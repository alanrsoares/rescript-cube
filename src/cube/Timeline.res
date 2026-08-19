// src/cube/Timeline.res - the undo/redo cursor over a run of moves.
//
// One list, one cursor. `moves[0 .. cursor - 1]` are on the cube; `moves[cursor
// ..]` were taken back but kept, so redo can replay them. Recording a fresh
// move discards that tail, which is what keeps the timeline a line and not a
// tree.
//
// Pure: it hands back the turns the renderer must play and never touches it.

open CubeTypes

type t = {moves: array<move>, cursor: int}

let empty = {moves: [], cursor: 0}

let length = t => Array.length(t.moves)

let applied = t => t.moves->Array.slice(~start=0, ~end=t.cursor)

let undone = t => t.moves->Array.slice(~start=t.cursor, ~end=length(t))

let canUndo = t => t.cursor > 0

let canRedo = t => t.cursor < length(t)

let record = (t, m) => {moves: Array.concat(applied(t), [m]), cursor: t.cursor + 1}

// The turns needed to land the cursor on `target`, in play order: inverses back
// to front when rewinding, the recorded moves as-is when replaying. Out-of-range
// targets clamp rather than fail, so a stale click from the log is harmless.
let seek = (t, target) => {
  let bounded = Math.Int.max(0, Math.Int.min(target, length(t)))
  let turns = if bounded < t.cursor {
    t.moves
    ->Array.slice(~start=bounded, ~end=t.cursor)
    ->Array.toReversed
    ->Array.map(invertMove)
  } else {
    t.moves->Array.slice(~start=t.cursor, ~end=bounded)
  }
  ({...t, cursor: bounded}, turns)
}

let undo = t => seek(t, t.cursor - 1)

let redo = t => seek(t, t.cursor + 1)
