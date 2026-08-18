// 3D Rubik's Cube Engine in ReScript & Three.js

open Three
open CubeTypes

type dragTarget = {
  normal: vector3,
  point: vector3,
  screenX: float,
  screenY: float,
}

type activeGesture = {
  move: move,
  startX: float,
  startY: float,
  directionX: float,
  directionY: float,
}

type animationState = {
  mutable isAnimating: bool,
  mutable currentMove: option<move>,
  mutable targetAngle: float,
  mutable startAngle: float,
  mutable rotatedAngle: float,
  mutable elapsed: float,
  mutable duration: float,
  mutable axis: vector3,
  mutable pivotGroup: group,
  mutable activeCubies: array<mesh>,
  mutable shouldNotify: bool,
  mutable moveQueue: array<move>,
  mutable animSpeed: float, // radians per frame, default ~0.18
}

// An in-flight ease from wherever the drag left the camera to the nearest
// detent. Directions are unit vectors; `distance` preserves the user's zoom.
type cameraSnap = {
  startDirection: vector3,
  startUp: vector3,
  targetDirection: vector3,
  targetUp: vector3,
  distance: float,
  mutable elapsed: float,
}

type cubeContext = {
  scene: scene,
  sceneRoot: group,
  camera: perspectiveCamera,
  cubeGroup: group,
  coreMesh: mesh,
  cameraControls: trackballControls,
  cubies: array<mesh>,
  cubieHomes: array<(int, int, int)>,
  animState: animationState,
  mutable materials: array<material>,
  mutable onMoveCompleted: option<move => unit>,
  mutable dragTarget: option<dragTarget>,
  mutable activeGesture: option<activeGesture>,
  mutable fittedCanvasWidth: float,
  mutable fittedCanvasHeight: float,
  canvasElem: Dom.element,
  mutable cameraSnap: option<cameraSnap>,
  mutable onCanvasPointerDown: Dom.event => unit,
  mutable onWindowPointerRelease: Dom.event => unit,
}

type rectObj = {
  left: float,
  top: float,
  width: float,
  height: float,
}

type domElemObj = {
  getBoundingClientRect: unit => rectObj,
  addEventListener: (string, Dom.event => unit) => unit,
  removeEventListener: (string, Dom.event => unit) => unit,
}

type meshObj = {
  mutable material: array<material>,
}

type singleMaterialMeshObj = {
  mutable material: material,
}

type evtObj = {
  clientX: float,
  clientY: float,
  pointerId: int,
}

external castMeshToObj: mesh => meshObj = "%identity"
external castMeshToSingleMaterialObj: mesh => singleMaterialMeshObj = "%identity"
external castDomElem: Dom.element => domElemObj = "%identity"
external castEvtObj: Dom.event => evtObj = "%identity"

@val
external addWindowEventListener: (string, Dom.event => unit) => unit = "window.addEventListener"
@val
external removeWindowEventListener: (string, Dom.event => unit) => unit =
  "window.removeEventListener"

let pi = Math.Constants.pi
let turnPixels = 120.0
let commitTurnAt = 0.35
let cubeBoundingRadius = 2.55
let cameraFitPadding = 1.12
let closestZoomRatio = 0.72
let furthestZoomRatio = 2.4

let roundInt = (v: float): int => {
  Math.round(v)->Float.toInt
}

let clamp = (value: float, low: float, high: float): float => Math.max(low, Math.min(high, value))

// Fit the cube's bounding sphere to both camera axes. R3F updates the camera
// aspect before `useFrame`, so this remains correct as the canvas resizes.
let fitCameraToCanvas = (ctx: cubeContext, width: float, height: float) => {
  if (
    width > 0.0 &&
    height > 0.0 &&
    (width != ctx.fittedCanvasWidth || height != ctx.fittedCanvasHeight)
  ) {
    let camera = ctx.camera
    let halfVerticalFov = cameraFov(camera) *. pi /. 360.0
    let halfHorizontalFov = Math.atan(Math.tan(halfVerticalFov) *. cameraAspect(camera))
    let fitDistance =
      cubeBoundingRadius /.
      Math.sin(Math.min(halfVerticalFov, halfHorizontalFov)) *.
      cameraFitPadding
    setMinDistanceTrackballControls(ctx.cameraControls, fitDistance *. closestZoomRatio)
    setMaxDistanceTrackballControls(ctx.cameraControls, fitDistance *. furthestZoomRatio)
    // TrackballControls maps drags through a cached canvas rect, so a resize
    // must invalidate it or every rotation is scaled against stale dimensions.
    handleResizeTrackballControls(ctx.cameraControls)
    let direction = cameraPosition(perspectiveToCamera(camera))->cloneVector3->normalizeVector3
    setPositionVec(camera, direction->multiplyScalarVector3(fitDistance))
    lookAtCamera(perspectiveToCamera(camera), 0.0, 0.0, 0.0)
    ctx.fittedCanvasWidth = width
    ctx.fittedCanvasHeight = height
  }
}

