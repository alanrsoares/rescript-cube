// src/components/Toolbar.res - the two actions that must stay reachable on a phone
// whichever panel is open, so they sit under the cube rather than inside a tab.

open StyledCva
open Utils

module Row = {
  let make = Tw.div("flex shrink-0 items-center gap-2 rounded-xl border bg-card p-2 lg:p-3")
}

@react.component
let make = (~className: string="", ~onScramble: unit => unit, ~onReset: unit => unit) =>
  <Row className>
    <Button variant=#accent btnSize=#lg className="flex-1" onClick={_ => onScramble()}>
      {Icon.render(Icon.shuffle)}
      {renderString("Scramble")}
    </Button>
    <Button variant=#secondary btnSize=#lg className="flex-1" onClick={_ => onReset()}>
      {Icon.render(Icon.rotateCcw)}
      {renderString("Reset")}
    </Button>
  </Row>
