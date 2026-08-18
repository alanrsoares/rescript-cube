// Intentionally small binding surface. Extend this only as the scene becomes
// declarative; keeping it narrow prevents the JavaScript API from leaking
// through the rest of the application.

open Three

type rootState
type pointerEvent
type pointerEventTarget

type rootStateObj = {
  scene: scene,
  camera: perspectiveCamera,
  gl: webGLRenderer,
  size: {width: float, height: float},
}

external rootStateObj: rootState => rootStateObj = "%identity"

type pointerEventObj = {
  nativeEvent: Dom.event,
  object: mesh,
  face: faceInfo,
  target: pointerEventTarget,
}

external pointerEventObj: pointerEvent => pointerEventObj = "%identity"
@send external setPointerCapture: (pointerEventTarget, int) => unit = "setPointerCapture"
@send external releasePointerCapture: (pointerEventTarget, int) => unit = "releasePointerCapture"

type primitiveProps<'object> = {
  object: 'object,
  key: option<string>,
  children: option<React.element>,
  onPointerDown: option<pointerEvent => unit>,
  onPointerMove: option<pointerEvent => unit>,
  onPointerUp: option<pointerEvent => unit>,
  onPointerCancel: option<pointerEvent => unit>,
}

@module("react")
external createElement: (string, primitiveProps<'object>) => React.element = "createElement"

let primitive = (
  ~object,
  ~key=?,
  ~children=?,
  ~onPointerDown=?,
  ~onPointerMove=?,
  ~onPointerUp=?,
  ~onPointerCancel=?,
) =>
  createElement(
    "primitive",
    {object, key, children, onPointerDown, onPointerMove, onPointerUp, onPointerCancel},
  )

type canvasProps = {
  children: React.element,
  onCreated?: rootState => unit,
}

@module("@react-three/fiber") external canvas: React.component<canvasProps> = "Canvas"

@module("@react-three/fiber") external useFrame: ((rootState, float) => unit) => unit = "useFrame"
