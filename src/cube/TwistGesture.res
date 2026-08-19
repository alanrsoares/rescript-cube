// src/cube/TwistGesture.res - two fingers twisting, as an angle.
//
// Tracks the angle of the segment between two pointers and the signed rotation
// accumulated since they went down. It decides only when a twist has been meant;
// what the twist turns is the caller's business.
//
// Pure: plain screen coordinates in, a direction out.

open CubeTypes

type point = {x: float, y: float}

type t = {previous: float, turned: float}

let pi = Math.Constants.pi

// Below this the twist is indistinguishable from two fingers settling on the
// glass, where the segment between them swings a few degrees on its own.
let commitDegrees = 22.0
let commitRadians = commitDegrees *. pi /. 180.0

let angleOf = (a: point, b: point): float => Math.atan2(~y=b.y -. a.y, ~x=b.x -. a.x)

let start = (a: point, b: point): t => {previous: angleOf(a, b), turned: 0.0}

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
  {previous: now, turned: t.turned +. wrap(now -. t.previous)}
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
