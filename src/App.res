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
@send external preventDefault: Dom.event => unit = "preventDefault"
external castEvtToKey: Dom.event => {
  "key": string,
  "shiftKey": bool,
  "metaKey": bool,
  "ctrlKey": bool,
  "code": string,
  "target": {"tagName": string},
} = "%identity"

type rubikViewProps = {
  theme: themeName,
  animSpeed: float,
  onContextInit: cubeContext => unit,
  onMoveCompleted: move => unit,
}

@module("./components/LazyRubikView.js")
external loadRubikView: unit => promise<React.component<rubikViewProps>> = "load"

let lazyRubikView = React.lazy_(loadRubikView)

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
    "plastic-panel relative min-h-[180px] w-full flex-1 rounded-xl border bg-card p-2 sm:p-3 lg:aspect-[4/3] lg:flex-none",
  )
}

module CubeSplash = {
  let make = Tw.div(
    "plastic-well flex h-full min-h-[180px] w-full flex-col items-center justify-center gap-3 rounded-lg border bg-background text-muted-foreground lg:min-h-[420px]",
  )
}

module SolvedBadge = {
  let make = Tw.div(
    "absolute left-4 top-4 flex items-center gap-1.5 rounded-md border border-success/30 bg-success/15 px-2.5 py-1 text-xs font-medium text-success lg:left-6 lg:top-6 lg:px-3 lg:py-1.5",
  )
}

