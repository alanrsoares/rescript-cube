// Three.js ReScript Bindings

type scene
type camera
type perspectiveCamera
type webGLRenderer
type group
type mesh
type geometry
type material
type meshStandardMaterial
type meshBasicMaterial
type color
type vector3
type matrix4
type quaternion
type euler
type faceInfo
type trackballControls

external perspectiveToCamera: perspectiveCamera => camera = "%identity"

// Vector3
@module("three") @new external createVector3: (float, float, float) => vector3 = "Vector3"
@module("three") @new external createVector3Zero: unit => vector3 = "Vector3"
@send external setVector3: (vector3, float, float, float) => vector3 = "set"
@send external copyVector3: (vector3, vector3) => vector3 = "copy"
@send external cloneVector3: vector3 => vector3 = "clone"
@send external multiplyScalarVector3: (vector3, float) => vector3 = "multiplyScalar"
@send external applyQuaternionVector3: (vector3, quaternion) => vector3 = "applyQuaternion"
@send external crossVector3: (vector3, vector3) => vector3 = "cross"
@send external addScaledVector3: (vector3, vector3, float) => vector3 = "addScaledVector"
@send external setFromMatrixColumn: (vector3, matrix4, int) => vector3 = "setFromMatrixColumn"
@send external lengthVector3: vector3 => float = "length"
@send external normalizeVector3: vector3 => vector3 = "normalize"
@get external xVector3: vector3 => float = "x"
@get external yVector3: vector3 => float = "y"
@get external zVector3: vector3 => float = "z"

// Quaternion
@module("three") @new external createQuaternion: unit => quaternion = "Quaternion"
@send external setFromAxisAngle: (quaternion, vector3, float) => quaternion = "setFromAxisAngle"
@send external copyQuaternion: (quaternion, quaternion) => quaternion = "copy"

// Euler
@send external setEuler: (euler, float, float, float, string) => euler = "set"

// Scene
@send external removeScene: (scene, 'a) => unit = "remove"

// Camera
@get external cameraPosition: camera => vector3 = "position"
@get external cameraFov: perspectiveCamera => float = "fov"
@get external cameraAspect: perspectiveCamera => float = "aspect"
@send external lookAtCamera: (camera, float, float, float) => unit = "lookAt"

// Renderer
@get external domElementRenderer: webGLRenderer => Dom.element = "domElement"

// General Object3D getters / setters
@get external getPosition: 'a => vector3 = "position"
@get external getRotation: 'a => euler = "rotation"
@get external getQuaternion: 'a => quaternion = "quaternion"
@get external getMatrixWorld: 'a => matrix4 = "matrixWorld"
@send external add: ('a, 'b) => unit = "add"
@send external remove: ('a, 'b) => unit = "remove"
@send external attach: ('a, 'b) => unit = "attach"
@send external updateMatrixWorld: ('a, bool) => unit = "updateMatrixWorld"
@set external setVisible: ('a, bool) => unit = "visible"

// `position` / `rotation` / `quaternion` are read-only accessors on Object3D —
// they must be mutated in place, never reassigned.
let setPositionVec = (o, v) => copyVector3(getPosition(o), v)->ignore
let setQuaternionVec = (o, q) => copyQuaternion(getQuaternion(o), q)->ignore
let resetRotation = o => setEuler(getRotation(o), 0.0, 0.0, 0.0, "XYZ")->ignore

// Group
@module("three") @new external createGroup: unit => group = "Group"

// Geometry
type roundedBoxGeometry
@module("three/examples/jsm/geometries/RoundedBoxGeometry.js") @new
external createRoundedBoxGeometry: (float, float, float, int, float) => roundedBoxGeometry =
  "RoundedBoxGeometry"
external geometryFromRoundedBox: roundedBoxGeometry => geometry = "%identity"

// Material
type materialOptions = {
  color?: int,
  roughness?: float,
  metalness?: float,
  clearcoat?: float,
  clearcoatRoughness?: float,
  flatShading?: bool,
}

@module("three") @new
external createMeshStandardMaterial: materialOptions => meshStandardMaterial =
  "MeshStandardMaterial"
@module("three") @new
external createMeshBasicMaterial: materialOptions => meshBasicMaterial = "MeshBasicMaterial"
external materialFromStandard: meshStandardMaterial => material = "%identity"
external materialFromBasic: meshBasicMaterial => material = "%identity"

// Mesh
@module("three") @new external createMesh: (geometry, 'mat) => mesh = "Mesh"

// Lights
type ambientLight
type directionalLight
@module("three") @new external createAmbientLight: (int, float) => ambientLight = "AmbientLight"
@module("three") @new
external createDirectionalLight: (int, float) => directionalLight = "DirectionalLight"

// Face picking (R3F does the raycasting; we only read the hit face)
@get external getFaceNormal: faceInfo => vector3 = "normal"

// Trackball Controls
//
// Chosen over OrbitControls so the cube tumbles freely on both axes: orbiting
// pins an up-vector, which stops the camera dead at the poles while letting it
// spin without limit horizontally.
@module("three/examples/jsm/controls/TrackballControls.js") @new
external createTrackballControls: (camera, Dom.element) => trackballControls = "TrackballControls"
@send external updateTrackballControls: trackballControls => unit = "update"
// Caches the canvas rect, so it must be re-run whenever the canvas resizes.
@send external handleResizeTrackballControls: trackballControls => unit = "handleResize"
@send external disposeTrackballControls: trackballControls => unit = "dispose"
@set external setNoRotateTrackballControls: (trackballControls, bool) => unit = "noRotate"
@set external setNoPanTrackballControls: (trackballControls, bool) => unit = "noPan"
@set external setStaticMovingTrackballControls: (trackballControls, bool) => unit = "staticMoving"
@set
external setDynamicDampingFactorTrackballControls: (trackballControls, float) => unit =
  "dynamicDampingFactor"
@set external setRotateSpeedTrackballControls: (trackballControls, float) => unit = "rotateSpeed"
@set external setZoomSpeedTrackballControls: (trackballControls, float) => unit = "zoomSpeed"
@set external setMinDistanceTrackballControls: (trackballControls, float) => unit = "minDistance"
@set external setMaxDistanceTrackballControls: (trackballControls, float) => unit = "maxDistance"
// Defaults to ["KeyA", "KeyS", "KeyD"] on `window`, which would swallow the
// S and D move shortcuts. An empty list disables the modifiers entirely.
@set external setKeysTrackballControls: (trackballControls, array<string>) => unit = "keys"

// DOM helpers for pointer gestures
type cssStyle = {mutable touchAction: string}
@get external getStyle: Dom.element => cssStyle = "style"
@send external setPointerCapture: (Dom.element, int) => unit = "setPointerCapture"
@send external releasePointerCapture: (Dom.element, int) => unit = "releasePointerCapture"
