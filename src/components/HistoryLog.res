// src/components/HistoryLog.res - the timeline as a clickable strip of turns.
//
// Applied turns read normally; turns taken back stay visible but struck through,
// because that tail is what redo replays. Clicking a turn seeks to just after it.

open StyledCva
open CubeTypes
open Utils

module LogBox = {
  let make = Tw.div(
    ScrollArea.bar ++ " plastic-well flex min-h-[50px] flex-1 flex-wrap content-start gap-1 rounded-md lg:max-h-24 lg:flex-none border bg-background p-3 font-mono text-xs overflow-y-auto",
  )
}

module MoveButton = {
  let make = Tw.button(
    "cursor-pointer rounded-md outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50",
  )
}

@react.component
let make = (~timeline: Timeline.t, ~onSeek: int => unit) => {
  let total = Timeline.length(timeline)
  let cursor = timeline.cursor
  let undoneCount = Array.length(Timeline.undone(timeline))

  <div
    className="plastic-panel flex min-h-0 flex-1 flex-col gap-2 rounded-xl border bg-card p-4 lg:flex-none"
  >
    <div
      className="flex shrink-0 items-center justify-between text-xs font-medium text-muted-foreground"
    >
      <span className="flex items-center gap-1.5">
        {Icon.render(Icon.history, ~size=14)}
        {renderString("Move History Log")}
      </span>
      <span className="font-mono text-muted-foreground">
        {renderString(
          undoneCount > 0
            ? `${Int.toString(cursor)} / ${Int.toString(total)} moves`
            : `${Int.toString(total)} moves`,
        )}
      </span>
    </div>
    <LogBox>
      {if total == 0 {
        <span className="italic text-muted-foreground"> {renderString("No moves made yet.")} </span>
      } else {
        timeline.moves
        ->Array.mapWithIndex((m, idx) => {
          let isApplied = idx < cursor
          <MoveButton
            key={Int.toString(idx)}
            type_="button"
            title={isApplied ? "Rewind to just after this move" : "Replay through this move"}
            onClick={_ => onSeek(idx + 1)}
          >
            <Badge variant={isApplied ? #ghost : #done}> {renderString(moveToString(m))} </Badge>
          </MoveButton>
        })
        ->renderArray
      }}
    </LogBox>
  </div>
}
