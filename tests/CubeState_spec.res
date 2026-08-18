// tests/CubeState_spec.res - the logical cube must agree with a real Rubik's cube

open CubeTypes
open BunTest
open BunTest.Expect

let parse = (notation: string): array<move> =>
  notation
  ->String.split(" ")
  ->Array.filterMap(stringToMove)

let orderOf = (notation: string): int => {
  let alg = parse(notation)
  let rec loop = (s, n) => {
    let next = CubeState.applyMoves(s, alg)
    if CubeState.isSolved(next) || n > 1260 {
      n
    } else {
      loop(next, n + 1)
    }
  }
  loop(CubeState.solved(), 1)
}

describe("CubeState", () => {
  describe("move tables", () => {
    ["U", "D", "L", "R", "F", "B", "M", "E", "S"]->Array.forEach(
      face => test(`${face} has order 4`, () => expect(orderOf(face))->toBe(4)),
    )

    // Rotations only change how the cube is held, so they never show up in
    // solvedness — their order lives in `orient`.
    ["X", "Y", "Z"]->Array.forEach(
      rot =>
        test(
          `${rot} cycles the hold in 4`,
          () => {
            let held = CubeState.fromMoves(parse(`${rot} ${rot} ${rot}`))
            expect(held.orient == [0, 1, 2, 3, 4, 5])->toBe(false)
            expect(CubeState.fromMoves(parse(`${rot} ${rot} ${rot} ${rot}`)).orient)->toEqual([
              0,
              1,
              2,
              3,
              4,
              5,
            ])
          },
        ),
    )

    test(
      "a quarter turn does not solve the cube",
      () => expect(CubeState.fromMoves(parse("R"))->CubeState.isSolved)->toBe(false),
    )
  })

  describe("known algorithm orders", () => {
    // These orders are properties of a physical cube: wrong tables break them.
    test("sexy move (R U R' U') has order 6", () => expect(orderOf("R U R' U'"))->toBe(6))
    test("Sune has order 6", () => expect(orderOf("R U R' U R U2 R'"))->toBe(6))
    test("U-perm has order 3", () => expect(orderOf("R U' R U R U R U' R' U' R2"))->toBe(3))
    test("A-perm has order 3", () => expect(orderOf("U R U' L' U R' U' L"))->toBe(3))
    test(
      "T-perm has order 2",
      () => expect(orderOf("R U R' U' R' F R2 U' R' U' R U R' F'"))->toBe(2),
    )
    test("R U has order 105", () => expect(orderOf("R U"))->toBe(105))
    test("M-slice checkerboard (M2 E2 S2) has order 2", () => expect(orderOf("M2 E2 S2"))->toBe(2))
  })

  describe("invariants", () => {
    test(
      "a scramble undone by its inverse is solved",
      () => {
        let scramble = CubeSolver.generateScramble(30)
        let undo = scramble->Array.map(invertMove)->Array.toReversed
        expect(CubeState.fromMoves(Array.concat(scramble, undo))->CubeState.isSolved)->toBe(true)
      },
    )

    test(
      "whole-cube rotations never unsolve the cube",
      () => expect(CubeState.fromMoves(parse("X Y' Z2 X' Y"))->CubeState.isSolved)->toBe(true),
    )

    test(
      "a solved cube stays solved under rotation, however it is held",
      () => {
        let held = CubeState.fromMoves(parse("X Y"))
        expect(held.orient == [0, 1, 2, 3, 4, 5])->toBe(false)
        expect(CubeState.isSolved(held))->toBe(true)
      },
    )

    test(
      "R after Y is the same physical turn as B",
      () => {
        let viaRotation = CubeState.fromMoves(parse("Y R Y'"))
        let direct = CubeState.fromMoves(parse("B"))
        expect(viaRotation.cp)->toEqual(direct.cp)
        expect(viaRotation.ep)->toEqual(direct.ep)
      },
    )

    test(
      "localize relabels a lesson for a rotated cube",
      () => {
        // After Y the right-hand face has swung round to the front, so a lesson
        // that says "R" must tell this learner to turn F.
        let held = CubeState.fromMoves(parse("Y"))
        expect(CubeState.localize(held, [MoveR(Clockwise)])->Array.map(moveToString))->toEqual([
          "F",
        ])
      },
    )

    test(
      "a localized algorithm turns the same cubies as the original",
      () => {
        let held = CubeState.fromMoves(parse("Y X'"))
        let alg = parse("R U R' U'")
        expect(CubeState.applyMoves(held, CubeState.localize(held, alg)).cp)->toEqual(
          CubeState.fromMoves(alg).cp,
        )
      },
    )

    test(
      "M equals turning the middle layer only",
      () => {
        // M is L-direction, so M followed by an L-direction outer pair is a full x'.
        let viaSlice = CubeState.fromMoves(parse("M R' L"))
        expect(CubeState.isSolved(viaSlice))->toBe(true)
        expect(viaSlice.orient)->toEqual(CubeState.fromMoves(parse("X'")).orient)
      },
    )
  })
})
