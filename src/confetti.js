export const triggerVictory = () => {
  void import("canvas-confetti").then(({default: fireConfetti}) => {
    fireConfetti({
      particleCount: 120,
      spread: 80,
      origin: {y: 0.6, x: 0.5},
    })
  })
}
