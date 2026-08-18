// Canvas Confetti ReScript Bindings

type confettiOptions = {
  particleCount?: int,
  spread?: float,
  origin?: {"y": float, "x": float},
  colors?: array<string>,
}

@module("canvas-confetti") external fireConfetti: confettiOptions => unit = "default"

let triggerVictory = () => {
  fireConfetti({
    particleCount: 120,
    spread: 80.0,
    origin: {"y": 0.6, "x": 0.5},
  })
}
