// src/cube/CubeState.res - the logical cube. Source of truth; Three.js only renders it.
//
// Cubie model with Kociemba indexing. Corner/edge permutation and orientation
// live in a FIXED frame (white D, green F, orange R). Whole-cube rotations never
// touch them; they only move `orient`, which maps a face *position* the learner
// is looking at to the fixed-frame face currently sitting there. Stage detection
// therefore works no matter how the cube has been turned in the viewport.
//
// Corners: URF UFL ULB UBR DFR DLF DBL DRB  (0..7)
// Edges:   UR UF UL UB DR DF DL DB FR FL BL BR  (0..11)

open CubeTypes

let faceU = 0
let faceR = 1
let faceF = 2
let faceD = 3
let faceL = 4
let faceB = 5

type t = {
  cp: array<int>,
  co: array<int>,
  ep: array<int>,
  eo: array<int>,
  orient: array<int>,
}

// A quarter turn, as the permutation it applies.
type turn = {cp: array<int>, co: array<int>, ep: array<int>, eo: array<int>}

let turnU = {
  cp: [3, 0, 1, 2, 4, 5, 6, 7],
  co: [0, 0, 0, 0, 0, 0, 0, 0],
  ep: [3, 0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11],
  eo: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
}

let turnR = {
  cp: [4, 1, 2, 0, 7, 5, 6, 3],
  co: [2, 0, 0, 1, 1, 0, 0, 2],
  ep: [8, 1, 2, 3, 11, 5, 6, 7, 4, 9, 10, 0],
  eo: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
}

let turnF = {
  cp: [1, 5, 2, 3, 0, 4, 6, 7],
  co: [1, 2, 0, 0, 2, 1, 0, 0],
  ep: [0, 9, 2, 3, 4, 8, 6, 7, 1, 5, 10, 11],
  eo: [0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0],
}

let turnD = {
  cp: [0, 1, 2, 3, 5, 6, 7, 4],
  co: [0, 0, 0, 0, 0, 0, 0, 0],
  ep: [0, 1, 2, 3, 5, 6, 7, 4, 8, 9, 10, 11],
  eo: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
}

let turnL = {
  cp: [0, 2, 6, 3, 4, 1, 5, 7],
  co: [0, 1, 2, 0, 0, 2, 1, 0],
  ep: [0, 1, 10, 3, 4, 5, 9, 7, 8, 2, 6, 11],
  eo: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
}

let turnB = {
  cp: [0, 1, 3, 7, 4, 5, 2, 6],
  co: [0, 0, 1, 2, 0, 0, 2, 1],
  ep: [0, 1, 2, 11, 4, 5, 6, 10, 8, 9, 3, 7],
  eo: [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 1],
}

let turnTable = [turnU, turnR, turnF, turnD, turnL, turnB]

// Whole-cube rotations, as face-position permutations: rot[p] = position whose
// face lands on p. rotX/Y/Z spin the cube the way R/U/F turn their layer.
let rotX = [2, 1, 3, 5, 4, 0]
let rotY = [0, 5, 1, 3, 2, 4]
let rotZ = [4, 0, 2, 1, 3, 5]

let quarters = (dir: moveDir): int =>
  switch dir {
  | Clockwise => 1
  | Double => 2
  | CounterClockwise => 3
  }

let solved = (): t => {
  cp: [0, 1, 2, 3, 4, 5, 6, 7],
  co: [0, 0, 0, 0, 0, 0, 0, 0],
  ep: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
  eo: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  orient: [0, 1, 2, 3, 4, 5],
}

let applyTurn = (s: t, k: turn): t => {
  cp: k.cp->Array.map(i => s.cp->Array.getUnsafe(i)),
  co: k.cp->Array.mapWithIndex((src, i) =>
    mod(s.co->Array.getUnsafe(src) + k.co->Array.getUnsafe(i), 3)
  ),
  ep: k.ep->Array.map(i => s.ep->Array.getUnsafe(i)),
  eo: k.ep->Array.mapWithIndex((src, i) =>
    mod(s.eo->Array.getUnsafe(src) + k.eo->Array.getUnsafe(i), 2)
  ),
  orient: s.orient,
}

