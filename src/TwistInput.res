// src/TwistInput.res - two-finger twist over raw pointer events.
//
// Owns the two live pointers and the angle between them, and nothing else: what a
// committed twist means is the caller's decision. It lives outside Cube3D so the
// engine gains a callback instead of a second pointer state machine.
//
// Move and release are watched on `window`, so a finger that slides off the canvas
// mid-twist keeps driving it and a release outside still ends it.

type pointerEvt = {
  pointerId: int,
  clientX: float,
  clientY: float,
  shiftKey: bool,
  pointerType: string,
}
external castEvt: Dom.event => pointerEvt = "%identity"

type elemObj = {
  addEventListener: (string, Dom.event => unit) => unit,
  removeEventListener: (string, Dom.event => unit) => unit,
}
external castElem: Dom.element => elemObj = "%identity"

@val
external addWindowEventListener: (string, Dom.event => unit) => unit = "window.addEventListener"
@val
external removeWindowEventListener: (string, Dom.event => unit) => unit =
  "window.removeEventListener"

type live = {id: int, point: TwistGesture.point, virtualFor: option<int>}
let virtualGapPx = 48.0

type t = {
  element: Dom.element,
  mutable pointers: array<live>,
  mutable gesture: option<TwistGesture.t>,
  // The owner may decline when the cube is already animating.
  onBegin: unit => bool,
  onUpdate: TwistGesture.t => unit,
  onEnd: unit => unit,
  mutable onDown: Dom.event => unit,
  mutable onMove: Dom.event => unit,
  mutable onRelease: Dom.event => unit,
}

// A twist needs exactly two fingers. A third is ignored rather than tracked, so
// resting a palm cannot silently retarget the gesture.
let pair = (t: t): option<(live, live)> =>
  switch (t.pointers[0], t.pointers[1]) {
  | (Some(a), Some(b)) => Some((a, b))
  | _ => None
  }

let isActive = (t: t): bool => t.gesture->Option.isSome

let beginIfPaired = (t: t) =>
  switch (t.gesture, pair(t)) {
  | (None, Some((a, b))) =>
    if t.onBegin() {
      t.gesture = Some(TwistGesture.start(a.point, b.point))
    }
  | _ => ()
  }

let stop = (t: t) => {
  switch t.gesture {
  | Some(_) => t.onEnd()
  | None => ()
  }
  t.gesture = None
}

let handleDown = (t: t, e: Dom.event) => {
  let ev = castEvt(e)
  t.pointers = Array.concat(
    t.pointers->Array.filter(p => p.id != ev.pointerId && p.virtualFor != Some(ev.pointerId)),
    [{id: ev.pointerId, point: {x: ev.clientX, y: ev.clientY}, virtualFor: None}],
  )

  // Shift+drag is the desktop counterpart to moving a two-finger pair together.
  // The virtual point remains a fixed distance beside the mouse, so the shared
  // midpoint moves exactly as a real two-finger swipe would.
  if ev.pointerType == "mouse" && ev.shiftKey && Array.length(t.pointers) == 1 {
    t.pointers = Array.concat(
      t.pointers,
      [
        {
          id: -ev.pointerId,
          point: {x: ev.clientX +. virtualGapPx, y: ev.clientY},
          virtualFor: Some(ev.pointerId),
        },
      ],
    )
  }
  beginIfPaired(t)
}

let handleMove = (t: t, e: Dom.event) => {
  let ev = castEvt(e)

  // Releasing Shift ends the emulated two-point gesture before a one-finger
  // slice or trackball drag can take over again.
  if ev.pointerType == "mouse" && !ev.shiftKey {
    t.pointers = t.pointers->Array.filter(p => p.virtualFor != Some(ev.pointerId))
    if Array.length(t.pointers) < 2 {
      stop(t)
    }
  }
  t.pointers =
    t.pointers->Array.map(p =>
      if p.id == ev.pointerId {
        {...p, point: {x: ev.clientX, y: ev.clientY}}
      } else if p.virtualFor == Some(ev.pointerId) {
        {...p, point: {x: ev.clientX +. virtualGapPx, y: ev.clientY}}
      } else {
        p
      }
    )
  switch (t.gesture, pair(t)) {
  | (Some(g), Some((a, b))) =>
    let next = TwistGesture.update(g, a.point, b.point)
    t.gesture = Some(next)
    t.onUpdate(next)
  | _ => ()
  }
}

let handleRelease = (t: t, e: Dom.event) => {
  let ev = castEvt(e)
  t.pointers =
    t.pointers->Array.filter(p => p.id != ev.pointerId && p.virtualFor != Some(ev.pointerId))
  if Array.length(t.pointers) < 2 {
    stop(t)
  }
}

let attach = (
  element: Dom.element,
  ~onBegin: unit => bool,
  ~onUpdate: TwistGesture.t => unit,
  ~onEnd: unit => unit,
): t => {
  let t = {
    element,
    pointers: [],
    gesture: None,
    onBegin,
    onUpdate,
    onEnd,
    onDown: _ => (),
    onMove: _ => (),
    onRelease: _ => (),
  }

  // Assigned after construction rather than in the literal: a closure built inside
  // the record would capture the record being copied, not this one.
  t.onDown = e => handleDown(t, e)
  t.onMove = e => handleMove(t, e)
  t.onRelease = e => handleRelease(t, e)

  castElem(element).addEventListener("pointerdown", t.onDown)
  addWindowEventListener("pointermove", t.onMove)
  addWindowEventListener("pointerup", t.onRelease)
  addWindowEventListener("pointercancel", t.onRelease)
  t
}

let detach = (t: t) => {
  castElem(t.element).removeEventListener("pointerdown", t.onDown)
  removeWindowEventListener("pointermove", t.onMove)
  removeWindowEventListener("pointerup", t.onRelease)
  removeWindowEventListener("pointercancel", t.onRelease)
  t.pointers = []
  t.gesture = None
}
