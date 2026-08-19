// src/TwistInput.res - two-finger twist over raw pointer events.
//
// Owns the two live pointers and the angle between them, and nothing else: what a
// committed twist means is the caller's decision. It lives outside Cube3D so the
// engine gains a callback instead of a second pointer state machine.
//
// Move and release are watched on `window`, so a finger that slides off the canvas
// mid-twist keeps driving it and a release outside still ends it.

type pointerEvt = {pointerId: int, clientX: float, clientY: float}
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

type live = {id: int, point: TwistGesture.point}

type t = {
  element: Dom.element,
  mutable pointers: array<live>,
  mutable gesture: option<TwistGesture.t>,
  // One turn per twist. Without this the same gesture would keep committing on
  // every further degree of rotation.
  mutable committed: bool,
  onBegin: unit => unit,
  onCommit: TwistGesture.intent => unit,
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

let stop = (t: t) => {
  switch t.gesture {
  | Some(_) => t.onEnd()
  | None => ()
  }
  t.gesture = None
  t.committed = false
}

let handleDown = (t: t, e: Dom.event) => {
  let ev = castEvt(e)
  t.pointers = Array.concat(
    t.pointers->Array.filter(p => p.id != ev.pointerId),
    [{id: ev.pointerId, point: {x: ev.clientX, y: ev.clientY}}],
  )
  switch (t.gesture, pair(t)) {
  | (None, Some((a, b))) =>
    t.gesture = Some(TwistGesture.start(a.point, b.point))
    t.committed = false
    t.onBegin()
  | _ => ()
  }
}

let handleMove = (t: t, e: Dom.event) => {
  let ev = castEvt(e)
  t.pointers =
    t.pointers->Array.map(p =>
      p.id == ev.pointerId ? {...p, point: {x: ev.clientX, y: ev.clientY}} : p
    )
  switch (t.gesture, pair(t)) {
  | (Some(g), Some((a, b))) =>
    let next = TwistGesture.update(g, a.point, b.point)
    t.gesture = Some(next)
    if !t.committed {
      switch TwistGesture.intent(next, a.point, b.point) {
      | Some(intent) =>
        t.committed = true
        t.onCommit(intent)
      | None => ()
      }
    }
  | _ => ()
  }
}

let handleRelease = (t: t, e: Dom.event) => {
  let ev = castEvt(e)
  t.pointers = t.pointers->Array.filter(p => p.id != ev.pointerId)
  if Array.length(t.pointers) < 2 {
    stop(t)
  }
}

let attach = (
  element: Dom.element,
  ~onBegin: unit => unit,
  ~onCommit: TwistGesture.intent => unit,
  ~onEnd: unit => unit,
): t => {
  let t = {
    element,
    pointers: [],
    gesture: None,
    committed: false,
    onBegin,
    onCommit,
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
