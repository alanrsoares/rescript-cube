// src/components/CoachPanel.res - the curriculum surface: where you are, what to do next.

open StyledCva
open CubeTypes
open Utils

module StageRow = {
  type state = [#current | #complete | #todo]

  type props = {
    ...styledProps,
    @as("$state") rowState?: state,
  }

  let make: React.component<props> = Tw.divWithConfig(
    "flex items-center gap-2.5 rounded-md px-2.5 py-1.5 text-sm transition-colors",
    {
      "variants": {
        "$state": {
          "current": "bg-primary/10 text-foreground ring-1 ring-primary/30",
          "complete": "text-muted-foreground",
          "todo": "text-muted-foreground/60",
        },
      },
      "defaultVariants": {"$state": "todo"},
    },
  )
}

module AlgRow = {
  let make = Tw.div("flex flex-wrap items-center gap-2 rounded-md border bg-background/60 p-2.5")
}

@react.component
let make = (
  ~state: CubeState.t,
  ~canSolve: bool,
  ~onSolve: unit => unit,
  ~onPlay: array<move> => unit,
  ~onPractice: Method.stage => unit,
) => {
  let current = Method.currentStage(state)

  <Card.Root className="min-h-0 flex-1 lg:flex-none">
    <Card.Header className="shrink-0">
      <div>
        <Card.Title>
          {Icon.render(Icon.graduationCap)}
          {renderString("Beginner method")}
        </Card.Title>
        <Card.Description>
          {renderString(
            switch current {
            | None => "Solved"
            | Some(st) =>
              `Stage ${Int.toString(Method.stages->Array.indexOf(st) + 1)} of ${Int.toString(
                  Array.length(Method.stages),
                )}`
            },
          )}
        </Card.Description>
      </div>
      <Button
        btnSize=#xs
        disabled={!canSolve}
        title="Solve the recorded cube position"
        onClick={_ => onSolve()}
      >
        {Icon.render(Icon.wandSparkles, ~size=13)}
        {renderString("Solve")}
      </Button>
    </Card.Header>

    <ScrollArea className="flex flex-col gap-4 lg:overflow-visible">
      <div className="flex flex-col gap-0.5">
        {Method.stages
        ->Array.map(st => {
          let done = Method.done(state, st)
          let complete = done == Method.total
          <StageRow
            key={Method.name(st)}
            rowState={complete ? #complete : current == Some(st) ? #current : #todo}
          >
            {complete
              ? Icon.render(Icon.circleCheck, ~size=15)
              : Icon.render(Icon.circle, ~size=15)}
            <span className="flex-1"> {renderString(Method.name(st))} </span>
            <span className="font-mono text-xs tabular-nums">
              {renderString(`${Int.toString(done)}/${Int.toString(Method.total)}`)}
            </span>
            <Button
              variant=#ghost btnSize=#xs title="Practice this stage" onClick={_ => onPractice(st)}
            >
              {Icon.render(Icon.dumbbell, ~size=13)}
            </Button>
          </StageRow>
        })
        ->renderArray}
      </div>

      {switch Method.coach(state) {
      | None =>
        <div className="flex flex-col items-center gap-2 py-5 text-center text-success">
          {Icon.render(Icon.partyPopper, ~size=22)}
          <p className="text-xs"> {renderString("Cube solved. Drill any stage to sharpen it.")} </p>
        </div>
      | Some(lesson) =>
        <div className="flex flex-col gap-3 border-t pt-4">
          <div className="flex flex-col gap-1">
            <span className="text-sm font-semibold"> {renderString(lesson.name)} </span>
            <p className="text-xs text-muted-foreground"> {renderString(lesson.goal)} </p>
          </div>

          <div className="flex gap-2 rounded-md bg-muted/50 p-2.5 text-xs text-muted-foreground">
            <span className="mt-px shrink-0 text-warning">
              {Icon.render(Icon.lightbulb, ~size=14)}
            </span>
            {renderString(lesson.tip)}
          </div>

          {lesson.algorithms
          ->Array.map(((label, alg)) =>
            <AlgRow key={label}>
              <span className="text-xs font-medium text-muted-foreground">
                {renderString(label)}
              </span>
              <div className="flex flex-1 flex-wrap gap-1">
                {alg
                ->Array.mapWithIndex((m, i) =>
                  <Badge key={Int.toString(i)} variant=#pending>
                    {renderString(moveToString(m))}
                  </Badge>
                )
                ->renderArray}
              </div>
              <Button btnSize=#xs onClick={_ => onPlay(alg)}>
                {Icon.render(Icon.play, ~size=12)}
                {renderString("Play")}
              </Button>
            </AlgRow>
          )
          ->renderArray}
        </div>
      }}
    </ScrollArea>
  </Card.Root>
}
