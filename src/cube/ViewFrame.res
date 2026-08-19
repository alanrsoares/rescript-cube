// src/cube/ViewFrame.res - the frame the learner is actually looking at.
//
// The model names layers by world axis and never moves them: R is the +x layer,
// U is +y, F is +z, and a whole-cube turn only relabels which colours sit there.
// The camera, though, orbits freely, so the face on the learner's right stops
// being +x the moment they drag the cube around.
//
// Notation typed at the keyboard, or tapped on the move grid, is written in the
// learner's frame. This module rewrites it into the world frame the model speaks.
// Algorithms from the coach are already in the model's frame and must not pass
// through here.
//
// Pure: it takes the camera basis as plain numbers, so it is testable without a
// renderer.

open CubeTypes

type axis = AxisX | AxisY | AxisZ

// A face position: an axis, and which end of it.
type signedAxis = {axis: axis, positive: bool}

type t = {right: signedAxis, up: signedAxis, front: signedAxis}

type vec = (float, float, float)

// Looking at the front face square on, which is how the model reads.
let world = {
  right: {axis: AxisX, positive: true},
  up: {axis: AxisY, positive: true},
  front: {axis: AxisZ, positive: true},
}

let opposite = (sa: signedAxis): signedAxis => {...sa, positive: !sa.positive}

let toVec = (sa: signedAxis): vec => {
  let s = sa.positive ? 1.0 : -1.0
  switch sa.axis {
  | AxisX => (s, 0.0, 0.0)
  | AxisY => (0.0, s, 0.0)
  | AxisZ => (0.0, 0.0, s)
  }
}

let component = (v: vec, a: axis): float => {
  let (x, y, z) = v
  switch a {
  | AxisX => x
  | AxisY => y
  | AxisZ => z
  }
}

let allAxes = [AxisX, AxisY, AxisZ]

// Nearest signed axis, restricted to `allowed`. Ties keep the earlier axis, which
// only comes up for a camera sitting exactly on a diagonal.
let snapWithin = (v: vec, allowed: array<axis>): signedAxis => {
  let best =
    allowed->Array.reduce(allowed->Array.getUnsafe(0), (b, a) =>
      Math.abs(component(v, a)) > Math.abs(component(v, b)) ? a : b
    )
  {axis: best, positive: component(v, best) >= 0.0}
}

let cross = ((ax, ay, az): vec, (bx, by, bz): vec): vec => (
  ay *. bz -. az *. by,
  az *. bx -. ax *. bz,
  ax *. by -. ay *. bx,
)

// `up` is snapped to an axis square to `right` rather than independently: part way
// through an orbit both raw vectors can lean toward the same axis, and a frame
// with two of its faces on one axis would relabel two letters onto one layer.
// `front` then follows from the pair, so the frame is always right-handed.
let fromCamera = (~right: vec, ~up: vec): t => {
  let r = snapWithin(right, allAxes)
  let u = snapWithin(up, allAxes->Array.filter(a => a != r.axis))
  {right: r, up: u, front: snapWithin(cross(toVec(r), toVec(u)), allAxes)}
}

// Both frames define a face turn as clockwise seen from outside that face, so a
// face move changes which letter names it and keeps its direction.
let faceMove = (sa: signedAxis, dir: moveDir): move =>
  switch (sa.axis, sa.positive) {
  | (AxisX, true) => MoveR(dir)
  | (AxisX, false) => MoveL(dir)
  | (AxisY, true) => MoveU(dir)
  | (AxisY, false) => MoveD(dir)
  | (AxisZ, true) => MoveF(dir)
  | (AxisZ, false) => MoveB(dir)
  }

type family = Whole | Slice

// X and M turn about the right-left axis, Y and E about up-down, Z and S about
// front-back. Unlike a face turn these take their sense from the axis itself (X
// follows R, M follows L), so landing on the negative end of a world axis
// reverses the turn.
let axisMove = (fam: family, sa: signedAxis, dir: moveDir): move => {
  let d = sa.positive ? dir : invertDir(dir)
  switch (fam, sa.axis) {
  | (Whole, AxisX) => MoveX(d)
  | (Whole, AxisY) => MoveY(d)
  | (Whole, AxisZ) => MoveZ(d)
  | (Slice, AxisX) => MoveM(d)
  | (Slice, AxisY) => MoveE(d)
  | (Slice, AxisZ) => MoveS(d)
  }
}

let relabel = (f: t, m: move): move =>
  switch m {
  | MoveR(d) => faceMove(f.right, d)
  | MoveL(d) => faceMove(opposite(f.right), d)
  | MoveU(d) => faceMove(f.up, d)
  | MoveD(d) => faceMove(opposite(f.up), d)
  | MoveF(d) => faceMove(f.front, d)
  | MoveB(d) => faceMove(opposite(f.front), d)
  | MoveX(d) => axisMove(Whole, f.right, d)
  | MoveY(d) => axisMove(Whole, f.up, d)
  | MoveZ(d) => axisMove(Whole, f.front, d)
  | MoveM(d) => axisMove(Slice, f.right, d)
  | MoveE(d) => axisMove(Slice, f.up, d)
  | MoveS(d) => axisMove(Slice, f.front, d)
  }
