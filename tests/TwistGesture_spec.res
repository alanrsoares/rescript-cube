// tests/TwistGesture_spec.res - the twist has to survive the atan2 seam and has
// to agree with the screen's downward y about which way is clockwise.

open CubeTypes
open BunTest
open BunTest.Expect

let at = (x, y): TwistGesture.point => {x, y}

// Two fingers `radius` apart, the segment between them rotated by `degrees`.
// Positive degrees sweep clockwise on screen, since y grows downward.
let grip = (degrees: float) => {
  let r = 100.0
  let a = degrees *. Math.Constants.pi /. 180.0
  (at(-.r *. Math.cos(a), -.r *. Math.sin(a)), at(r *. Math.cos(a), r *. Math.sin(a)))
}

let twistTo = (degrees: array<float>) => {
  let (a0, b0) = grip(0.0)
  degrees->Array.reduce(TwistGesture.start(a0, b0), (g, d) => {
    let (a, b) = grip(d)
    TwistGesture.update(g, a, b)
  })
}

describe("TwistGesture", () => {
  test("stays undecided while the fingers are only settling", () => {
    expect(twistTo([4.0, -3.0, 6.0])->TwistGesture.direction)->toEqual(None)
  })

  test("reads a clockwise sweep as a clockwise turn", () => {
    expect(twistTo([10.0, 20.0, 30.0])->TwistGesture.direction)->toEqual(Some(Clockwise))
  })

  test("reads a counter-clockwise sweep as a counter-clockwise turn", () => {
    expect(twistTo([-10.0, -20.0, -30.0])->TwistGesture.direction)->toEqual(Some(CounterClockwise))
  })

  // The segment between two fingers is symmetric, so its angle wraps every half
  // turn. Sampling across that seam must not reverse the gesture.
  test("keeps accumulating across the angle seam", () => {
    let g = twistTo([60.0, 120.0, 170.0, 200.0, 240.0])
    expect(g.turned > 0.0)->toBe(true)
    expect(TwistGesture.direction(g))->toEqual(Some(Clockwise))
  })

  test("cancels itself when the twist comes back to where it started", () => {
    expect(twistTo([30.0, 15.0, 0.0])->TwistGesture.direction)->toEqual(None)
  })

  test("reads a two-finger upward swipe independently of rotation", () => {
    let (a, b) = (at(-40.0, 0.0), at(40.0, 0.0))
    let movedA = at(-40.0, -50.0)
    let movedB = at(40.0, -50.0)
    let g = TwistGesture.start(a, b)->TwistGesture.update(movedA, movedB)
    expect(TwistGesture.intent(g, movedA, movedB))->toEqual(Some(TwistGesture.SwipeUp))
  })

  test("reads a two-finger downward swipe independently of rotation", () => {
    let (a, b) = (at(-40.0, 0.0), at(40.0, 0.0))
    let movedA = at(-40.0, 50.0)
    let movedB = at(40.0, 50.0)
    let g = TwistGesture.start(a, b)->TwistGesture.update(movedA, movedB)
    expect(TwistGesture.intent(g, movedA, movedB))->toEqual(Some(TwistGesture.SwipeDown))
  })
})
