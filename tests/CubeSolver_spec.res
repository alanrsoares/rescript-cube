// tests/CubeSolver_spec.res - Tests for CubeSolver algorithm reduction & scramble generation

open CubeTypes
open CubeSolver
open BunTest
open BunTest.Expect

describe("CubeSolver Spec", () => {
  describe("Move history optimization & reduction", () => {
    test(
      "canceling opposite adjacent moves",
      () => {
        let input = list{MoveR(Clockwise), MoveR(CounterClockwise)}
        let simplified = simplifyMoves(input)
        expect(simplified)->toEqual(list{})
      },
    )

    test(
      "combines two identical clockwise moves into a double move",
      () => {
        let input = list{MoveU(Clockwise), MoveU(Clockwise)}
        let simplified = simplifyMoves(input)
        expect(simplified)->toEqual(list{MoveU(Double)})
      },
    )

    test(
      "reduces three identical clockwise moves to one prime move",
      () => {
        let input = list{MoveF(Clockwise), MoveF(Clockwise), MoveF(Clockwise)}
        let simplified = simplifyMoves(input)
        expect(simplified)->toEqual(list{MoveF(CounterClockwise)})
      },
    )

    test(
      "cancels four identical moves completely",
      () => {
        let input = list{MoveL(Clockwise), MoveL(Clockwise), MoveL(Clockwise), MoveL(Clockwise)}
        let simplified = simplifyMoves(input)
        expect(simplified)->toEqual(list{})
      },
    )
  })

  describe("Solution sequence generation", () => {
    test(
      "inverts and reverses single move history",
      () => {
        let history = [MoveR(Clockwise)]
        let sol = generateSolution(history)
        expect(sol)->toEqual([MoveR(CounterClockwise)])
      },
    )

    test(
      "inverts and reverses multi-move history",
      () => {
        let history = [MoveR(Clockwise), MoveU(Clockwise)]
        let sol = generateSolution(history)
        expect(sol)->toEqual([MoveU(CounterClockwise), MoveR(CounterClockwise)])
      },
    )

    test(
      "optimizes solution sequence automatically",
      () => {
        let history = [MoveR(Clockwise), MoveU(Clockwise), MoveU(Clockwise)]
        let sol = generateSolution(history)
        expect(sol)->toEqual([MoveU(Double), MoveR(CounterClockwise)])
      },
    )

    test(
      "returns a recorded position to solved",
      () => {
        let history = [MoveR(Clockwise), MoveU(Double), MoveF(CounterClockwise)]
        let solved = CubeState.applyMoves(CubeState.fromMoves(history), generateSolution(history))
        expect(CubeState.isSolved(solved))->toBe(true)
      },
    )
  })

  describe("Random scramble generator", () => {
    test(
      "generates scramble of specified length",
      () => {
        let scramble = generateScramble(20)
        expect(Array.length(scramble))->toBe(20)
      },
    )

    test(
      "avoids adjacent moves on the same face",
      () => {
        let scramble = generateScramble(15)
        let hasSameAdjacentFace = ref(false)

        for i in 0 to Array.length(scramble) - 2 {
          let m1 = scramble[i]->Option.getOr(MoveU(Clockwise))
          let m2 = scramble[i + 1]->Option.getOr(MoveU(Clockwise))
          if faceOfMove(m1) == faceOfMove(m2) {
            hasSameAdjacentFace := true
          }
        }

        expect(hasSameAdjacentFace.contents)->toBe(false)
      },
    )
  })
})
