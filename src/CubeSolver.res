// Cube Solver & Move History Optimizer

open CubeTypes

// Simplify and cancel adjacent redundant moves in a sequence
let simplifyMoves = (moves: list<move>): list<move> => {
  let rec simplify = (acc: list<move>, rest: list<move>) => {
    switch (acc, rest) {
    | (acc, list{}) => List.reverse(acc)
    | (list{}, list{m, ...tail}) => simplify(list{m}, tail)
    | (list{top, ...accTail}, list{m, ...restTail}) =>
      if withMoveDir(top, Clockwise) != withMoveDir(m, Clockwise) {
        simplify(list{m, top, ...accTail}, restTail)
      } else {
        let turns = moveDirOf(top)->moveDirQuarterTurns + moveDirOf(m)->moveDirQuarterTurns
        switch moveDirFromQuarterTurns(turns) {
        | None => simplify(accTail, restTail)
        | Some(dir) => simplify(list{withMoveDir(top, dir), ...accTail}, restTail)
        }
      }
    }
  }
  simplify(list{}, moves)
}

// Generate solution sequence by reversing and inverting history moves
let generateSolution = (history: array<move>): array<move> => {
  let reversedInverted = history->Array.map(invertMove)->Array.toReversed
  let simplifiedList = simplifyMoves(reversedInverted->List.fromArray)
  simplifiedList->List.toArray
}

// Generate a standard random scramble of specified length (default 20 moves)
let generateScramble = (length: int): array<move> => {
  let faces = [Up, Down, Left, Right, Front, Back]
  let dirs = [Clockwise, CounterClockwise, Double]

  let moves = []
  let lastFace = ref(None)

  for _ in 1 to length {
    let rec pickFace = () => {
      let idx = Math.floor(Math.random() *. 6.0)->Float.toInt
      let f = switch faces[idx] {
      | Some(faceVal) => faceVal
      | None => Up
      }
      switch (lastFace.contents, f) {
      | (Some(lf), f) if lf == f => pickFace()
      | _ => f
      }
    }
    let chosenFace = pickFace()
    lastFace := Some(chosenFace)

    let dirIdx = Math.floor(Math.random() *. 3.0)->Float.toInt
    let chosenDir = switch dirs[dirIdx] {
    | Some(d) => d
    | None => Clockwise
    }

    let m = moveForFace(chosenFace, chosenDir)
    let _ = Array.push(moves, m)
  }
  moves
}