let animationDuration = (ctx: cubeContext, startAngle: float, targetAngle: float): float =>
  Math.max(0.001, Math.abs(targetAngle -. startAngle) /. (ctx.animState.animSpeed *. 60.0))

let getMat = (mats: array<material>, idx: int): material => {
  switch mats[idx] {
  | Some(m) => m
  | None =>
    switch mats[0] {
    | Some(m) => m
    | None => createMeshBasicMaterial({})->materialFromBasic
    }
  }
}

// Create materials for a cubie based on color scheme
let createFaceMaterials = (theme: colorScheme): array<material> => {
  let mats = [
    createMeshStandardMaterial({color: theme.right, roughness: 0.18, metalness: 0.08}), // +X
    createMeshStandardMaterial({color: theme.left, roughness: 0.18, metalness: 0.08}), // -X
    createMeshStandardMaterial({color: theme.up, roughness: 0.18, metalness: 0.08}), // +Y
    createMeshStandardMaterial({color: theme.down, roughness: 0.18, metalness: 0.08}), // -Y
    createMeshStandardMaterial({color: theme.front, roughness: 0.18, metalness: 0.08}), // +Z
    createMeshStandardMaterial({color: theme.back, roughness: 0.18, metalness: 0.08}), // -Z
    createMeshStandardMaterial({color: theme.inner, roughness: 0.75, metalness: 0.15}), // Inner plastic
  ]
  mats->Array.map(m => materialFromStandard(m))
}

// Assign 6 materials to a cubie depending on its (x,y,z) position in 3x3 grid
let getCubieMaterials = (allMats: array<material>, x: int, y: int, z: int): array<material> => {
  [
    if x == 1 {
      getMat(allMats, 0)
    } else {
      getMat(allMats, 6)
    }, // Right
    if x == -1 {
      getMat(allMats, 1)
    } else {
      getMat(allMats, 6)
    }, // Left
    if y == 1 {
      getMat(allMats, 2)
    } else {
      getMat(allMats, 6)
    }, // Up
    if y == -1 {
      getMat(allMats, 3)
    } else {
      getMat(allMats, 6)
    }, // Down
    if z == 1 {
      getMat(allMats, 4)
    } else {
      getMat(allMats, 6)
    }, // Front
    if z == -1 {
      getMat(allMats, 5)
    } else {
      getMat(allMats, 6)
    }, // Back
  ]
}

// Update color materials for live theme switching
let updateThemeColors = (ctx: cubeContext, newTheme: themeName) => {
  let theme = getTheme(newTheme)
  let newMats = createFaceMaterials(theme)
  ctx.materials = newMats
  let core = castMeshToSingleMaterialObj(ctx.coreMesh)
  core.material = getMat(newMats, 6)

  ctx.cubies->Array.forEachWithIndex((mesh, i) => {
    let (cx, cy, cz) = ctx.cubieHomes->Array.getUnsafe(i)
    let mats = getCubieMaterials(newMats, cx, cy, cz)
    let mo = castMeshToObj(mesh)
    mo.material = mats
  })
}

// Select matching cubies for a move
let selectCubiesForMove = (cubies: array<mesh>, m: move): array<mesh> => {
  cubies->Array.filter(mesh => {
    let pos = getPosition(mesh)
    let cx = roundInt(xVector3(pos))
    let cy = roundInt(yVector3(pos))
    let cz = roundInt(zVector3(pos))

    switch m {
    | MoveU(_) => cy == 1
    | MoveD(_) => cy == -1
    | MoveL(_) => cx == -1
    | MoveR(_) => cx == 1
    | MoveF(_) => cz == 1
    | MoveB(_) => cz == -1
    | MoveM(_) => cx == 0
    | MoveE(_) => cy == 0
    | MoveS(_) => cz == 0
    | MoveX(_) | MoveY(_) | MoveZ(_) => true
    }
  })
}

