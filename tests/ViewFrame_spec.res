// tests/ViewFrame_spec.res - notation is written from where the learner sits, so
// every letter has to survive the trip into the model's world frame.

open CubeTypes
open BunTest
open BunTest.Expect

// Camera basis columns: right, up. `front` follows from the pair.
let frame = (~right, ~up) => ViewFrame.fromCamera(~right, ~up)

let faceLetters = [
  MoveU(Clockwise),
  MoveD(Clockwise),
  MoveL(Clockwise),
  MoveR(Clockwise),
  MoveF(Clockwise),
  MoveB(Clockwise),
]

describe("ViewFrame", () => {
  test("leaves every letter alone when the learner is square to the front face", () => {
    let f = frame(~right=(1.0, 0.0, 0.0), ~up=(0.0, 1.0, 0.0))
    expect(f)->toEqual(ViewFrame.world)
    [
      MoveU(Clockwise),
      MoveR(CounterClockwise),
      MoveF(Double),
      MoveM(Clockwise),
      MoveE(Clockwise),
      MoveS(Clockwise),
      MoveX(Clockwise),
      MoveY(Clockwise),
      MoveZ(Clockwise),
    ]->Array.forEach(m => expect(ViewFrame.relabel(f, m))->toEqual(m))
  })

  // Standing off the right-hand face: the model's R is now straight ahead.
  test("relabels a quarter turn around the cube", () => {
    let f = frame(~right=(0.0, 0.0, -1.0), ~up=(0.0, 1.0, 0.0))
    expect(ViewFrame.relabel(f, MoveF(Clockwise)))->toEqual(MoveR(Clockwise))
    expect(ViewFrame.relabel(f, MoveR(Clockwise)))->toEqual(MoveB(Clockwise))
    expect(ViewFrame.relabel(f, MoveL(Clockwise)))->toEqual(MoveF(Clockwise))
    expect(ViewFrame.relabel(f, MoveB(Clockwise)))->toEqual(MoveL(Clockwise))
  })

  test("keeps up and down when only the horizontal view changes", () => {
    let f = frame(~right=(0.0, 0.0, -1.0), ~up=(0.0, 1.0, 0.0))
    expect(ViewFrame.relabel(f, MoveU(Clockwise)))->toEqual(MoveU(Clockwise))
    expect(ViewFrame.relabel(f, MoveD(Double)))->toEqual(MoveD(Double))
  })

  test("swaps up for down when the view has tumbled over the top", () => {
    let f = frame(~right=(1.0, 0.0, 0.0), ~up=(0.0, -1.0, 0.0))
    expect(ViewFrame.relabel(f, MoveU(Clockwise)))->toEqual(MoveD(Clockwise))
    expect(ViewFrame.relabel(f, MoveD(Clockwise)))->toEqual(MoveU(Clockwise))
    // Right stayed on +x, so the view is now looking at the back face.
    expect(ViewFrame.relabel(f, MoveF(Clockwise)))->toEqual(MoveB(Clockwise))
  })

  // A face turn is clockwise seen from outside that face in either frame, so only
  // the letter moves. The axis families take their sense from the axis, so they
  // reverse when the learner's axis points down the negative world one.
  test("reverses whole-cube turns and slices that land on a negative axis", () => {
    let f = frame(~right=(-1.0, 0.0, 0.0), ~up=(0.0, 1.0, 0.0))
    expect(ViewFrame.relabel(f, MoveR(Clockwise)))->toEqual(MoveL(Clockwise))
    expect(ViewFrame.relabel(f, MoveX(Clockwise)))->toEqual(MoveX(CounterClockwise))
    expect(ViewFrame.relabel(f, MoveM(Clockwise)))->toEqual(MoveM(CounterClockwise))
    expect(ViewFrame.relabel(f, MoveY(Clockwise)))->toEqual(MoveY(Clockwise))
  })

  test("never lands two letters on the same layer", () => {
    let f = frame(~right=(0.9, 0.1, -0.2), ~up=(0.2, 0.8, 0.1))
    let relabelled = faceLetters->Array.map(m => ViewFrame.relabel(f, m))
    expect(Array.length(Set.fromArray(relabelled->Array.map(moveToString))->Set.toArray))->toBe(6)
  })

  // Part way through an orbit the raw right and up vectors can lean on the same
  // axis. Snapping them independently would collapse the frame.
  test("keeps the frame square when the raw basis is nearly degenerate", () => {
    let f = frame(~right=(0.1, 0.99, 0.0), ~up=(0.0, 0.98, 0.2))
    expect(f.right.axis == f.up.axis)->toBe(false)
    expect(f.front.axis == f.up.axis)->toBe(false)
    expect(f.front.axis == f.right.axis)->toBe(false)
  })
})
