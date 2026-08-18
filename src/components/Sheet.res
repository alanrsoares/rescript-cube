// src/components/Sheet.res - a phone panel with a drag-down-to-dismiss grab handle.
// From lg up it is a plain column child: no handle, no drag, always open.

open StyledCva

@send external setPointerCapture: (Dom.element, Dom.eventPointerId) => unit = "setPointerCapture"
external asElement: {..} => Dom.element = "%identity"

module Grip = {
  let make = Tw.div("mx-auto h-1.5 w-10 rounded-full bg-muted-foreground/40")
}

module Handle = {
  let make = Tw.div(
    "flex h-7 shrink-0 cursor-grab touch-none items-center justify-center active:cursor-grabbing lg:hidden",
  )
}

// Past this much downward travel the release dismisses instead of snapping back.
let dismissPx = 56.0

@react.component
let make = (~active: bool, ~onClose: unit => unit, ~children) => {
  let (dragY, setDragY) = React.useState(() => 0.0)
  let startY = React.useRef(0.0)
  let offset = React.useRef(0.0)
  let dragging = React.useRef(false)

  let onPointerDown = e => {
    startY.current = Float.fromInt(ReactEvent.Pointer.clientY(e))
    dragging.current = true
    offset.current = 0.0
    // Capture keeps the gesture alive if the finger slides off the grip; a browser
    // that refuses the id (or a synthetic event) simply falls back to bubbling.
    try asElement(ReactEvent.Pointer.currentTarget(e))->setPointerCapture(
      ReactEvent.Pointer.pointerId(e),
    ) catch {
    | _ => ()
    }
  }

  // Downward only - dragging up must not tear the panel off its resting edge.
  let onPointerMove = e =>
    if dragging.current {
      let dy = Math.max(0.0, Float.fromInt(ReactEvent.Pointer.clientY(e)) -. startY.current)
      offset.current = dy
      setDragY(_ => dy)
    }

  let onPointerUp = _ =>
    if dragging.current {
      dragging.current = false
      if offset.current >= dismissPx {
        onClose()
      }
      setDragY(_ => 0.0)
    }

  <div
    className={`${active
        ? "flex"
        : "hidden"} max-h-[45svh] min-h-0 shrink-0 flex-col overflow-hidden lg:flex lg:max-h-none lg:overflow-visible`}
    style={{
      transform: dragY == 0.0 ? "none" : `translateY(${Float.toString(dragY)}px)`,
      transition: dragging.current ? "none" : "transform 150ms ease-out",
    }}
  >
    <Handle onPointerDown onPointerMove onPointerUp onPointerCancel={onPointerUp}>
      <Grip />
    </Handle>
    // The panel scrolls its own body under its own header, so the sheet only has
    // to hand it the leftover height.
    children
  </div>
}