// Get rotation axis and total angle for a move
let getMoveAxisAndAngle = (m: move): (vector3, float) => {
  let getAngleMultiplier = (dir: moveDir) => {
    switch dir {
    | Clockwise => 1.0
    | CounterClockwise => -1.0
    | Double => 2.0
    }
  }

  switch m {
  | MoveU(dir) => (createVector3(0.0, 1.0, 0.0), -1.0 *. pi /. 2.0 *. getAngleMultiplier(dir))
  | MoveD(dir) => (createVector3(0.0, 1.0, 0.0), 1.0 *. pi /. 2.0 *. getAngleMultiplier(dir))
  | MoveL(dir) => (createVector3(1.0, 0.0, 0.0), 1.0 *. pi /. 2.0 *. getAngleMultiplier(dir))
  | MoveR(dir) => (createVector3(1.0, 0.0, 0.0), -1.0 *. pi /. 2.0 *. getAngleMultiplier(dir))
  | MoveF(dir) => (createVector3(0.0, 0.0, 1.0), -1.0 *. pi /. 2.0 *. getAngleMultiplier(dir))
  | MoveB(dir) => (createVector3(0.0, 0.0, 1.0), 1.0 *. pi /. 2.0 *. getAngleMultiplier(dir))
  | MoveM(dir) => (createVector3(1.0, 0.0, 0.0), 1.0 *. pi /. 2.0 *. getAngleMultiplier(dir))
  | MoveE(dir) => (createVector3(0.0, 1.0, 0.0), 1.0 *. pi /. 2.0 *. getAngleMultiplier(dir))
  | MoveS(dir) => (createVector3(0.0, 0.0, 1.0), -1.0 *. pi /. 2.0 *. getAngleMultiplier(dir))
  | MoveX(dir) => (createVector3(1.0, 0.0, 0.0), -1.0 *. pi /. 2.0 *. getAngleMultiplier(dir))
  | MoveY(dir) => (createVector3(0.0, 1.0, 0.0), -1.0 *. pi /. 2.0 *. getAngleMultiplier(dir))
  | MoveZ(dir) => (createVector3(0.0, 0.0, 1.0), -1.0 *. pi /. 2.0 *. getAngleMultiplier(dir))
  }
}

// Queue a move for execution
let queueMove = (ctx: cubeContext, m: move) => {
  let _ = Array.push(ctx.animState.moveQueue, m)
}

// Queue multiple moves
let queueMoves = (ctx: cubeContext, moves: array<move>) => {
  moves->Array.forEach(m => queueMove(ctx, m))
}

// Start animating the next move in queue
let startNextMove = (ctx: cubeContext) => {
  if !ctx.animState.isAnimating && Array.length(ctx.animState.moveQueue) > 0 {
    let nextMove = Array.shift(ctx.animState.moveQueue)
    switch nextMove {
    | Some(m) =>
      let (axis, angle) = getMoveAxisAndAngle(m)
      let activeCubies = selectCubiesForMove(ctx.cubies, m)

      // Reset pivot group orientation
      let pivot = createGroup()
      resetRotation(pivot)
      setQuaternionVec(pivot, createQuaternion())
      add(ctx.sceneRoot, pivot)

      // Reparent cubies to pivot
      activeCubies->Array.forEach(cubieMesh => {
        attach(pivot, cubieMesh)
      })

      // The core is useful at rest, but its large flat face becomes a harsh
      // black slab through the temporary gaps of a turning layer.
      setVisible(ctx.coreMesh, false)

      ctx.animState.isAnimating = true
      ctx.animState.currentMove = Some(m)
      ctx.animState.targetAngle = angle
      ctx.animState.startAngle = 0.0
      ctx.animState.rotatedAngle = 0.0
      ctx.animState.elapsed = 0.0

      // `animSpeed` originated as radians/frame. Convert it once into a
      // duration so turns keep their familiar timing at 60 fps but remain
      // smooth on faster or slower displays.
      ctx.animState.duration = animationDuration(ctx, 0.0, angle)
      ctx.animState.axis = axis
      ctx.animState.pivotGroup = pivot
      ctx.animState.activeCubies = activeCubies
      ctx.animState.shouldNotify = true
    | None => ()
    }
  }
}

