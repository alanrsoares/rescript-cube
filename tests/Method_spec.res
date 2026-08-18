// tests/Method_spec.res - stage detection and practice setup

open BunTest
open BunTest.Expect

let solved = CubeState.solved()

let earlierStages = (st: Method.stage): array<Method.stage> =>
  Method.stages->Array.slice(~start=0, ~end=Method.stages->Array.indexOf(st))

describe("Method", () => {
  test("a solved cube has no stage left", () =>
    expect(Method.currentStage(solved)->Option.isNone)->toBe(true)
  )

  test("every stage is complete on a solved cube", () =>
    expect(Method.stages->Array.every(st => Method.isComplete(solved, st)))->toBe(true)
  )

  test("a scrambled cube reports the earliest unfinished stage", () => {
    // A U turn leaves both lower layers and the yellow face alone, but shifts
    // the top corners off their slots — so the learner is on stage six.
    let s = CubeState.fromMoves([CubeTypes.MoveU(Clockwise)])
    expect(Method.currentStage(s))->toEqual(Some(Method.CornerPermute))
  })

  test("breaking the cross sends the learner back to stage one", () => {
    let s = CubeState.fromMoves([CubeTypes.MoveF(Clockwise)])
    expect(Method.currentStage(s))->toEqual(Some(Method.Cross))
  })

  test("progress counts pieces, not moves", () => {
    let s = CubeState.fromMoves([CubeTypes.MoveF(Double)])
    // F2 displaces the DF edge and two bottom corners, leaving the rest.
    expect(Method.done(s, Method.Cross))->toBe(3)
  })

  describe("practice setup", () => {
    Method.stages->Array.forEach(
      st =>
        test(
          `${Method.name(st)} drills leave every earlier stage solved`,
          () => {
            let failures = Array.fromInitializer(
              ~length=40,
              _ => {
                let s = CubeState.fromMoves(Setup.practiceScramble(st))
                let earlierIntact =
                  earlierStages(st)->Array.every(prev => Method.isComplete(s, prev))
                let worthDrilling = !Method.isComplete(s, st) || st == Method.Cross
                earlierIntact && worthDrilling
              },
            )->Array.filter(ok => !ok)
            expect(Array.length(failures))->toBe(0)
          },
        ),
    )
  })
})
