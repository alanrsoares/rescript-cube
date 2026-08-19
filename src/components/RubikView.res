// R3F owns the canvas, renderer lifecycle, resize handling, and frame loop.
// Cube3D remains the imperative domain renderer while it is incrementally
// migrated to declarative scene components.

open CubeTypes
open Cube3D
open Three

module CubeScene = {
  @react.component
  let make = (
    ~state: ReactThreeFiber.rootState,
    ~theme: themeName,
    ~animSpeed: float,
    ~onContextInit: cubeContext => unit,
    ~onMoveCompleted: move => unit,
  ) => {
    let ctxRef = React.useRef(None)
    let (ctx, setCtx) = React.useState(() => None)
    let r3f = ReactThreeFiber.rootStateObj(state)

    React.useEffect(() => {
      let ctx = Cube3D.init(~scene=r3f.scene, ~camera=r3f.camera, ~renderer=r3f.gl, theme)
      ctx.onMoveCompleted = Some(onMoveCompleted)
      ctx.animState.animSpeed = animSpeed
      ctxRef.current = Some(ctx)
      setCtx(_ => Some(ctx))

      Some(() => Cube3D.dispose(ctx))
    }, [])

    // The context is useful to the app only after React has mounted its
    // primitive cubies. Callers may establish an initial position immediately,
    // and doing that before this commit lets the mount put those meshes back in
    // their solved arrangement.
    React.useEffect(() => {
      switch ctx {
      | Some(ctx) => onContextInit(ctx)
      | None => ()
      }
      None
    }, [ctx])

    ReactThreeFiber.useFrame((_, deltaSeconds) =>
      switch ctxRef.current {
      | Some(ctx) =>
        fitCameraToCanvas(ctx, r3f.size.width, r3f.size.height)
        switch ctx.cameraSnap {
        | Some(_) => updateCameraSnap(ctx, deltaSeconds)
        | None => updateTrackballControls(ctx.cameraControls)
        }
        updateAnimation(ctx, deltaSeconds)
      | None => ()
      }
    )

    React.useEffect(() => {
      switch ctxRef.current {
      | Some(ctx) => updateThemeColors(ctx, theme)
      | None => ()
      }
      None
    }, [theme])

    React.useEffect(() => {
      switch ctxRef.current {
      | Some(ctx) => ctx.animState.animSpeed = animSpeed
      | None => ()
      }
      None
    }, [animSpeed])

    switch ctx {
    | Some(ctx) => {
        let cubies =
          ctx.cubies->Array.mapWithIndex((cubie, index) =>
            ReactThreeFiber.primitive(
              ~object=cubie,
              ~key=Int.toString(index),
              ~onPointerDown={event => handleCubiePointerDown(ctx, event)},
              ~onPointerMove={event => handleCubiePointerMove(ctx, event)},
              ~onPointerUp={event => handleCubiePointerUp(ctx, event)},
              ~onPointerCancel={event => handleCubiePointerCancel(ctx, event)},
            )
          )
        let cubeChildren = React.array(
          [ReactThreeFiber.primitive(~object=ctx.coreMesh, ~key="core"), ...cubies],
        )
        ReactThreeFiber.primitive(
          ~object=ctx.sceneRoot,
          ~children=ReactThreeFiber.primitive(~object=ctx.cubeGroup, ~children=cubeChildren),
        )
      }
    | None => React.null
    }
  }
}

@react.component
let make = (
  ~theme: themeName,
  ~animSpeed: float,
  ~onContextInit: cubeContext => unit,
  ~onMoveCompleted: move => unit,
) => {
  let (state, setState) = React.useState(() => None)

  <div
    className="plastic-well relative h-full min-h-[180px] w-full cursor-grab select-none overflow-hidden rounded-lg border bg-background touch-none active:cursor-grabbing lg:min-h-[420px]"
  >
    <ReactThreeFiber.canvas onCreated={created => setState(_ => Some(created))}>
      {switch state {
      | Some(r3fState) =>
        <CubeScene state={r3fState} theme animSpeed onContextInit onMoveCompleted />
      | None => React.null
      }}
    </ReactThreeFiber.canvas>
  </div>
}