// Finish current move animation, reparent cubies, round positions
let finishCurrentMove = (ctx: cubeContext) => {
  switch ctx.animState.currentMove {
  | Some(m) =>
    // Set exact final rotation on pivot
    let finalQuat =
      createQuaternion()->setFromAxisAngle(ctx.animState.axis, ctx.animState.targetAngle)
    setQuaternionVec(ctx.animState.pivotGroup, finalQuat)
    updateMatrixWorld(ctx.animState.pivotGroup, true)

    // Reparent back to cubeGroup
    ctx.animState.activeCubies->Array.forEach(cubieMesh => {
      attach(ctx.cubeGroup, cubieMesh)

      // Snap positions and rotations to clean grid values to prevent floating point drift
      let pos = getPosition(cubieMesh)
      let roundedPos = createVector3(
        Math.round(xVector3(pos)),
        Math.round(yVector3(pos)),
        Math.round(zVector3(pos)),
      )
      setPositionVec(cubieMesh, roundedPos)
      updateMatrixWorld(ctx.animState.pivotGroup, true)
    })

    remove(ctx.sceneRoot, ctx.animState.pivotGroup)
    setVisible(ctx.coreMesh, true)

    ctx.animState.isAnimating = false
    ctx.animState.currentMove = None

    if ctx.animState.shouldNotify {
      switch ctx.onMoveCompleted {
      | Some(cb) => cb(m)
      | None => ()
      }
    }
  | None => ()
  }
}

let easeInOutCubic = (t: float): float =>
  t < 0.5 ? 4.0 *. t *. t *. t : 1.0 -. Math.pow(-2.0 *. t +. 2.0, ~exp=3.0) /. 2.0

// R3F supplies elapsed frame time, so animation speed is independent of the
// display refresh rate. Easing removes the abrupt start and stop of each turn.
let updateAnimation = (ctx: cubeContext, deltaSeconds: float) => {
  if ctx.animState.isAnimating {
    ctx.animState.elapsed = ctx.animState.elapsed +. deltaSeconds
    let progress = Math.min(1.0, ctx.animState.elapsed /. ctx.animState.duration)
    ctx.animState.rotatedAngle =
      ctx.animState.startAngle +.
      (ctx.animState.targetAngle -. ctx.animState.startAngle) *. easeInOutCubic(progress)
    let quat = createQuaternion()->setFromAxisAngle(ctx.animState.axis, ctx.animState.rotatedAngle)
    setQuaternionVec(ctx.animState.pivotGroup, quat)

    if progress >= 1.0 {
      finishCurrentMove(ctx)
    }
  } else {
    startNextMove(ctx)
  }
}

// Gesture → Move resolution
//
// A drag across a cube face should spin the slice under the finger in the
// direction of travel. For a point on a face with outward normal `n` dragged
// along world vector `d`, the rotation axis is `n × d` (then snapped to the
// nearest grid axis): rotating +90° about it moves the surface along `d`.

type gridAxis = AxisX | AxisY | AxisZ

// Dominant component of a vector: which grid axis, and its signed magnitude.
let dominantAxis = (v: vector3): (gridAxis, float) => {
  let (x, y, z) = (xVector3(v), yVector3(v), zVector3(v))
  let (ax, ay, az) = (Math.abs(x), Math.abs(y), Math.abs(z))
  if ax >= ay && ax >= az {
    (AxisX, x)
  } else if ay >= az {
    (AxisY, y)
  } else {
    (AxisZ, z)
  }
}

// The move equal to a +90° right-hand rotation about the positive `axis`,
// applied to the layer (-1 | 0 | 1) holding the grabbed cubie.
let moveForRotation = (axis: gridAxis, layer: int): move => {
  switch (axis, layer) {
  | (AxisX, 1) => MoveR(CounterClockwise)
  | (AxisX, -1) => MoveL(Clockwise)
  | (AxisX, _) => MoveM(Clockwise)
  | (AxisY, 1) => MoveU(CounterClockwise)
  | (AxisY, -1) => MoveD(Clockwise)
  | (AxisY, _) => MoveE(Clockwise)
  | (AxisZ, 1) => MoveF(CounterClockwise)
  | (AxisZ, -1) => MoveB(Clockwise)
  | (AxisZ, _) => MoveS(CounterClockwise)
  }
}

// Screen-space drag (px, y down) projected onto the camera's world basis.
let dragToWorld = (ctx: cubeContext, dx: float, dy: float): vector3 => {
  let cam = perspectiveToCamera(ctx.camera)
  updateMatrixWorld(cam, true)
  let m = getMatrixWorld(cam)
  let right = createVector3Zero()->setFromMatrixColumn(m, 0)
  let up = createVector3Zero()->setFromMatrixColumn(m, 1)
  createVector3(0.0, 0.0, 0.0)
  ->addScaledVector3(right, dx)
  ->addScaledVector3(up, -.dy)
}

