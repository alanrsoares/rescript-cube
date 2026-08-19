// src/components/ShortcutsModal.res - Keyboard Shortcuts Dialog using Dialog, Kbd, and Button primitives

open Utils

module ShortcutRow = {
  let make = StyledCva.Tw.div("flex justify-between items-center")
}

@react.component
let make = (~isOpen: bool, ~onClose: unit => unit) => {
  <Dialog.root isOpen onClose>
    <Dialog.Content>
      <Dialog.Header>
        <Dialog.Title>
          {Icon.render(Icon.keyboard, ~size=18)}
          {renderString("Keyboard Shortcuts")}
        </Dialog.Title>
        <Dialog.Close onClick={_ => onClose()}> {Icon.render(Icon.x, ~size=18)} </Dialog.Close>
      </Dialog.Header>

      <p className="text-xs text-muted-foreground">
        {renderString(
          "Letters follow the view: R turns whichever face is on your right, not a fixed one.",
        )}
      </p>

      <div className="flex flex-col gap-3 text-sm text-muted-foreground">
        <ShortcutRow>
          <Kbd.Root> {renderString("U / Shift+U")} </Kbd.Root>
          <span> {renderString("Turn the top face (CW / CCW)")} </span>
        </ShortcutRow>
        <ShortcutRow>
          <Kbd.Root> {renderString("D / Shift+D")} </Kbd.Root>
          <span> {renderString("Turn the bottom face")} </span>
        </ShortcutRow>
        <ShortcutRow>
          <Kbd.Root> {renderString("L / Shift+L")} </Kbd.Root>
          <span> {renderString("Turn the left face")} </span>
        </ShortcutRow>
        <ShortcutRow>
          <Kbd.Root> {renderString("R / Shift+R")} </Kbd.Root>
          <span> {renderString("Turn the right face")} </span>
        </ShortcutRow>
        <ShortcutRow>
          <Kbd.Root> {renderString("F / Shift+F")} </Kbd.Root>
          <span> {renderString("Turn the face toward you")} </span>
        </ShortcutRow>
        <ShortcutRow>
          <Kbd.Root> {renderString("B / Shift+B")} </Kbd.Root>
          <span> {renderString("Turn the face away from you")} </span>
        </ShortcutRow>
        <ShortcutRow>
          <Kbd.Root> {renderString("Cmd/Ctrl+Z")} </Kbd.Root>
          <span> {renderString("Undo the last move")} </span>
        </ShortcutRow>
        <ShortcutRow>
          <Kbd.Root> {renderString("Cmd/Ctrl+Shift+Z")} </Kbd.Root>
          <span> {renderString("Redo the next move")} </span>
        </ShortcutRow>
        <ShortcutRow>
          <Kbd.Root> {renderString("Drag a sticker")} </Kbd.Root>
          <span> {renderString("Turn a layer of the face you are looking at")} </span>
        </ShortcutRow>
        <ShortcutRow>
          <Kbd.Root> {renderString("Twist two fingers")} </Kbd.Root>
          <span> {renderString("Turn the face toward you")} </span>
        </ShortcutRow>
        <ShortcutRow>
          <Kbd.Root> {renderString("Twist off the cube")} </Kbd.Root>
          <span> {renderString("Roll the whole cube")} </span>
        </ShortcutRow>
        <ShortcutRow>
          <Kbd.Root> {renderString("Drag Background")} </Kbd.Root>
          <span> {renderString("Orbit 3D Camera view")} </span>
        </ShortcutRow>
      </div>

      <Button variant=#default onClick={_ => onClose()}>
        {Icon.render(Icon.check)}
        {renderString("Got it")}
      </Button>
    </Dialog.Content>
  </Dialog.root>
}