@react.component
let make = () => {
  let (cubeCtx, setCubeCtx) = React.useState(() => None)
  let (cubeState, setCubeState) = React.useState(() => CubeState.solved())
  let (currentTheme, setCurrentTheme) = React.useState(() => Classic)
  let (animSpeed, setAnimSpeed) = React.useState(() => 0.18)
  let (timeline, setTimeline) = React.useState(() => Timeline.empty)
  let (timerState, setTimerState) = React.useState(() => Timer.Idle)
  let (timerMs, setTimerMs) = React.useState(() => 0.0)
  let (bestTime, setBestTime) = React.useState(() => Timer.getBestTime())
  let (showModal, setShowModal) = React.useState(() => false)
  // Phone sheets start collapsed so the cube owns the opening viewport.
  let (tab, setTab) = React.useState((): option<MobileTabs.tab> => None)
  let closeTab = () => setTab(_ => None)

  // The timeline drives an imperative move queue, so the ref is authoritative and
  // the state is only the copy React renders. `commitTimeline` is the sole writer,
  // which stops two undos in one tick from reading the same cursor and replaying
  // the same turn twice.
  let timelineRef = React.useRef(timeline)
  // Every landed move, including the opening scramble, is retained here so the
  // history solver can return the cube to its actual current position.
  let positionHistoryRef = React.useRef(([]: array<move>))
  let initialScrambleRef = React.useRef((None: option<array<move>>))
  let initialScrambleQueuedRef = React.useRef(false)
  let commitTimeline = (next: Timeline.t) => {
    timelineRef.current = next
    setTimeline(_ => next)
  }

  // Turns queued to satisfy a seek. They have to reach the model but not the
  // timeline, because `seek` already moved the cursor.
  let replayingRef = React.useRef(0)

  let isSolved = CubeState.isSolved(cubeState)
  let wasSolvedRef = React.useRef(isSolved)
  let suppressVictoryRef = React.useRef(false)

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
    if isSolved && !wasSolvedRef.current && !suppressVictoryRef.current {
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

    // Reset and scramble intentionally pass through the solved state. Clear the
    // one-shot guard once that transition has been observed (or skipped).
    suppressVictoryRef.current = false
    wasSolvedRef.current = isSolved
    None
  }, [isSolved])

  // The renderer reports each turn once its animation lands; the model follows.
  let handleMoveCompleted = (m: move) => {
    positionHistoryRef.current = Array.concat(positionHistoryRef.current, [m])
    if replayingRef.current > 0 {
      replayingRef.current = replayingRef.current - 1
    } else {
      commitTimeline(Timeline.record(timelineRef.current, m))
    }
    setCubeState(prev => CubeState.applyMove(prev, m))
  }

  // Start from a real scramble through the normal animation path, but keep its
  // moves out of the learner's history and leave the timer idle.
  let handleContextInit = (ctx: cubeContext) => setCubeCtx(_ => Some(ctx))

  React.useEffect(() => {
    switch cubeCtx {
    | Some(ctx) => {
        let scramble = switch initialScrambleRef.current {
        | Some(moves) => moves
        | None => {
            let moves = CubeSolver.generateScramble(20)
            initialScrambleRef.current = Some(moves)
            moves
          }
        }
        if !initialScrambleQueuedRef.current {
          initialScrambleQueuedRef.current = true
          replayingRef.current = replayingRef.current + Array.length(scramble)
          queueMoves(ctx, scramble)
        }
      }
    | None => ()
    }
    None
  }, [cubeCtx])

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

  let handleTriggerMove = (m: move) =>
    switch cubeCtx {
    | Some(ctx) => handleQueue([ViewFrame.relabel(viewFrame(ctx), m)])
    | None => ()
    }

  // Move labels follow the camera, so the preview must be localized through the
  // same frame before it reaches the renderer.
  let handlePreviewFace = (m: move) =>
    switch cubeCtx {
    | Some(ctx) => showFaceHighlight(ctx, ViewFrame.relabel(viewFrame(ctx), m))
    | None => ()
    }

  let handleClearFacePreview = () =>
    switch cubeCtx {
    | Some(ctx) => clearFaceHighlight(ctx)
    | None => ()
    }

  // Walk the timeline to `target` and play the turns it hands back. The cursor
  // moves now; the model catches up as each animation lands. A seek never starts
  // the timer, so taking a move back cannot open a timed attempt.
  let handleSeek = (target: int) =>
    switch cubeCtx {
    | Some(ctx) =>
      let (next, turns) = Timeline.seek(timelineRef.current, target)
      if Array.length(turns) > 0 {
        replayingRef.current = replayingRef.current + Array.length(turns)
        commitTimeline(next)
        queueMoves(ctx, turns)
      }
    | None => ()
    }

  let handleUndo = () => handleSeek(timelineRef.current.cursor - 1)
  let handleRedo = () => handleSeek(timelineRef.current.cursor + 1)

  // Reset both the rendered cube and the model back to solved.
  let restart = (ctx: cubeContext) => {
    resetCube(ctx)
    setCubeState(_ => CubeState.solved())
    positionHistoryRef.current = []
    suppressVictoryRef.current = true

    // `resetCube` drops the queue, so turns still owed to a seek will never land.
    // Forget them, or the next real move would be mistaken for a replay.
    replayingRef.current = 0
    commitTimeline(Timeline.empty)
    setTimerMs(_ => 0.0)
  }

  let handleScramble = () =>
    switch cubeCtx {
    | Some(ctx) =>
      restart(ctx)
      let scramble = CubeSolver.generateScramble(20)

      // Scrambles establish a position to solve; only the learner's moves belong
      // in undo/redo history. The complete position history still retains them
      // so the Solve action can reverse the scramble.
      replayingRef.current = replayingRef.current + Array.length(scramble)
      queueMoves(ctx, scramble)
      setTimerState(_ => Inspecting(15))
    | None => ()
    }

  let handleReset = () =>
    switch cubeCtx {
    | Some(ctx) =>
      restart(ctx)
      setTimerState(_ => Idle)
    | None => ()
    }

  // The app knows every move that produced the current logical state, including
  // the opening scramble. Reversing that path is a guaranteed solution without
  // pretending the fixed beginner-method examples are a general-purpose solver.
  let handleSolve = () =>
    switch cubeCtx {
    | Some(ctx) if !isSolved && replayingRef.current == 0 =>
      queueMoves(ctx, CubeSolver.generateSolution(positionHistoryRef.current))
    | _ => ()
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
        // Cmd/Ctrl+Z walks the timeline. The guard matters twice: it keeps the
        // browser from undoing the page, and it keeps a modified Z from reading
        // as a Z turn.
        if evt["metaKey"] || evt["ctrlKey"] {
          if String.toLowerCase(evt["key"]) == "z" {
            preventDefault(e)
            evt["shiftKey"] ? handleRedo() : handleUndo()
          }
        } else {
          let notation = String.toUpperCase(evt["key"]) ++ (evt["shiftKey"] ? "'" : "")
          switch stringToMove(notation) {
          | Some(move) => handleTriggerMove(move)
          | None => ()
          }
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
          <React.Suspense
            fallback={<CubeSplash>
              <div className="grid grid-cols-3 gap-1" ariaLabel="Loading cube">
                <span className="size-3 animate-pulse rounded-sm bg-primary/85" />
                <span
                  className="size-3 animate-pulse rounded-sm bg-primary/65 [animation-delay:120ms]"
                />
                <span
                  className="size-3 animate-pulse rounded-sm bg-primary/45 [animation-delay:240ms]"
                />
              </div>
              <span className="text-xs font-medium tracking-[0.18em] uppercase">
                {renderString("Loading cube")}
              </span>
            </CubeSplash>}
          >
            {React.createElement(
              lazyRubikView,
              {
                theme: currentTheme,
                animSpeed,
                onContextInit: handleContextInit,
                onMoveCompleted: handleMoveCompleted,
              },
            )}
          </React.Suspense>
          {isSolved
            ? <SolvedBadge>
                {Icon.render(Icon.check, ~size=14)}
                {renderString("Cube Solved")}
              </SolvedBadge>
            : React.null}
        </CanvasCard>

        <Toolbar
          canUndo={Timeline.canUndo(timeline)}
          canRedo={Timeline.canRedo(timeline)}
          onUndo={handleUndo}
          onRedo={handleRedo}
          onScramble={handleScramble}
          onReset={handleReset}
        />

        <Sheet active={tab == Some(#moves)} onClose={closeTab}>
          <Controls
            currentTheme={currentTheme}
            animSpeed={animSpeed}
            onTriggerMove={handleTriggerMove}
            onPreviewFace={handlePreviewFace}
            onClearFacePreview={handleClearFacePreview}
            onChangeTheme={t => setCurrentTheme(_ => t)}
            onChangeSpeed={spd => setAnimSpeed(_ => spd)}
          />
        </Sheet>
      </section>

      <section className="flex min-h-0 flex-col gap-3 lg:col-span-5 lg:gap-6">
        <Sheet active={tab == Some(#coach)} onClose={closeTab}>
          <CoachPanel
            state={cubeState}
            canSolve={!isSolved && replayingRef.current == 0}
            onSolve={handleSolve}
            onPlay={handleQueue}
            onPractice={handlePractice}
          />
        </Sheet>
        <Sheet active={tab == Some(#log)} onClose={closeTab}>
          <HistoryLog timeline onSeek={handleSeek} />
        </Sheet>
      </section>
    </MainGrid>

    <MobileTabs active={tab} onSelect={t => setTab(_ => t)} />

    <ShortcutsModal isOpen={showModal} onClose={() => setShowModal(_ => false)} />
  </AppLayout>
}
