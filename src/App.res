// App.res - Main application shell. Owns the logical cube; Three.js only renders it.

open StyledCva
open CubeTypes
open Cube3D
open Utils

@val
external addWindowEventListener: (string, Dom.event => unit) => unit = "window.addEventListener"
@val
external removeWindowEventListener: (string, Dom.event => unit) => unit =
  "window.removeEventListener"
@val external setInterval: (unit => unit, int) => int = "setInterval"
@val external clearInterval: int => unit = "clearInterval"
@val external dateNow: unit => float = "Date.now"
external castEvtToKey: Dom.event => {
  "key": string,
  "shiftKey": bool,
  "code": string,
  "target": {"tagName": string},
} = "%identity"

// Phone: one viewport-tall app, the cube is the hero and the panels live behind
// a bottom tab bar. Desktop (lg): the page scrolls and every panel is on screen.
module AppLayout = {
  let make = Tw.div(
    "flex h-[100dvh] flex-col overflow-hidden bg-background p-4 pb-0 font-sans text-foreground lg:h-auto lg:min-h-screen lg:items-center lg:overflow-visible lg:p-8 lg:pb-8",
  )
}

module MainGrid = {
  let make = Tw.main(
    "relative flex min-h-0 w-full max-w-6xl flex-1 flex-col gap-3 lg:grid lg:flex-none lg:grid-cols-12 lg:items-start lg:gap-6",
  )
}

module CanvasCard = {
  let make = Tw.div(
    "relative min-h-[180px] w-full flex-1 rounded-xl border bg-card p-2 shadow-sm sm:p-3 lg:aspect-[4/3] lg:flex-none",
  )
}

module SolvedBadge = {
  let make = Tw.div(
    "absolute left-4 top-4 flex items-center gap-1.5 rounded-md border border-success/30 bg-success/15 px-2.5 py-1 text-xs font-medium text-success backdrop-blur-md lg:left-6 lg:top-6 lg:px-3 lg:py-1.5",
  )
}

module ViewResetSlot = {
  let make = Tw.div("absolute right-4 top-4 lg:right-6 lg:top-6")
}

