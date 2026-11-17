import UIKit

// Decoded cover bitmaps, kept for the life of the process. The shelf views used to call
// UIImage(contentsOfFile:) inside their bodies, so every render pass re-read and
// re-decoded JPEGs from disk on the main thread — a steady source of scroll stutter in
// the library. NSCache evicts under memory pressure, so the worst case is a re-decode.
enum CoverCache {
    private static let cache = NSCache<NSString, UIImage>()

    static func image(at url: URL?) -> UIImage? {
        guard let url else { return nil }
        let key = url.path as NSString
        if let hit = cache.object(forKey: key) { return hit }
        guard let img = UIImage(contentsOfFile: url.path) else { return nil }
        // Force-decode now, once — otherwise UIKit decodes lazily at first draw.
        let prepared = img.preparingForDisplay() ?? img
        cache.setObject(prepared, forKey: key)
        return prepared
    }
}

extension CoverCache {
    private static var tones: [String: UIColor] = [:]

    // The cover's average colour (its board tone: pale parchment, deep navy, …), measured
    // once by drawing the cover into a single pixel. Main thread only.
    static func tone(at url: URL?) -> UIColor? {
        guard let url else { return nil }
        if let t = tones[url.path] { return t }
        guard let cg = image(at: url)?.cgImage else { return nil }
        var px = [UInt8](repeating: 0, count: 4)
        guard let ctx = CGContext(data: &px, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.interpolationQuality = .medium
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        let t = UIColor(red: CGFloat(px[0]) / 255, green: CGFloat(px[1]) / 255,
                        blue: CGFloat(px[2]) / 255, alpha: 1)
        tones[url.path] = t
        return t
    }
}
