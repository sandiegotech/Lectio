"""Swappable AI provider contract.

Planned backends (NONE implemented yet — v1 is no-AI):

  "apple"  on-device Apple Foundation Models — free, offline, ~3B params.
           Comprehension aids (tap-to-explain, recaps, simplify). Free tier.
  "gemma"  bundled open model via MLX / llama.cpp — later "offline AI pack".
           Offline translation on M-series devices. RAM-bound.
  "claude" cloud custom-tuned "Philosopher" — highest fidelity, cross-app,
           any device. AI translation + Gloss intelligence. Paid (Philosopher tier).
  "noop"   disabled. The only registered provider today.

The contract is intentionally tiny: `available()` lets callers feature-detect and
degrade gracefully; `complete()` does one text-in/text-out turn. Structured output,
streaming, and tuning profiles get layered on when a real backend lands.
"""
from __future__ import annotations

from abc import ABC, abstractmethod


class AIProvider(ABC):
    name: str = "abstract"

    @abstractmethod
    def available(self) -> bool:
        """True if this backend can run on the current device/account."""

    @abstractmethod
    def complete(self, prompt: str, **opts) -> str:
        """One completion. Implementations may accept opts like profile=, max_tokens=."""


class NoOpProvider(AIProvider):
    """The default. Reports unavailable and refuses to run — so nothing in v1
    accidentally depends on AI. Call sites must check `available()` first."""

    name = "noop"

    def available(self) -> bool:
        return False

    def complete(self, prompt: str, **opts) -> str:
        raise RuntimeError(
            "AI is disabled in this build (NoOpProvider). "
            "Check provider.available() before calling complete()."
        )


_REGISTRY = {
    "noop": NoOpProvider,
    # "apple": AppleFoundationModelsProvider,   # TODO: app-side, on-device
    # "gemma": GemmaMLXProvider,                # TODO: offline pack
    # "claude": ClaudeAPIProvider,              # TODO: Philosopher tier
}


def get_provider(name: str = "noop") -> AIProvider:
    """Resolve a provider by name, falling back to the no-op provider."""
    return _REGISTRY.get(name, NoOpProvider)()
