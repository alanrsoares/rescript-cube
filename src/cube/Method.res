// src/cube/Method.res - the beginner layer-by-layer curriculum.
//
// Seven stages, ~7 algorithms. Every stage exposes the same three things, so the
// UI can treat them uniformly: can I tell when it is done, how far along am I,
// and what should the learner do next.
//
// Written in the fixed frame (white D, yellow U). CubeState.localize relabels an
// algorithm if the learner is holding the cube some other way.

open CubeTypes

type stage =
  | Cross
  | FirstLayer
  | MiddleLayer
  | YellowCross
  | YellowFace
  | CornerPermute
  | EdgePermute

let stages = [Cross, FirstLayer, MiddleLayer, YellowCross, YellowFace, CornerPermute, EdgePermute]

let name = (st: stage): string =>
  switch st {
  | Cross => "White cross"
  | FirstLayer => "White corners"
  | MiddleLayer => "Middle edges"
  | YellowCross => "Yellow cross"
  | YellowFace => "Yellow face"
  | CornerPermute => "Place corners"
  | EdgePermute => "Place edges"
  }

let goal = (st: stage): string =>
  switch st {
  | Cross => "Put the four white edges around the white centre, each matching its side colour."
  | FirstLayer => "Drop the four white corners into place. The whole bottom layer becomes solid."
  | MiddleLayer => "Send the four non-yellow edges from the top into the middle layer."
  | YellowCross => "Flip the top edges until a yellow plus sign appears. Corners don't matter yet."
  | YellowFace => "Twist the top corners until the whole top face is yellow."
  | CornerPermute => "Move the top corners to their correct spots, twist ignored."
  | EdgePermute => "Cycle the last three edges home. This finishes the cube."
  }

let tip = (st: stage): string =>
  switch st {
  | Cross => "No algorithm here — line the edge up under its slot, then turn that face twice."
  | FirstLayer => "Bring the corner directly above its slot and repeat the trigger until it drops in white-side-down."
  | MiddleLayer => "Find a top edge with no yellow. Line its front colour up with its centre, then insert toward the side it belongs."
  | YellowCross => "Dot needs it three times, an L twice, a line once. Hold an L at the back-left, a line side to side."
  | YellowFace => "Repeat with a solved corner at the front-left. Ugly middle states are normal — keep going."
  | CornerPermute => "This cycles three corners and leaves the up-front-left one alone. Put an already-correct corner there; if none is correct, run it once and look again."
  | EdgePermute => "This cycles the other three edges and leaves the back one alone. Hold your solved edge at the back; if none is solved, run it once and look again."
  }

// The trigger(s) for a stage, named the way a tutorial names them.
let algorithms = (st: stage): array<(string, array<move>)> => {
  let alg = notation => notation->String.split(" ")->Array.filterMap(stringToMove)
  switch st {
  | Cross => []
  | FirstLayer => [("Trigger", alg("R U R' U'"))]
  | MiddleLayer => [
      ("Insert right", alg("U R U' R' U' F' U F")),
      ("Insert left", alg("U' L' U L U F U' F'")),
    ]
  | YellowCross => [("Edge flip", alg("F R U R' U' F'"))]
  | YellowFace => [("Sune", alg("R U R' U R U2 R'"))]
  | CornerPermute => [("A-perm", alg("R' F R' B2 R F' R' B2 R2"))]
  | EdgePermute => [("U-perm", alg("R U' R U R U R U' R' U' R2"))]
  }
}

// --- Detection --------------------------------------------------------------

let bottomEdges = [4, 5, 6, 7] // DR DF DL DB
let bottomCorners = [4, 5, 6, 7] // DFR DLF DBL DRB
let middleEdges = [8, 9, 10, 11] // FR FL BL BR
let topEdges = [0, 1, 2, 3] // UR UF UL UB
let topCorners = [0, 1, 2, 3] // URF UFL ULB UBR

let countTrue = (xs: array<'a>, f: 'a => bool): int =>
  xs->Array.reduce(0, (n, x) => f(x) ? n + 1 : n)

// How many of this stage's four pieces are done. Every stage happens to have
// four, which is what makes a uniform progress read-out possible.
let done = (s: CubeState.t, st: stage): int =>
  switch st {
  | Cross => countTrue(bottomEdges, i => CubeState.edgeSolved(s, i))
  | FirstLayer => countTrue(bottomCorners, i => CubeState.cornerSolved(s, i))
  | MiddleLayer => countTrue(middleEdges, i => CubeState.edgeSolved(s, i))
  | YellowCross => countTrue(topEdges, i => s.eo->Array.getUnsafe(i) == 0)
  | YellowFace => countTrue(topCorners, i => s.co->Array.getUnsafe(i) == 0)
  | CornerPermute => countTrue(topCorners, i => s.cp->Array.getUnsafe(i) == i)
  | EdgePermute => countTrue(topEdges, i => s.ep->Array.getUnsafe(i) == i)
  }

let total = 4

let isComplete = (s: CubeState.t, st: stage): bool => done(s, st) == total

// The stage the learner is actually on: the first one not yet finished.
let currentStage = (s: CubeState.t): option<stage> => stages->Array.find(st => !isComplete(s, st))

// --- Coaching ---------------------------------------------------------------

type lesson = {
  stage: stage,
  name: string,
  goal: string,
  tip: string,
  done: int,
  total: int,
  // Relabelled for however the learner is currently holding the cube.
  algorithms: array<(string, array<move>)>,
}

let lesson = (s: CubeState.t, st: stage): lesson => {
  stage: st,
  name: name(st),
  goal: goal(st),
  tip: tip(st),
  done: done(s, st),
  total,
  algorithms: algorithms(st)->Array.map(((label, alg)) => (label, CubeState.localize(s, alg))),
}

let coach = (s: CubeState.t): option<lesson> => currentStage(s)->Option.map(st => lesson(s, st))