// The center band is intentionally generous. Rounded cubies leave a visible
// gap at row boundaries, where a ray can nick the adjacent cubie and make a
// middle-slice gesture turn an outer layer.
let layerForCoordinate = coordinate => {
  if coordinate > 0.75 {
    1
  } else if coordinate < -0.75 {
    -1
  } else {
    0
  }
}

let layerAtPoint = (point: vector3, axis: gridAxis): int => {
  switch axis {
  | AxisX => layerForCoordinate(xVector3(point))
  | AxisY => layerForCoordinate(yVector3(point))
  | AxisZ => layerForCoordinate(zVector3(point))
  }
}

let resolveGesture = (ctx: cubeContext, dt: dragTarget, dx: float, dy: float): option<move> => {
  let rotAxis = cloneVector3(dt.normal)->crossVector3(dragToWorld(ctx, dx, dy))
  if lengthVector3(rotAxis) < 0.001 {
    // Dragged straight along the face normal — no slice implied.
    None
  } else {
    let (axis, signed) = dominantAxis(rotAxis)
    let m = moveForRotation(axis, layerAtPoint(dt.point, axis))
    Some(signed >= 0.0 ? m : invertMove(m))
  }
}

// R3F owns picking and pointer capture. The cube only owns the gesture state
// and turn simulation derived from those events.
let dragThresholdPx = 10.0

// Camera detents
//
// A free camera can be left at any angle, including ones where the cube reads
// as an unrecognisable sliver. On release it eases to a resting view that puts
// one face squarely in front of the user: the nearest face normal, with the
// up-vector on one of the four axes square to it.
let snapDuration = 0.28

// How far the camera is raised off that face normal. Dead-on reads as a flat 2D
// grid, so the view is lifted just enough to keep a sliver of the neighbouring
// face, and with it the sense of depth the coach's algorithms rely on.
let detentTiltDegrees = 17.0

let axisDirections = [
  createVector3(1.0, 0.0, 0.0),
  createVector3(-1.0, 0.0, 0.0),
  createVector3(0.0, 1.0, 0.0),
  createVector3(0.0, -1.0, 0.0),
  createVector3(0.0, 0.0, 1.0),
  createVector3(0.0, 0.0, -1.0),
]

// Nearest by dot product: for unit vectors the largest dot is the smallest angle.
let nearestAxis = (candidates: array<vector3>, target: vector3): vector3 =>
  candidates->Array.reduce(candidates->Array.getUnsafe(0), (best, candidate) =>
    dotVector3(candidate, target) > dotVector3(best, target) ? candidate : best
  )

// `up` has to be square to the viewing direction, so the four axes perpendicular
// to it are the only valid choices. Picking the nearest of those preserves an
// upside-down view rather than rolling it back upright.
let squareUpCandidates = (direction: vector3): array<vector3> =>
  axisDirections->Array.filter(axis => Math.abs(dotVector3(axis, direction)) < 0.5)

// The resting direction for a face: its normal, raised toward the chosen up.
let detentDirection = (faceNormal: vector3, up: vector3): vector3 => {
  let tilt = detentTiltDegrees *. pi /. 180.0
  cloneVector3(faceNormal)
  ->multiplyScalarVector3(Math.cos(tilt))
  ->addScaledVector3(up, Math.sin(tilt))
  ->normalizeVector3
}

let beginCameraSnap = (ctx: cubeContext) => {
  let cam = perspectiveToCamera(ctx.camera)
  let position = cameraPosition(cam)
  let distance = lengthVector3(position)
  if distance > 0.0001 {
    let direction = cloneVector3(position)->normalizeVector3
    let currentUp = cloneVector3(getUp(cam))
    let faceNormal = nearestAxis(axisDirections, direction)
    // Chosen from the current up rather than forced to world +Y, so a view that
    // tumbled over the top stays inverted instead of rolling back.
    let targetUp = nearestAxis(squareUpCandidates(faceNormal), currentUp)
    ctx.cameraSnap = Some({
      startDirection: direction,
      startUp: currentUp,
      targetDirection: detentDirection(faceNormal, targetUp),
      targetUp,
      distance,
      elapsed: 0.0,
    })
  }
}

