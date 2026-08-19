// src/cube/TwistGesture.res - two fingers twisting, as an angle.
//
// Tracks the angle of the segment between two pointers and the signed rotation
// accumulated since they went down. The caller decides how to render that
// continuous rotation and when to settle it.
//
// Pure: plain screen coordinates in, a direction out.

open CubeTypes

type point = {x: float, y: float}

type swipeAxis = Horizontal | Vertical
type interaction = Twist(moveDir) | Swipe(swipeAxis, moveDir)

type t = {
  previous: float,
  turned: float,
  startCenter: point,
  center: point,
}

let pi = Math.Constants.pi

// Below this the twist is indistinguishable from two fingers settling on the
// glass. It is used only to choose the initial turn direction; interpolation
// remains continuous once the pivot is live.
let commitDegrees = 8.0
let commitRadians = commitDegrees *. pi /. 180.0
let swipeThresholdPx = 18.0

let angleOf = (a: point, b: point): float => Math.atan2(~y=b.y -. a.y, ~x=b.x -. a.x)
let midpoint = (a: point, b: point): point => {x: (a.x +. b.x) /. 2.0, y: (a.y +. b.y) /. 2.0}

let start = (a: point, b: point): t => {
  let center = midpoint(a, b)
  {previous: angleOf(a, b), turned: 0.0, startCenter: center, center}
}

// Wrapped before accumulating. Successive samples are milliseconds apart, so a
// raw difference near a full turn is the atan2 seam rather than real motion, and
// adding it unwrapped would flip the sign of the whole gesture.
let wrap = (angle: float): float =>
  if angle > pi {
    angle -. 2.0 *. pi
  } else if angle <= -.pi {
    angle +. 2.0 *. pi
  } else {
    angle
  }

let update = (t: t, a: point, b: point): t => {
  let now = angleOf(a, b)
  {...t, previous: now, turned: t.turned +. wrap(now -. t.previous), center: midpoint(a, b)}
}

// Screen y grows downward, so a positive accumulated angle is clockwise on screen
// and therefore a clockwise turn of the face being looked at.
let direction = (t: t): option<moveDir> =>
  if t.turned >= commitRadians {
    Some(Clockwise)
  } else if t.turned <= -.commitRadians {
    Some(CounterClockwise)
  } else {
    None
  }

// A two-point gesture chooses one interaction once it becomes deliberate.
// Translation is measured from the shared midpoint, which makes a real pair and
// Shift+drag's virtual pair indistinguishable to the renderer.
let interaction = (t: t): option<interaction> =>
  switch direction(t) {
  | Some(dir) => Some(Twist(dir))
  | None => {
      let dx = t.center.x -. t.startCenter.x
      let dy = t.center.y -. t.startCenter.y
      if Math.abs(dx) >= swipeThresholdPx && Math.abs(dx) >= Math.abs(dy) {
        Some(Swipe(Horizontal, dx > 0.0 ? Clockwise : CounterClockwise))
      } else if Math.abs(dy) >= swipeThresholdPx {
        // Screen y points down. Counter-clockwise here makes an upward swipe
        // carry the visible front face upward.
        Some(Swipe(Vertical, dy > 0.0 ? Clockwise : CounterClockwise))
      } else {
        None
      }
    }
  }