@react.component
let make = () => {
  let (cubeCtx, setCubeCtx) = React.useState(() => None)
  let (cubeState, setCubeState) = React.useState(() => CubeState.solved())
  let (currentTheme, setCurrentTheme) = React.useState(() => Classic)
  let (animSpeed, setAnimSpeed) = React.useState(() => 0.18)
  let (moveHistory, setMoveHistory) = React.useState(() => [])
  let (timerState, setTimerState) = React.useState(() => Timer.Idle)
  let (timerMs, setTimerMs) = React.useState(() => 0.0)
  let (bestTime, setBestTime) = React.useState(() => Timer.getBestTime())
  let (showModal, setShowModal) = React.useState(() => false)
  let (tab, setTab) = React.useState((): option<MobileTabs.tab> => Some(#coach))
  let closeTab = () => setTab(_ => None)

  let isSolved = CubeState.isSolved(cubeState)
  let wasSolvedRef = React.useRef(isSolved)

  // Timer tick
  React.useEffect(() => {
    switch timerState {
    | Running(startTime) =>
      let intervalId = setInterval(() => setTimerMs(_ => dateNow() -. startTime), 10)
      Some(() => clearInterval(intervalId))
    | Inspecting(secondsLeft) =>
      let intervalId = setInterval(
        () =>
          setTimerState(_ => secondsLeft > 1 ? Inspecting(secondsLeft - 1) : Running(dateNow())),
        1000,
      )
      Some(() => clearInterval(intervalId))
    | Idle | Solved(_) => None
    }
  }, [timerState])

  // Celebrate only on the transition into a solved cube.
  React.useEffect(() => {
    if isSolved && !wasSolvedRef.current {
      Confetti.triggerVictory()
      setTimerState(st =>
        switch st {
        | Running(startTime) =>
          let elapsed = dateNow() -. startTime
          setTimerMs(_ => elapsed)
          if Timer.saveBestTime(elapsed) {
            setBestTime(_ => Some(elapsed))
          }
          Timer.Solved(elapsed)
        | _ => st
        }
      )
    }
    wasSolvedRef.current = isSolved
    None
  }, [isSolved])

  // The renderer reports each turn once its animation lands; the model follows.
  let handleMoveCompleted = (m: move) => {
    setMoveHistory(prev => Array.concat(prev, [m]))
    setCubeState(prev => CubeState.applyMove(prev, m))
  }

  // Only a scramble starts a timed attempt, so drills and free play never
  // record a personal best.
  let startTimerOnFirstMove = () =>
    setTimerState(st =>
      switch st {
      | Inspecting(_) => Running(dateNow())
      | _ => st
      }
    )

  let handleQueue = (moves: array<move>) =>
    switch cubeCtx {
    | Some(ctx) =>
      queueMoves(ctx, moves)
      startTimerOnFirstMove()
    | None => ()
    }

  let handleTriggerMove = (m: move) => handleQueue([m])

  // Reset both the rendered cube and the model back to solved.
  let restart = (ctx: cubeContext) => {
    resetCube(ctx)
    setCubeState(_ => CubeState.solved())
    setMoveHistory(_ => [])
    setTimerMs(_ => 0.0)
  }

  let handleScramble = () =>
    switch cubeCtx {
    | Some(ctx) =>
      restart(ctx)
      queueMoves(ctx, CubeSolver.generateScramble(20))
      setTimerState(_ => Inspecting(15))
    | None => ()
    }

  let handleReset = () =>
    switch cubeCtx {
    | Some(ctx) =>
      restart(ctx)
      resetView(ctx)
      setTimerState(_ => Idle)
    | None => ()
    }

  // Recentre the camera without touching the cube: a bad viewing angle should
  // not cost the solve in progress.
  let handleResetView = () =>
    switch cubeCtx {
    | Some(ctx) => resetView(ctx)
    | None => ()
    }

  // Drill a single stage: solved cube, then a scramble that only disturbs that stage.
  let handlePractice = (stage: Method.stage) =>
    switch cubeCtx {
    | Some(ctx) =>
      restart(ctx)
      queueMoves(ctx, Setup.practiceScramble(stage))
      setTimerState(_ => Idle)
    | None => ()
    }

  React.useEffect(() => {
    let handleKeyDown = (e: Dom.event) => {
      let evt = castEvtToKey(e)
      let tag = evt["target"]["tagName"]
      if tag != "INPUT" && tag != "TEXTAREA" {
        let notation = String.toUpperCase(evt["key"]) ++ (evt["shiftKey"] ? "'" : "")
        switch stringToMove(notation) {
        | Some(move) => handleTriggerMove(move)
        | None => ()
        }
      }
    }
    addWindowEventListener("keydown", handleKeyDown)
    Some(() => removeWindowEventListener("keydown", handleKeyDown))
    // `timerState` changes every 10 ms while running. The handler uses functional
    // state updates, so it only needs replacing when the renderer context changes.
  }, [cubeCtx])

  <AppLayout>
    <ScoreBoard
      timerState={timerState}
      timerMs={timerMs}
      bestTime={bestTime}
      onOpenShortcuts={() => setShowModal(_ => true)}
    />

    <MainGrid>
      <section className="flex min-h-0 flex-1 flex-col gap-3 lg:col-span-7 lg:gap-4">
        <CanvasCard>
          <RubikView
            theme={currentTheme}
            animSpeed={animSpeed}
            onContextInit={ctx => setCubeCtx(_ => Some(ctx))}
            onMoveCompleted={handleMoveCompleted}
          />
          <ViewResetSlot>
            <Button
              variant=#ghost
              btnSize=#icon
              className="size-8 rounded-md bg-background/60 backdrop-blur-md hover:bg-accent"
              title="Recentre the view"
              onClick={_ => handleResetView()}
            >
              {Icon.render(Icon.target, ~size=15)}
            </Button>
          </ViewResetSlot>
          {isSolved
            ? <SolvedBadge>
                {Icon.render(Icon.check, ~size=14)}
                {renderString("Cube Solved")}
              </SolvedBadge>
            : React.null}
        </CanvasCard>

        <Toolbar onScramble={handleScramble} onReset={handleReset} />

        <Sheet active={tab == Some(#moves)} onClose={closeTab}>
          <Controls
            currentTheme={currentTheme}
            animSpeed={animSpeed}
            onTriggerMove={handleTriggerMove}
            onChangeTheme={t => setCurrentTheme(_ => t)}
            onChangeSpeed={spd => setAnimSpeed(_ => spd)}
          />
        </Sheet>
      </section>

      <section className="flex min-h-0 flex-col gap-3 lg:col-span-5 lg:gap-6">
        <Sheet active={tab == Some(#coach)} onClose={closeTab}>
          <CoachPanel state={cubeState} onPlay={handleQueue} onPractice={handlePractice} />
        </Sheet>
        <Sheet active={tab == Some(#log)} onClose={closeTab}>
          <HistoryLog moveHistory={moveHistory} />
        </Sheet>
      </section>
    </MainGrid>

    <MobileTabs active={tab} onSelect={t => setTab(_ => t)} />

    <ShortcutsModal isOpen={showModal} onClose={() => setShowModal(_ => false)} />
  </AppLayout>
}
