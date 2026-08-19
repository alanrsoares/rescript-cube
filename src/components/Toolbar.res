// src/components/Toolbar.res - the actions that must stay reachable on a phone
// whichever panel is open, so they sit under the cube rather than inside a tab.

open StyledCva
open Utils

module Row = {
  let make = Tw.div(
    "plastic-panel flex shrink-0 items-center gap-2 rounded-xl border bg-card p-2 lg:p-3",
  )
}

@react.component
let make = (
  ~className: string="",
  ~canUndo: bool,
  ~canRedo: bool,
  ~onUndo: unit => unit,
  ~onRedo: unit => unit,
  ~onScramble: unit => unit,
  ~onReset: unit => unit,
) =>
  <Row className>
    <Button
      variant=#outline
      btnSize=#icon
      className="size-10 shrink-0"
      disabled={!canUndo}
      ariaLabel="Undo move"
      title="Undo move"
      onClick={_ => onUndo()}
    >
      {Icon.render(Icon.undo)}
    </Button>
    <Button
      variant=#outline
      btnSize=#icon
      className="size-10 shrink-0"
      disabled={!canRedo}
      ariaLabel="Redo move"
      title="Redo move"
      onClick={_ => onRedo()}
    >
      {Icon.render(Icon.redo)}
    </Button>
    <Button variant=#default btnSize=#lg className="flex-1" onClick={_ => onScramble()}>
      {Icon.render(Icon.shuffle)}
      {renderString("Scramble")}
    </Button>
    <Button variant=#secondary btnSize=#lg className="flex-1" onClick={_ => onReset()}>
      {Icon.render(Icon.rotateCcw)}
      {renderString("Reset")}
    </Button>
  </Row>