// Runs instead of the trackball update, not alongside it: the controls carry a
// damping tail after release that would otherwise pull against the ease.
let updateCameraSnap = (ctx: cubeContext, deltaSeconds: float) =>
  switch ctx.cameraSnap {
  | None => ()
  | Some(snap) =>
    snap.elapsed = snap.elapsed +. deltaSeconds
    let progress = Math.min(1.0, snap.elapsed /. snapDuration)
    let eased = easeInOutCubic(progress)
    let cam = perspectiveToCamera(ctx.camera)
    let direction =
      cloneVector3(snap.startDirection)->lerpVector3(snap.targetDirection, eased)->normalizeVector3
    setPositionVec(cam, multiplyScalarVector3(direction, snap.distance))
    let _ =
      getUp(cam)
      ->copyVector3(snap.startUp)
      ->lerpVector3(snap.targetUp, eased)
      ->normalizeVector3
    lookAtCamera(cam, 0.0, 0.0, 0.0)
    if progress >= 1.0 {
      ctx.cameraSnap = None
    }
  }

let beginGesture = (
  ctx: cubeContext,
  m: move,
  startX: float,
  startY: float,
  dx: float,
  dy: float,
) => {
  let length = Math.sqrt(dx *. dx +. dy *. dy)
  let (axis, targetAngle) = getMoveAxisAndAngle(m)
  let pivot = createGroup()
  add(ctx.sceneRoot, pivot)
  let activeCubies = selectCubiesForMove(ctx.cubies, m)
  activeCubies->Array.forEach(cubieMesh => attach(pivot, cubieMesh))
  setVisible(ctx.coreMesh, false)

  ctx.animState.currentMove = Some(m)
  ctx.animState.axis = axis
  ctx.animState.targetAngle = targetAngle
  ctx.animState.startAngle = 0.0
  ctx.animState.rotatedAngle = 0.0
  ctx.animState.pivotGroup = pivot
  ctx.animState.activeCubies = activeCubies
  ctx.activeGesture = Some({
    move: m,
    startX,
    startY,
    directionX: dx /. length,
    directionY: dy /. length,
  })
}

let updateGesture = (ctx: cubeContext, gesture: activeGesture, x: float, y: float) => {
  let distance =
    (x -. gesture.startX) *. gesture.directionX +. (y -. gesture.startY) *. gesture.directionY
  let progress = clamp(distance /. turnPixels, 0.0, 1.0)
  ctx.animState.rotatedAngle = ctx.animState.targetAngle *. progress
  let quat = createQuaternion()->setFromAxisAngle(ctx.animState.axis, ctx.animState.rotatedAngle)
  setQuaternionVec(ctx.animState.pivotGroup, quat)
}

let settleGesture = (ctx: cubeContext, commit: bool) => {
  switch ctx.activeGesture {
  | Some(_) =>
    let target = commit ? ctx.animState.targetAngle : 0.0
    ctx.animState.startAngle = ctx.animState.rotatedAngle
    ctx.animState.targetAngle = target
    ctx.animState.elapsed = 0.0
    ctx.animState.duration = animationDuration(ctx, ctx.animState.startAngle, target)
    ctx.animState.shouldNotify = commit
    ctx.animState.isAnimating = true
    ctx.activeGesture = None
  | None => ()
  }
}

let endGesture = (ctx: cubeContext) => {
  ctx.dragTarget = None
  setNoRotateTrackballControls(ctx.cameraControls, false)
}

let handleCubiePointerDown = (ctx: cubeContext, e: ReactThreeFiber.pointerEvent) => {
  let event = ReactThreeFiber.pointerEventObj(e)
  let nativeEvent = castEvtObj(event.nativeEvent)
  if !ctx.animState.isAnimating && Array.length(ctx.animState.moveQueue) == 0 {
    let targetMesh = event.object
    ctx.dragTarget = Some({
      normal: cloneVector3(getFaceNormal(event.face))->applyQuaternionVector3(
        getQuaternion(targetMesh),
      ),
      point: event.point,
      screenX: nativeEvent.clientX,
      screenY: nativeEvent.clientY,
    })
    setNoRotateTrackballControls(ctx.cameraControls, true)
    ReactThreeFiber.setPointerCapture(event.target, nativeEvent.pointerId)
  } else {
    endGesture(ctx)
  }
}

let handleCubiePointerMove = (ctx: cubeContext, e: ReactThreeFiber.pointerEvent) => {
  let nativeEvent = ReactThreeFiber.pointerEventObj(e).nativeEvent->castEvtObj
  switch ctx.dragTarget {
  | None =>
    switch ctx.activeGesture {
    | Some(gesture) => updateGesture(ctx, gesture, nativeEvent.clientX, nativeEvent.clientY)
    | None => ()
    }
  | Some(dt) =>
    let dx = nativeEvent.clientX -. dt.screenX
    let dy = nativeEvent.clientY -. dt.screenY
    if Math.sqrt(dx *. dx +. dy *. dy) >= dragThresholdPx {
      switch resolveGesture(ctx, dt, dx, dy) {
      | Some(m) =>
        beginGesture(ctx, m, dt.screenX, dt.screenY, dx, dy)
        ctx.dragTarget = None
      | None => ()
      }
    }
  }
}

