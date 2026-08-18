// Three.js ReScript Bindings

type scene
type camera
type perspectiveCamera
type renderer
type webGLRenderer
type group
type mesh
type geometry
type boxGeometry
type material
type meshStandardMaterial
type meshBasicMaterial
type color
type vector3
type vector2
type matrix4
type quaternion
type euler
type raycaster
type intersection
type faceInfo
type object3D
type orbitControls

external object3D: 'a => object3D = "%identity"
external mesh: 'a => mesh = "%identity"
external group: 'a => group = "%identity"
external camera: perspectiveCamera => camera = "%identity"
external perspectiveToCamera: perspectiveCamera => camera = "%identity"
external renderer: webGLRenderer => renderer = "%identity"
external webGLToRenderer: webGLRenderer => renderer = "%identity"

// Vector3
@module("three") @new external createVector3: (float, float, float) => vector3 = "Vector3"
@module("three") @new external createVector3Zero: unit => vector3 = "Vector3"
@send external setVector3: (vector3, float, float, float) => vector3 = "set"
@send external copyVector3: (vector3, vector3) => vector3 = "copy"
@send external cloneVector3: vector3 => vector3 = "clone"
@send external addVector3: (vector3, vector3) => vector3 = "add"
@send external subVector3: (vector3, vector3) => vector3 = "sub"
@send external multiplyScalarVector3: (vector3, float) => vector3 = "multiplyScalar"
@send external applyMatrix4Vector3: (vector3, matrix4) => vector3 = "applyMatrix4"
@send external applyQuaternionVector3: (vector3, quaternion) => vector3 = "applyQuaternion"
@send external dotVector3: (vector3, vector3) => float = "dot"
@send external crossVector3: (vector3, vector3) => vector3 = "cross"
@send external addScaledVector3: (vector3, vector3, float) => vector3 = "addScaledVector"
@send external setFromMatrixColumn: (vector3, matrix4, int) => vector3 = "setFromMatrixColumn"
@send external lengthVector3: vector3 => float = "length"
@send external normalizeVector3: vector3 => vector3 = "normalize"
@get external xVector3: vector3 => float = "x"
@get external yVector3: vector3 => float = "y"
@get external zVector3: vector3 => float = "z"

// Vector2
@module("three") @new external createVector2: (float, float) => vector2 = "Vector2"
@send external setVector2: (vector2, float, float) => vector2 = "set"
@get external xVector2: vector2 => float = "x"
@get external yVector2: vector2 => float = "y"

// Color
@module("three") @new external createColor: string => color = "Color"
@module("three") @new external createColorHex: int => color = "Color"
@send external setHexColor: (color, int) => color = "setHex"
@send external setStyleColor: (color, string) => color = "setStyle"
@send external getHexColor: color => int = "getHex"

// Quaternion
@module("three") @new external createQuaternion: unit => quaternion = "Quaternion"
@send external setFromAxisAngle: (quaternion, vector3, float) => quaternion = "setFromAxisAngle"
@send external setFromEuler: (quaternion, euler) => quaternion = "setFromEuler"
@send
external multiplyQuaternions: (quaternion, quaternion, quaternion) => quaternion =
  "multiplyQuaternions"
@send external premultiplyQuaternion: (quaternion, quaternion) => quaternion = "premultiply"
@send external copyQuaternion: (quaternion, quaternion) => quaternion = "copy"

// Euler
@module("three") @new external createEuler: (float, float, float, string) => euler = "Euler"
@send external setEuler: (euler, float, float, float, string) => euler = "set"

// Matrix4
@module("three") @new external createMatrix4: unit => matrix4 = "Matrix4"
@send external identityMatrix4: matrix4 => matrix4 = "identity"
@send external makeRotationAxis: (matrix4, vector3, float) => matrix4 = "makeRotationAxis"
@send external multiplyMatrices: (matrix4, matrix4, matrix4) => matrix4 = "multiplyMatrices"

