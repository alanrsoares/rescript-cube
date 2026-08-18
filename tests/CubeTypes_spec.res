// tests/CubeTypes_spec.res - Tests for CubeTypes move representation & parsing

open CubeTypes
open BunTest
open BunTest.Expect

describe("CubeTypes Spec", () => {
  describe("Move notation formatting", () => {
    test(
      "formats clockwise moves correctly",
      () => {
        expect(moveToString(MoveU(Clockwise)))->toBe("U")
        expect(moveToString(MoveR(Clockwise)))->toBe("R")
        expect(moveToString(MoveF(Clockwise)))->toBe("F")
        expect(moveToString(MoveM(Clockwise)))->toBe("M")
      },
    )

    test(
      "formats counter-clockwise (prime) moves correctly",
      () => {
        expect(moveToString(MoveU(CounterClockwise)))->toBe("U'")
        expect(moveToString(MoveR(CounterClockwise)))->toBe("R'")
        expect(moveToString(MoveF(CounterClockwise)))->toBe("F'")
        expect(moveToString(MoveX(CounterClockwise)))->toBe("X'")
      },
    )

    test(
      "formats double moves correctly",
      () => {
        expect(moveToString(MoveU(Double)))->toBe("U2")
        expect(moveToString(MoveR(Double)))->toBe("R2")
        expect(moveToString(MoveZ(Double)))->toBe("Z2")
      },
    )
  })

  describe("Move inversion", () => {
    test(
      "inverts clockwise move to counter-clockwise",
      () => {
        expect(invertMove(MoveR(Clockwise)))->toEqual(MoveR(CounterClockwise))
        expect(invertMove(MoveU(Clockwise)))->toEqual(MoveU(CounterClockwise))
      },
    )

    test(
      "inverts counter-clockwise move to clockwise",
      () => {
        expect(invertMove(MoveF(CounterClockwise)))->toEqual(MoveF(Clockwise))
      },
    )

    test(
      "inverting double move remains double move",
      () => {
        expect(invertMove(MoveL(Double)))->toEqual(MoveL(Double))
      },
    )
  })

  describe("Move direction arithmetic", () => {
    test(
      "models a full turn as cancellation",
      () => {
        expect(moveDirFromQuarterTurns(4))->toEqual(None)
        expect(moveDirFromQuarterTurns(5))->toEqual(Some(Clockwise))
      },
    )
  })

  describe("String to Move parsing", () => {
    test(
      "parses single character moves",
      () => {
        expect(stringToMove("U"))->toEqual(Some(MoveU(Clockwise)))
        expect(stringToMove("r"))->toEqual(Some(MoveR(Clockwise)))
        expect(stringToMove("F"))->toEqual(Some(MoveF(Clockwise)))
      },
    )

    test(
      "parses prime moves",
      () => {
        expect(stringToMove("U'"))->toEqual(Some(MoveU(CounterClockwise)))
        expect(stringToMove("r'"))->toEqual(Some(MoveR(CounterClockwise)))
      },
    )

    test(
      "parses double moves",
      () => {
        expect(stringToMove("D2"))->toEqual(Some(MoveD(Double)))
        expect(stringToMove("b2"))->toEqual(Some(MoveB(Double)))
      },
    )

    test(
      "returns None for invalid move strings",
      () => {
        expect(stringToMove(""))->toEqual(None)
        expect(stringToMove("INVALID"))->toEqual(None)
        expect(stringToMove("U22"))->toEqual(None)
      },
    )
  })

  describe("Color themes", () => {
    test(
      "puts the first-layer colour on the bottom, as the method teaches",
      () => {
        let classic = getTheme(Classic)
        expect(classic.down)->toBe(0xffffff) // white
        expect(classic.up)->toBe(0xffd500) // yellow
      },
    )

    test(
      "keeps every theme a physically valid cube",
      () => {
        // Opposite faces must never share a colour, and all six must differ.
        [Classic, Neon, Pastel, Monochrome, Cyberpunk]->Array.forEach(
          theme => {
            let t = getTheme(theme)
            let faces = [t.up, t.down, t.left, t.right, t.front, t.back]
            expect(faces->Set.fromArray->Set.size)->toBe(6)
          },
        )
      },
    )
  })
})
