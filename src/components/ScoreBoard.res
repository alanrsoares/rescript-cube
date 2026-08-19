// src/components/ScoreBoard.res - Timer HUD & Best Score using UI primitives

open StyledCva
open Utils

// Identity left, run state right. The status pill used to sit in its own centre
// column, which left it floating in dead space on a wide header; it belongs next
// to the record it is about to beat.
module HeaderContainer = {
  let make = Tw.header(
    "mb-3 flex w-full max-w-6xl shrink-0 items-center justify-between gap-3 border-b border-border/70 pb-3 lg:mb-6 lg:pb-4",
  )
}

module LogoIcon = {
  let make = Tw.div(
    "plastic flex size-10 shrink-0 items-center justify-center rounded-xl border bg-card p-1 lg:size-11",
  )
}

module TitleText = {
  let make = Tw.h1("truncate text-lg font-semibold tracking-[-0.04em] text-foreground lg:text-2xl")
}

module Eyebrow = {
  let make = Tw.p(
    "hidden text-[10px] font-semibold uppercase tracking-[0.18em] text-muted-foreground sm:block",
  )
}

module StatusRegion = {
  let make = Tw.div("shrink-0")
}

module RecordCard = {
  let make = Tw.div("hidden min-w-[76px] flex-col items-end sm:flex")
}

module RecordLabel = {
  let make = Tw.span(
    "flex items-center gap-1 text-[10px] font-medium uppercase tracking-wider text-muted-foreground",
  )
}

module RecordValue = {
  let make = Tw.span("font-mono text-sm font-semibold tabular-nums text-warning")
}

@react.component
let make = (
  ~timerState: Timer.timerState,
  ~timerMs: float,
  ~bestTime: option<float>,
  ~onOpenShortcuts: unit => unit,
) => {
  <HeaderContainer>
    <div className="flex min-w-0 items-center gap-3 lg:gap-3.5">
      <LogoIcon>
        <div className="size-full bg-[url('/cube-icon.svg')] bg-contain bg-center bg-no-repeat" />
      </LogoIcon>
      <div className="min-w-0">
        <Eyebrow> {renderString("ReScript cube trainer")} </Eyebrow>
        <TitleText> {renderString("Cube Lab")} </TitleText>
      </div>
    </div>

    <div className="flex shrink-0 items-center gap-3 lg:gap-4">
      <StatusRegion ariaLive=#polite>
        {switch timerState {
        | Inspecting(secs) =>
          <Badge variant=#warning className="px-2.5 py-1">
            {Icon.render(Icon.eye, ~size=12)}
            <span className="hidden sm:inline"> {renderString("Inspect")} </span>
            <span className="tabular-nums"> {renderString(Int.toString(secs) ++ "s")} </span>
          </Badge>
        | Running(_) =>
          <Badge variant=#success className="px-2.5 py-1">
            {Icon.render(Icon.timer, ~size=12)}
            <span className="text-sm tabular-nums">
              {renderString(Timer.formatTime(timerMs))}
            </span>
          </Badge>
        | Solved(ms) =>
          <Badge variant=#default className="px-2.5 py-1">
            {Icon.render(Icon.partyPopper, ~size=12)}
            <span className="hidden sm:inline"> {renderString("Solved")} </span>
            <span className="tabular-nums"> {renderString(Timer.formatTime(ms))} </span>
          </Badge>
        | Idle =>
          <Badge variant=#secondary className="px-2.5 py-1"> {renderString("Ready")} </Badge>
        }}
      </StatusRegion>

      <div className="hidden h-8 w-px shrink-0 bg-border sm:block" />

      <RecordCard>
        <RecordLabel>
          {Icon.render(Icon.trophy, ~size=10)}
          {renderString("Personal Best")}
        </RecordLabel>
        <RecordValue>
          {switch bestTime {
          | Some(t) => renderString(Timer.formatTime(t))
          | None => renderString("--:--.--")
          }}
        </RecordValue>
      </RecordCard>

      <Button
        variant=#ghost
        btnSize=#icon
        className="hidden rounded-full lg:inline-flex"
        onClick={_ => onOpenShortcuts()}
        ariaLabel="Keyboard shortcuts"
        title="Keyboard Controls"
      >
        {Icon.render(Icon.keyboard)}
      </Button>
    </div>
  </HeaderContainer>
}