let rec repeat = (s: t, step: t => t, n: int): t => n <= 0 ? s : repeat(step(s), step, n - 1)

// Turn the layer at face *position* p. Which cubies move depends on which
// fixed-frame face currently sits there.
let turnFace = (s: t, p: int, dir: moveDir): t => {
  let k = turnTable->Array.getUnsafe(s.orient->Array.getUnsafe(p))
  repeat(s, st => applyTurn(st, k), quarters(dir))
}

let rotate = (s: t, rot: array<int>, dir: moveDir): t =>
  repeat(
    s,
    st => {...st, orient: rot->Array.map(i => st.orient->Array.getUnsafe(i))},
    quarters(dir),
  )

let applyMove = (s: t, m: move): t =>
  switch m {
  | MoveU(d) => turnFace(s, faceU, d)
  | MoveR(d) => turnFace(s, faceR, d)
  | MoveF(d) => turnFace(s, faceF, d)
  | MoveD(d) => turnFace(s, faceD, d)
  | MoveL(d) => turnFace(s, faceL, d)
  | MoveB(d) => turnFace(s, faceB, d)
  | MoveX(d) => rotate(s, rotX, d)
  | MoveY(d) => rotate(s, rotY, d)
  | MoveZ(d) => rotate(s, rotZ, d)
  // A slice is a whole-cube rotation with the two outer layers turned back.
  | MoveM(d) => s->rotate(rotX, invertDir(d))->turnFace(faceR, d)->turnFace(faceL, invertDir(d))
  | MoveE(d) => s->rotate(rotY, invertDir(d))->turnFace(faceU, d)->turnFace(faceD, invertDir(d))
  | MoveS(d) => s->rotate(rotZ, d)->turnFace(faceF, invertDir(d))->turnFace(faceB, d)
  }

let applyMoves = (s: t, ms: array<move>): t => ms->Array.reduce(s, applyMove)

let fromMoves = (ms: array<move>): t => applyMoves(solved(), ms)

let indices = (n: int): array<int> => Array.fromInitializer(~length=n, i => i)

let inPlace = (perm: array<int>, ori: array<int>, i: int): bool =>
  perm->Array.getUnsafe(i) == i && ori->Array.getUnsafe(i) == 0

let cornerSolved = (s: t, i: int): bool => inPlace(s.cp, s.co, i)
let edgeSolved = (s: t, i: int): bool => inPlace(s.ep, s.eo, i)

// Solved regardless of how the learner is holding it.
let isSolved = (s: t): bool =>
  indices(8)->Array.every(i => cornerSolved(s, i)) &&
    indices(12)->Array.every(i => edgeSolved(s, i))

// Where a given cubie currently sits.
let edgeSlot = (s: t, cubie: int): int => s.ep->Array.indexOf(cubie)
let cornerSlot = (s: t, cubie: int): int => s.cp->Array.indexOf(cubie)

// --- Frame translation ------------------------------------------------------
// Lessons are written in the fixed frame. If the learner has rotated the cube,
// the same physical turn has a different letter, so algorithms get relabelled.

let faceIndex = (face: face): int =>
  switch face {
  | Up => faceU
  | Right => faceR
  | Front => faceF
  | Down => faceD
  | Left => faceL
  | Back => faceB
  }

let faceAtIndex = (index: int): face =>
  switch index {
  | 0 => Up
  | 1 => Right
  | 2 => Front
  | 3 => Down
  | 4 => Left
  | _ => Back
  }

let localize = (s: t, ms: array<move>): array<move> => {
  let position = f => s.orient->Array.indexOf(f)
  ms->Array.map(m =>
    switch faceOfMove(m) {
    | Some(face) => moveForFace(faceAtIndex(position(faceIndex(face))), moveDirOf(m))
    | None => m
    }
  )
}