let handleCubiePointerUp = (ctx: cubeContext, e: ReactThreeFiber.pointerEvent) => {
  let event = ReactThreeFiber.pointerEventObj(e)
  let nativeEvent = castEvtObj(event.nativeEvent)
  ReactThreeFiber.releasePointerCapture(event.target, nativeEvent.pointerId)
  switch ctx.activeGesture {
  | Some(_) =>
    let progress = Math.abs(ctx.animState.rotatedAngle) /. Math.abs(ctx.animState.targetAngle)
    settleGesture(ctx, progress >= commitTurnAt)
  | None => ()
  }
  endGesture(ctx)
}

let handleCubiePointerCancel = (ctx: cubeContext, e: ReactThreeFiber.pointerEvent) => {
  let event = ReactThreeFiber.pointerEventObj(e)
  let nativeEvent = castEvtObj(event.nativeEvent)
  ReactThreeFiber.releasePointerCapture(event.target, nativeEvent.pointerId)
  settleGesture(ctx, false)
  endGesture(ctx)
}

// Create the cube inside R3F's scene. Canvas owns the renderer, camera sizing,
// and render lifecycle; this engine only owns cube objects and interactions.
let init = (
  ~scene: scene,
  ~camera: perspectiveCamera,
  ~renderer: webGLRenderer,
  initialTheme: themeName,
): cubeContext => {
  // Start on a detent, so the opening framing matches every position the camera
  // settles into afterwards. Only the direction matters: `fitCameraToCanvas`
  // sets the distance.
  let home = detentDirection(createVector3(0.0, 0.0, 1.0), createVector3(0.0, 1.0, 0.0))
  let _ = setVector3(
    cameraPosition(perspectiveToCamera(camera)),
    xVector3(home),
    yVector3(home),
    zVector3(home),
  )
  let canvasElem = domElementRenderer(renderer)

  // Without this, browsers claim touch drags for scroll/zoom and no move fires.
  getStyle(canvasElem).touchAction = "none"
  // Every object created by this engine lives below one root. This makes the
  // whole scene removable when React Strict Mode replays an effect.
  let sceneRoot = createGroup()

  // Lights
  let ambientLight = createAmbientLight(0xffffff, 0.75)
  add(sceneRoot, ambientLight)

  let dirLight1 = createDirectionalLight(0xffffff, 1.25)
  let _ = setVector3(getPosition(dirLight1), 10.0, 15.0, 10.0)
  add(sceneRoot, dirLight1)

  let dirLight2 = createDirectionalLight(0xffffff, 0.55)
  let _ = setVector3(getPosition(dirLight2), -10.0, -10.0, -10.0)
  add(sceneRoot, dirLight2)

  let dirLight3 = createDirectionalLight(0xffffff, 0.45)
  let _ = setVector3(getPosition(dirLight3), -8.0, 12.0, -8.0)
  add(sceneRoot, dirLight3)

  // Trackball controls attached to canvasElem. Unlike orbiting, these impose no
  // up-vector, so the cube tumbles freely on every axis instead of stalling at
  // the poles while spinning without limit horizontally.
  let controls = createTrackballControls(perspectiveToCamera(camera), canvasElem)
  // No inertia: the damping tail keeps applying a decaying rotation to both the
  // eye and the up-vector on every update, which would pull the camera straight
  // back off the detent it just settled onto. Releasing snaps instead, so the
  // drag can track the pointer exactly.
  setStaticMovingTrackballControls(controls, true)
  setRotateSpeedTrackballControls(controls, 2.4)
  setZoomSpeedTrackballControls(controls, 1.0)
  // The cube is the only subject and `fitCameraToCanvas` frames it around the
  // origin; panning would slide it off-centre and defeat that.
  setNoPanTrackballControls(controls, true)
  // Clear the KeyA/KeyS/KeyD modifiers: they are bound on `window` and would
  // swallow the S and D move shortcuts.
  setKeysTrackballControls(controls, [])
  lookAtCamera(perspectiveToCamera(camera), 0.0, 0.0, 0.0)

  // Group to hold all cubies and core
  let cubeGroup = createGroup()

  // Geometries and materials
  let theme = getTheme(initialTheme)
  let materials = createFaceMaterials(theme)

  // Inner dark plastic core
  let coreGeom = geometryFromRoundedBox(createRoundedBoxGeometry(2.82, 2.82, 2.82, 4, 0.1))
  let coreMat = getMat(materials, 6)
  let coreMesh = createMesh(coreGeom, coreMat)

  // Semi-rounded cubie geometry
  let cubieGeom = geometryFromRoundedBox(createRoundedBoxGeometry(0.94, 0.94, 0.94, 5, 0.08))

  let cubies = []
  let cubieHomes = []
  for x in -1 to 1 {
    for y in -1 to 1 {
      for z in -1 to 1 {
        let cubieMats = getCubieMaterials(materials, x, y, z)
        let mesh = createMesh(cubieGeom, cubieMats)
        let _ = setVector3(getPosition(mesh), Float.fromInt(x), Float.fromInt(y), Float.fromInt(z))
        let _ = Array.push(cubies, mesh)
        let _ = Array.push(cubieHomes, (x, y, z))
      }
    }
  }

  let animState = {
    isAnimating: false,
    currentMove: None,
    targetAngle: 0.0,
    startAngle: 0.0,
    rotatedAngle: 0.0,
    elapsed: 0.0,
    duration: 0.0,
    axis: createVector3(0.0, 1.0, 0.0),
    pivotGroup: createGroup(),
    activeCubies: [],
    shouldNotify: true,
    moveQueue: [],
    animSpeed: 0.18,
  }

  let ctx = {
    scene,
    sceneRoot,
    camera,
    cubeGroup,
    coreMesh,
    cameraControls: controls,
    cubies,
    cubieHomes,
    animState,
    materials,
    onMoveCompleted: None,
    dragTarget: None,
    activeGesture: None,
    fittedCanvasWidth: 0.0,
    fittedCanvasHeight: 0.0,
    canvasElem,
    cameraSnap: None,
    onCanvasPointerDown: _ => (),
    onWindowPointerRelease: _ => (),
  }

  // Assigned after construction rather than through a spread: a closure built
  // inside the record literal would capture the record being copied, not this
  // one, and its writes would land on a value nothing else can see.
  // Release is watched on `window` so a drag ending outside the canvas still
  // settles the camera.
  ctx.onCanvasPointerDown = _ => ctx.cameraSnap = None
  ctx.onWindowPointerRelease = _ => beginCameraSnap(ctx)
  castDomElem(canvasElem).addEventListener("pointerdown", ctx.onCanvasPointerDown)
  addWindowEventListener("pointerup", ctx.onWindowPointerRelease)
  addWindowEventListener("pointercancel", ctx.onWindowPointerRelease)

  ctx
}

