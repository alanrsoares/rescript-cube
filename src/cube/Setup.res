// src/cube/Setup.res - practice-state generation.
//
// Drilling one stage means starting from a cube where every earlier stage is
// already solved. Rather than search for such a state, we build it: scramble
// only with sequences that provably cannot disturb the earlier stages.

open CubeTypes

let alg = (notation: string): array<move> =>
  notation->String.split(" ")->Array.filterMap(stringToMove)

let inverse = (ms: array<move>): array<move> => ms->Array.map(invertMove)->Array.toReversed

// setup · core · setup⁻¹ — same effect, moved to a different part of the layer.
let conjugate = (setup: array<move>, core: array<move>): array<move> =>
  [setup, core, inverse(setup)]->Array.flat

let randomPick = (xs: array<'a>): 'a => {
  let i = Math.floor(Math.random() *. Float.fromInt(Array.length(xs)))->Float.toInt
  let last = Array.length(xs) - 1
  xs->Array.getUnsafe(i > last ? last : i)
}

let uTurns = [alg("U"), alg("U'"), alg("U2")]

let withInverses = (xs: array<array<move>>): array<array<move>> =>
  Array.concat(xs, xs->Array.map(inverse))

// A conjugate X U… X' returns X's layer, so the cross survives untouched.
let crossSafe = ["R U R' U'", "L' U' L U", "F' U' F U", "B U B' U'"]->Array.map(alg)

let firstLayerSafe = ["U R U' R' U' F' U F", "U' L' U L U F U' F'"]->Array.map(alg)

let orientEdges = alg("F R U R' U' F'")
let sune = alg("R U R' U R U2 R'")
// Keeps the up-front-left corner; a real A-perm, so corner twist survives it.
let aPerm = alg("R' F R' B2 R F' R' B2 R2")
let uPerm = alg("R U' R U R U R U' R' U' R2")

// Sequences that leave every stage before `st` intact.
let safeBlocks = (st: Method.stage): array<array<move>> =>
  switch st {
  | Method.Cross => []
  | FirstLayer => Array.concat(uTurns, withInverses(crossSafe))
  | MiddleLayer => Array.concat(uTurns, withInverses(firstLayerSafe))
  | YellowCross => Array.concat(uTurns, withInverses([orientEdges, sune]))
  | YellowFace => Array.concat(uTurns, withInverses([sune]))
  | CornerPermute => Array.concat(uTurns, withInverses([aPerm, uPerm]))
  // A bare U turn would undo the corners placed in the previous stage, so the
  // edge drill varies its case by conjugating the U-perm instead.
  | EdgePermute => withInverses(Array.concat([[]], uTurns)->Array.map(auf => conjugate(auf, uPerm)))
  }

let blockCount = (st: Method.stage): int =>
  switch st {
  | Method.Cross => 0
  | FirstLayer | MiddleLayer => 6
  | _ => 4
  }

// A scramble that sets up `st` and nothing before it. Retries until the stage is
// actually unsolved — a random draw can land back on a finished case.
let practiceScramble = (st: Method.stage): array<move> => {
  let blocks = safeBlocks(st)
  let draw = () =>
    switch st {
    | Method.Cross => CubeSolver.generateScramble(20)
    | _ => Array.fromInitializer(~length=blockCount(st), _ => randomPick(blocks))->Array.flat
    }
  let rec attempt = (n: int) => {
    let moves = draw()
    if n <= 0 || !Method.isComplete(CubeState.fromMoves(moves), st) {
      moves
    } else {
      attempt(n - 1)
    }
  }
  attempt(12)
}
