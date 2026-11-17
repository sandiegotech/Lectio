import Foundation
import Combine
#if canImport(FoundationModels)
import FoundationModels
#endif

// The Docent — the reading companion in the margin. Answers questions about the
// passage being read, grounded in the passage itself plus the curated editorial
// layer (glossary, passage notes, chapter overviews). AI is an instrument here,
// never the authority: answers are labeled, and the text remains the text.
//
// Wired through a capability layer (CLAUDE.md "AI is deferred and swappable"):
// DocentProvider is the seam. v1 backend is Apple's on-device model
// (FoundationModels, iOS 26+, Apple Intelligence hardware) — free, offline,
// private. Gemma / Claude backends can conform later without touching the UI.

enum DocentFeature {
    // Single rename point: the user-facing name of the companion.
    static let name = "Docent"
}

// Everything a provider may ground an answer in. Assembled by the reader from
// the anchored segment + the work's enrichment sidecar; small enough to fit the
// on-device model's 4k-token window with plenty of room for conversation.
struct DocentContext: Equatable {
    var segmentId: String        // anchor; changing it starts a new conversation
    var workTitle: String
    var author: String
    var composed: String
    var editionLabel: String
    var sectionLabel: String
    var sectionTitle: String?
    var chapterOverview: String?
    var passage: String          // the anchored passage's text
    var before: String?          // a little surrounding text, for continuity
    var after: String?
    var notes: [String]          // curated glossary + passage notes relevant here
}

enum DocentAvailability: Equatable {
    case available
    case unavailable(String)     // flat, human-readable reason
}

// The provider seam. Stateful: begin() anchors a conversation to a passage;
// reply() streams cumulative text for one question, remembering prior turns.
@MainActor
protocol DocentProvider: AnyObject {
    var label: String { get }    // provenance label shown to the reader
    func begin(_ context: DocentContext)
    func reply(to question: String) -> AsyncThrowingStream<String, Error>
}

enum DocentError: Error {
    case notReady
}

struct DocentExchange: Identifiable {
    let id = UUID()
    var question: String
    var answer: String = ""
    var done = false
    var failed = false
}

// The streaming conversation, split from the service so per-token updates only
// re-render the panel — never the reader column behind it.
@MainActor
final class DocentThread: ObservableObject {
    @Published fileprivate(set) var exchanges: [DocentExchange] = []
    @Published fileprivate(set) var busy = false
}

// MARK: - Service (what the UI talks to)

@MainActor
final class DocentService: ObservableObject {
    let thread = DocentThread()
    @Published private(set) var availability: DocentAvailability
    @Published private(set) var context: DocentContext?

    private var provider: DocentProvider?
    private let mockForced: Bool
    private var task: Task<Void, Never>?

    var isAvailable: Bool { availability == .available }
    var providerLabel: String? { provider?.label }

    init() {
        #if DEBUG
        // Debug hook: LECTIO_DEBUG_DOCENT_MOCK uses a canned provider (for
        // screenshots and for development on hosts without Apple Intelligence).
        if ProcessInfo.processInfo.environment["LECTIO_DEBUG_DOCENT_MOCK"] != nil {
            mockForced = true
            provider = MockDocent()
            availability = .available
            return
        }
        #endif
        mockForced = false
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let a = AppleDocent.systemAvailability
            availability = a
            provider = (a == .available) ? AppleDocent() : nil
            #if DEBUG
            print("[Docent] availability: \(a)")
            #endif
            return
        }
        #endif
        availability = .unavailable("The \(DocentFeature.name) needs iOS 26 or later.")
        provider = nil
    }

    // Availability changes while the app is open — Apple Intelligence gets switched
    // on, the model finishes downloading. Re-check whenever the panel comes up.
    func refresh() {
        guard !mockForced else { return }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let a = AppleDocent.systemAvailability
            guard a != availability || (a == .available && provider == nil) else { return }
            availability = a
            if a == .available {
                let p = AppleDocent()
                provider = p
                if let ctx = context { p.begin(ctx) }
            } else {
                provider = nil
            }
        }
        #endif
    }

    // Anchor the conversation to a passage. A new anchor is a new conversation.
    func anchor(_ ctx: DocentContext) {
        guard ctx.segmentId != context?.segmentId else { return }
        task?.cancel()
        task = nil
        thread.busy = false
        thread.exchanges = []
        context = ctx
        provider?.begin(ctx)
    }

    func ask(_ question: String) {
        let q = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty, !thread.busy, let provider, context != nil else { return }
        thread.busy = true
        thread.exchanges.append(DocentExchange(question: q))
        let index = thread.exchanges.count - 1
        task = Task { [weak self] in
            do {
                for try await text in provider.reply(to: q) {
                    guard !Task.isCancelled else { return }
                    self?.thread.exchanges[index].answer = text
                }
                self?.thread.exchanges[index].done = true
            } catch {
                guard !Task.isCancelled else { return }
                self?.thread.exchanges[index].answer = Self.readerMessage(for: error)
                self?.thread.exchanges[index].failed = true
                self?.thread.exchanges[index].done = true
            }
            self?.thread.busy = false
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        if let last = thread.exchanges.indices.last, !thread.exchanges[last].done {
            thread.exchanges[last].done = true
        }
        thread.busy = false
    }

    // Map provider errors to flat sentences a reader can act on.
    private static func readerMessage(for error: Error) -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), let e = error as? LanguageModelSession.GenerationError {
            switch e {
            case .guardrailViolation, .refusal:
                return "The on-device model declined this question. Try asking about a narrower part of the passage."
            case .rateLimited, .concurrentRequests:
                return "The on-device model is busy. Try again in a moment."
            case .assetsUnavailable:
                return "The on-device model isn't loaded right now. Try again in a moment."
            default:
                break
            }
        }
        #endif
        return "Something went wrong answering that. Try asking again."
    }
}

