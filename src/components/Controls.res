// src/components/Controls.res - Move grids plus appearance settings.
// The scramble/reset actions live in Toolbar so they survive a phone's tab switch.

open StyledCva
open CubeTypes
open Utils

module SectionLabel = {
  let make = Tw.div("mb-2 text-[11px] font-medium uppercase tracking-wider text-muted-foreground")
}

module Group = {
  let make = Tw.div("plastic-well flex items-center gap-1 rounded-md border bg-background p-1")
}

// Fingers are wider than cursors: the grid keeps six columns but grows the rows
// on a phone and shrinks back to the dense desktop size at lg.
let moveBtnClass = "h-11 min-w-0 px-0 text-sm lg:h-8 lg:text-xs"

type turnDirection =
  | ClockwiseTurn
  | CounterClockwiseTurn

@react.component
let make = (
  ~currentTheme: themeName,
  ~animSpeed: float,
  ~onTriggerMove: move => unit,
  ~onPreviewFace: move => unit,
  ~onClearFacePreview: unit => unit,
  ~onChangeTheme: themeName => unit,
  ~onChangeSpeed: float => unit,
) => {
  let (turnDirection, setTurnDirection) = React.useState(() => ClockwiseTurn)

  let renderBtn = (label: string, m: move, variant: Button.variant) =>
    <Button
      key={label}
      variant
      btnSize=#sm
      className={moveBtnClass}
      onClick={_ => onTriggerMove(m)}
      onMouseEnter={_ => onPreviewFace(m)}
      onMouseLeave={_ => onClearFacePreview()}
    >
      {renderString(label)}
    </Button>

  let renderRow = (label, buttons) =>
    <div>
      <SectionLabel> {renderString(label)} </SectionLabel>
      <div className="grid grid-cols-6 gap-1.5 lg:gap-2"> {buttons->renderArray} </div>
    </div>

  let faceMove = (face: string): move =>
    switch turnDirection {
    | ClockwiseTurn =>
      switch face {
      | "U" => MoveU(Clockwise)
      | "D" => MoveD(Clockwise)
      | "L" => MoveL(Clockwise)
      | "R" => MoveR(Clockwise)
      | "F" => MoveF(Clockwise)
      | _ => MoveB(Clockwise)
      }
    | CounterClockwiseTurn =>
      switch face {
      | "U" => MoveU(CounterClockwise)
      | "D" => MoveD(CounterClockwise)
      | "L" => MoveL(CounterClockwise)
      | "R" => MoveR(CounterClockwise)
      | "F" => MoveF(CounterClockwise)
      | _ => MoveB(CounterClockwise)
      }
    }

  <Card.Root className="min-h-0 flex-1 p-4 lg:flex-none lg:p-5">
    <Card.Header className="shrink-0">
      <Card.Title>
        {Icon.render(Icon.gamepad)}
        {renderString("Face Rotations")}
      </Card.Title>
      <Card.Description className="hidden sm:block">
        {renderString("Drag the cube, tap, or use the keyboard")}
      </Card.Description>
    </Card.Header>

    <ScrollArea className="flex flex-col gap-4 lg:overflow-visible">
      <div className="flex flex-col gap-2">
        <div className="flex items-center justify-between gap-3">
          <SectionLabel> {renderString("Face turns")} </SectionLabel>
          <Group>
            <Button
              variant={turnDirection == ClockwiseTurn ? #move : #ghost}
              btnSize=#xs
              className="h-7"
              ariaLabel="Use clockwise face turns"
              title="Clockwise turns"
              onClick={_ => setTurnDirection(_ => ClockwiseTurn)}
            >
              {renderString("Clockwise")}
            </Button>
            <Button
              variant={turnDirection == CounterClockwiseTurn ? #prime : #ghost}
              btnSize=#xs
              className="h-7"
              ariaLabel="Use counter-clockwise face turns"
              title="Counter-clockwise turns"
              onClick={_ => setTurnDirection(_ => CounterClockwiseTurn)}
            >
              {renderString("Counter-clockwise")}
            </Button>
          </Group>
        </div>
        <div className="grid grid-cols-6 gap-1.5 lg:gap-2">
          {["U", "D", "L", "R", "F", "B"]
          ->Array.map(face => renderBtn(face, faceMove(face), #move))
          ->renderArray}
        </div>
      </div>
      {renderRow(
        "Slices & whole cube",
        [
          renderBtn("M", MoveM(Clockwise), #slice),
          renderBtn("E", MoveE(Clockwise), #slice),
          renderBtn("S", MoveS(Clockwise), #slice),
          renderBtn("X", MoveX(Clockwise), #slice),
          renderBtn("Y", MoveY(Clockwise), #slice),
          renderBtn("Z", MoveZ(Clockwise), #slice),
        ],
      )}

      <div className="flex flex-wrap items-center gap-2 border-t pt-4">
        <Group>
          {themeOptions
          ->Array.map(((theme, label)) => {
            <Button
              key={label}
              variant={currentTheme == theme ? #default : #ghost}
              btnSize=#xs
              className="h-8 lg:h-7"
              onClick={_ => onChangeTheme(theme)}
            >
              {renderString(label)}
            </Button>
          })
          ->renderArray}
        </Group>

        <Group>
          {[("slow", Icon.snail, 0.08), ("normal", Icon.rocket, 0.18), ("fast", Icon.zap, 0.35)]
          ->Array.map(((label, icon, spd)) =>
            <Button
              key={label}
              variant={animSpeed == spd ? #secondary : #ghost}
              btnSize=#xs
              className="h-8 lg:h-7"
              title={label}
              onClick={_ => onChangeSpeed(spd)}
            >
              {Icon.render(icon, ~size=14)}
            </Button>
          )
          ->renderArray}
        </Group>
      </div>
    </ScrollArea>
  </Card.Root>
}