// R3F owns the renderer, but this engine owns the Three objects and DOM
// listeners it creates. Keeping their teardown together prevents duplicate
// meshes and lights under React Strict Mode.
let dispose = (ctx: cubeContext) => {
  endGesture(ctx)
  ctx.animState.moveQueue = []
  if ctx.animState.isAnimating {
    remove(ctx.sceneRoot, ctx.animState.pivotGroup)
  }
  castDomElem(ctx.canvasElem).removeEventListener("pointerdown", ctx.onCanvasPointerDown)
  removeWindowEventListener("pointerup", ctx.onWindowPointerRelease)
  removeWindowEventListener("pointercancel", ctx.onWindowPointerRelease)
  disposeTrackballControls(ctx.cameraControls)
  removeScene(ctx.scene, ctx.sceneRoot)
}

// Reset cube to solved state
let resetCube = (ctx: cubeContext) => {
  ctx.animState.moveQueue = []
  if ctx.animState.isAnimating {
    ctx.animState.activeCubies->Array.forEach(cubieMesh => attach(ctx.cubeGroup, cubieMesh))
    remove(ctx.sceneRoot, ctx.animState.pivotGroup)
  }
  ctx.animState.isAnimating = false
  ctx.animState.currentMove = None
  ctx.animState.activeCubies = []
  ctx.activeGesture = None
  setVisible(ctx.coreMesh, true)

  let idx = ref(0)
  for x in -1 to 1 {
    for y in -1 to 1 {
      for z in -1 to 1 {
        switch ctx.cubies[idx.contents] {
        | Some(mesh) =>
          let _ = setVector3(
            getPosition(mesh),
            Float.fromInt(x),
            Float.fromInt(y),
            Float.fromInt(z),
          )
          setQuaternionVec(mesh, createQuaternion())
          updateMatrixWorld(mesh, true)
        | None => ()
        }
        idx := idx.contents + 1
      }
    }
  }
}