// MARK: - Apple on-device provider (FoundationModels)

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@MainActor
final class AppleDocent: DocentProvider {
    let label = "Apple's on-device model"

    private var session: LanguageModelSession?
    private var context: DocentContext?

    static var systemAvailability: DocentAvailability {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return .unavailable("This device doesn't support Apple Intelligence, which the \(DocentFeature.name) runs on.")
            case .appleIntelligenceNotEnabled:
                return .unavailable("Turn on Apple Intelligence in Settings, then come back — the \(DocentFeature.name) runs on it.")
            case .modelNotReady:
                return .unavailable("The on-device model is still downloading. The \(DocentFeature.name) will wake up once it's ready.")
            @unknown default:
                return .unavailable("The on-device model isn't available right now.")
            }
        }
    }

    func begin(_ ctx: DocentContext) {
        context = ctx
        session = Self.makeSession(for: ctx)
        // Load the model ahead of the first question so the answer starts fast.
        session?.prewarm()
    }

    func reply(to question: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let work = Task { @MainActor in
                guard let session = self.session else {
                    continuation.finish(throwing: DocentError.notReady)
                    return
                }
                do {
                    try await Self.stream(question, from: session, into: continuation)
                    continuation.finish()
                } catch let error as LanguageModelSession.GenerationError {
                    // A long conversation overflowed the model's window: keep the
                    // same passage grounding, drop the history, answer fresh.
                    if case .exceededContextWindowSize = error, let ctx = self.context {
                        let fresh = Self.makeSession(for: ctx)
                        self.session = fresh
                        do {
                            try await Self.stream(question, from: fresh, into: continuation)
                            continuation.finish()
                        } catch {
                            continuation.finish(throwing: error)
                        }
                    } else {
                        continuation.finish(throwing: error)
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in work.cancel() }
        }
    }

    private static func stream(_ question: String,
                               from session: LanguageModelSession,
                               into continuation: AsyncThrowingStream<String, Error>.Continuation) async throws {
        for try await snapshot in session.streamResponse(to: question) {
            continuation.yield(snapshot.content)
        }
    }

    // All grounding lives in the instructions, so each question is just a prompt
    // and the session transcript carries the follow-up thread.
    private static func makeSession(for c: DocentContext) -> LanguageModelSession {
        var lines: [String] = []
        lines.append("""
        You are the \(DocentFeature.name): the reading companion inside Lectio, an app for \
        reading the classics. The reader is intelligent but may be meeting this work for \
        the first time. Answer their questions plainly, in modern English, in two to five \
        sentences. Ground every answer in the passage and notes below — never invent \
        quotations, names, or events. The passage is the only text in front of the reader; \
        the notes may mention people and ideas from elsewhere in the section, so never \
        claim the passage says something it doesn't. If the passage doesn't contain the \
        answer, say so plainly first, then offer what brief context you can. Never talk \
        down to the reader.
        """)
        lines.append("The reader is in \(c.workTitle) by \(c.author) (\(c.composed)), reading the \(c.editionLabel), in \(c.sectionLabel)\(c.sectionTitle.map { ", “\($0)”" } ?? "").")
        if let overview = c.chapterOverview, !overview.isEmpty {
            lines.append("Where they are in the work: \(overview)")
        }
        if let before = c.before, !before.isEmpty {
            lines.append("Just before the passage: \(before)")
        }
        lines.append("The passage the reader is asking about:\n\(c.passage)")
        if let after = c.after, !after.isEmpty {
            lines.append("Just after the passage: \(after)")
        }
        if !c.notes.isEmpty {
            lines.append("Editor's notes on names and terms here:\n" + c.notes.map { "- \($0)" }.joined(separator: "\n"))
        }
        return LanguageModelSession(instructions: lines.joined(separator: "\n\n"))
    }
}
#endif

// MARK: - Mock provider (debug/dev only; enabled by LECTIO_DEBUG_DOCENT_MOCK)

#if DEBUG
@MainActor
final class MockDocent: DocentProvider {
    let label = "preview (canned answer)"
    private var context: DocentContext?

    func begin(_ ctx: DocentContext) { context = ctx }

    func reply(to question: String) -> AsyncThrowingStream<String, Error> {
        let answer = "Marcus opens the Meditations with a ledger of debts: person by person, he names what each one taught him. From his grandfather Verus he took good temper; from his father's memory, modesty and strength of character; from his mother, reverence, generosity, and plain living. Before writing a single idea of his own, he credits every virtue he has to someone else — the book's first lesson in humility."
        return AsyncThrowingStream { continuation in
            let work = Task {
                var sent = ""
                for word in answer.split(separator: " ", omittingEmptySubsequences: false) {
                    guard !Task.isCancelled else { return }
                    sent += (sent.isEmpty ? "" : " ") + word
                    continuation.yield(sent)
                    try? await Task.sleep(nanoseconds: 12_000_000)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in work.cancel() }
        }
    }
}
#endif
