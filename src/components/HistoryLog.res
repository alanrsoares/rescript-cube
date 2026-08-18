// src/components/HistoryLog.res - Move History Log Stream using UI primitives

open StyledCva
open CubeTypes
open Utils

module LogBox = {
  let make = Tw.div(
    ScrollArea.bar ++ " flex min-h-[50px] flex-1 flex-wrap content-start gap-1 rounded-md lg:max-h-24 lg:flex-none border bg-background/60 p-3 font-mono text-xs overflow-y-auto",
  )
}

@react.component
let make = (~moveHistory: array<move>) => {
  <div className="flex min-h-0 flex-1 flex-col gap-2 rounded-xl border bg-card p-4 lg:flex-none">
    <div
      className="flex shrink-0 items-center justify-between text-xs font-medium text-muted-foreground"
    >
      <span className="flex items-center gap-1.5">
        {Icon.render(Icon.history, ~size=14)}
        {renderString("Move History Log")}
      </span>
      <span className="font-mono text-muted-foreground">
        {renderString(`${Int.toString(Array.length(moveHistory))} moves`)}
      </span>
    </div>
    <LogBox>
      {if Array.length(moveHistory) == 0 {
        <span className="italic text-muted-foreground"> {renderString("No moves made yet.")} </span>
      } else {
        moveHistory
        ->Array.mapWithIndex((m, idx) => {
          <Badge key={Int.toString(idx)} variant=#ghost> {renderString(moveToString(m))} </Badge>
        })
        ->renderArray
      }}
    </LogBox>
  </div>
}