// Scene
@module("three") @new external createScene: unit => scene = "Scene"
@send external addScene: (scene, 'a) => unit = "add"
@send external removeScene: (scene, 'a) => unit = "remove"
@set external setSceneBackground: (scene, color) => unit = "background"

// Camera
@module("three") @new
external createPerspectiveCamera: (float, float, float, float) => perspectiveCamera =
  "PerspectiveCamera"
@get external cameraPosition: camera => vector3 = "position"
@get external cameraFov: perspectiveCamera => float = "fov"
@get external cameraAspect: perspectiveCamera => float = "aspect"
@send external updateProjectionMatrix: perspectiveCamera => unit = "updateProjectionMatrix"
@set external setAspect: (perspectiveCamera, float) => unit = "aspect"
@set external setFov: (perspectiveCamera, float) => unit = "fov"
@send external lookAtCamera: (camera, float, float, float) => unit = "lookAt"
@send external lookAtCameraVec: (camera, vector3) => unit = "lookAt"

// Renderer
type rendererOptions = {
  antialias?: bool,
  alpha?: bool,
  powerPreference?: string,
}

@module("three") @new
external createWebGLRenderer: rendererOptions => webGLRenderer = "WebGLRenderer"
@send external setSizeRenderer: (webGLRenderer, int, int) => unit = "setSize"
@send external setPixelRatioRenderer: (webGLRenderer, float) => unit = "setPixelRatio"
@send external render: (webGLRenderer, scene, camera) => unit = "render"
@get external domElementRenderer: webGLRenderer => Dom.element = "domElement"
@send external disposeRenderer: webGLRenderer => unit = "dispose"

// General Object3D getters / setters
@get external getPosition: 'a => vector3 = "position"
@get external getRotation: 'a => euler = "rotation"
@get external getQuaternion: 'a => quaternion = "quaternion"
@get external getMatrixWorld: 'a => matrix4 = "matrixWorld"
@get external getMatrix: 'a => matrix4 = "matrix"
@send external add: ('a, 'b) => unit = "add"
@send external remove: ('a, 'b) => unit = "remove"
@send external attach: ('a, 'b) => unit = "attach"
@send external updateMatrixWorld: ('a, bool) => unit = "updateMatrixWorld"
@send external updateMatrix: 'a => unit = "updateMatrix"
@set external setMatrixAutoUpdate: ('a, bool) => unit = "matrixAutoUpdate"
@set external setVisible: ('a, bool) => unit = "visible"
@get external getChildren: 'a => array<object3D> = "children"
@get external getUserData: 'a => 'b = "userData"

// `position` / `rotation` / `quaternion` are read-only accessors on Object3D —
// they must be mutated in place, never reassigned.
let setPositionVec = (o, v) => copyVector3(getPosition(o), v)->ignore
let setQuaternionVec = (o, q) => copyQuaternion(getQuaternion(o), q)->ignore
let resetRotation = o => setEuler(getRotation(o), 0.0, 0.0, 0.0, "XYZ")->ignore

// Group
@module("three") @new external createGroup: unit => group = "Group"

// Geometry
@module("three") @new
external createBoxGeometry: (float, float, float) => boxGeometry = "BoxGeometry"
external geometryFromBox: boxGeometry => geometry = "%identity"

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
@get external materialColor: material => color = "color"
@send external cloneMaterial: material => material = "clone"

// Mesh
@module("three") @new external createMesh: (geometry, 'mat) => mesh = "Mesh"

// Lights
type ambientLight
type directionalLight
type pointLight
@module("three") @new external createAmbientLight: (int, float) => ambientLight = "AmbientLight"
@module("three") @new
external createDirectionalLight: (int, float) => directionalLight = "DirectionalLight"
@module("three") @new external createPointLight: (int, float, float) => pointLight = "PointLight"

// Raycaster
@module("three") @new external createRaycaster: unit => raycaster = "Raycaster"
@send external setFromCameraRaycaster: (raycaster, vector2, camera) => unit = "setFromCamera"
@send
external intersectObjects: (raycaster, array<mesh>, bool) => array<intersection> =
  "intersectObjects"

@get external getIntersectionPoint: intersection => vector3 = "point"
@get external getIntersectionObject: intersection => mesh = "object"
@get external getIntersectionFaceIndex: intersection => int = "faceIndex"
@get external getIntersectionFace: intersection => faceInfo = "face"
@get external getFaceNormal: faceInfo => vector3 = "normal"

// Orbit Controls
@module("three/examples/jsm/controls/OrbitControls.js") @new
external createOrbitControls: (camera, Dom.element) => orbitControls = "OrbitControls"
@send external updateOrbitControls: orbitControls => unit = "update"
@set external setEnableRotateOrbitControls: (orbitControls, bool) => unit = "enableRotate"
@set external setEnableZoomOrbitControls: (orbitControls, bool) => unit = "enableZoom"
@set external setEnablePanOrbitControls: (orbitControls, bool) => unit = "enablePan"
@set external setEnableDampingOrbitControls: (orbitControls, bool) => unit = "enableDamping"
@set external setDampingFactorOrbitControls: (orbitControls, float) => unit = "dampingFactor"
@set external setMinDistanceOrbitControls: (orbitControls, float) => unit = "minDistance"
@set external setMaxDistanceOrbitControls: (orbitControls, float) => unit = "maxDistance"
@send external disposeOrbitControls: orbitControls => unit = "dispose"

// DOM helpers for pointer gestures
type cssStyle = {mutable touchAction: string}
@get external getStyle: Dom.element => cssStyle = "style"
@send external setPointerCapture: (Dom.element, int) => unit = "setPointerCapture"
@send external releasePointerCapture: (Dom.element, int) => unit = "releasePointerCapture"
