// tests/Timeline_spec.res - the undo cursor has to behave like a line, not a tree.

open CubeTypes
open BunTest
open BunTest.Expect

let build = moves => moves->Array.reduce(Timeline.empty, Timeline.record)

describe("Timeline", () => {
  test("records onto the end and leaves nothing to redo", () => {
    let t = build([MoveR(Clockwise), MoveU(Clockwise)])
    expect(t.cursor)->toBe(2)
    expect(Timeline.canUndo(t))->toBe(true)
    expect(Timeline.canRedo(t))->toBe(false)
  })

  test("undo yields the inverse of the last move and keeps it for redo", () => {
    let (next, turns) = build([MoveR(Clockwise), MoveU(Clockwise)])->Timeline.undo
    expect(turns)->toEqual([MoveU(CounterClockwise)])
    expect(next.cursor)->toBe(1)
    expect(Timeline.undone(next))->toEqual([MoveU(Clockwise)])
    expect(Timeline.canRedo(next))->toBe(true)
  })

  test("redo replays the recorded move, not its inverse", () => {
    let (undone, _) = build([MoveR(Clockwise)])->Timeline.undo
    let (next, turns) = Timeline.redo(undone)
    expect(turns)->toEqual([MoveR(Clockwise)])
    expect(next.cursor)->toBe(1)
    expect(Timeline.canRedo(next))->toBe(false)
  })

  // A double is its own inverse, so undoing one must not flip it to a quarter turn.
  test("inverts a double back onto itself", () => {
    let (_, turns) = build([MoveF(Double)])->Timeline.undo
    expect(turns)->toEqual([MoveF(Double)])
  })

  test("rewinds multiple moves back to front", () => {
    let (next, turns) =
      build([MoveR(Clockwise), MoveU(Clockwise), MoveF(CounterClockwise)])->Timeline.seek(0)
    expect(turns)->toEqual([MoveF(Clockwise), MoveU(CounterClockwise), MoveR(CounterClockwise)])
    expect(next.cursor)->toBe(0)
    expect(Timeline.canUndo(next))->toBe(false)
  })

  test("recording after an undo discards the branch that was taken back", () => {
    let (rewound, _) = build([MoveR(Clockwise), MoveU(Clockwise)])->Timeline.undo
    let t = Timeline.record(rewound, MoveL(Clockwise))
    expect(t.moves)->toEqual([MoveR(Clockwise), MoveL(Clockwise)])
    expect(Timeline.canRedo(t))->toBe(false)
  })

  test("clamps a seek past either end instead of failing", () => {
    let t = build([MoveR(Clockwise)])
    let (ahead, forward) = Timeline.seek(t, 99)
    expect(ahead.cursor)->toBe(1)
    expect(forward)->toEqual([])
    let (behind, back) = Timeline.seek(t, -99)
    expect(behind.cursor)->toBe(0)
    expect(back)->toEqual([MoveR(CounterClockwise)])
  })

  test("has nothing to undo or redo when empty", () => {
    expect(Timeline.canUndo(Timeline.empty))->toBe(false)
    expect(Timeline.canRedo(Timeline.empty))->toBe(false)
    let (next, turns) = Timeline.undo(Timeline.empty)
    expect(turns)->toEqual([])
    expect(next.cursor)->toBe(0)
  })
})
