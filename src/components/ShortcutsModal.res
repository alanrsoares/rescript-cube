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

      <div className="flex flex-col gap-3 text-sm text-muted-foreground">
        <ShortcutRow>
          <Kbd.Root> {renderString("U / Shift+U")} </Kbd.Root>
          <span> {renderString("Rotate Up face (CW / CCW)")} </span>
        </ShortcutRow>
        <ShortcutRow>
          <Kbd.Root> {renderString("D / Shift+D")} </Kbd.Root>
          <span> {renderString("Rotate Down face")} </span>
        </ShortcutRow>
        <ShortcutRow>
          <Kbd.Root> {renderString("L / Shift+L")} </Kbd.Root>
          <span> {renderString("Rotate Left face")} </span>
        </ShortcutRow>
        <ShortcutRow>
          <Kbd.Root> {renderString("R / Shift+R")} </Kbd.Root>
          <span> {renderString("Rotate Right face")} </span>
        </ShortcutRow>
        <ShortcutRow>
          <Kbd.Root> {renderString("F / Shift+F")} </Kbd.Root>
          <span> {renderString("Rotate Front face")} </span>
        </ShortcutRow>
        <ShortcutRow>
          <Kbd.Root> {renderString("B / Shift+B")} </Kbd.Root>
          <span> {renderString("Rotate Back face")} </span>
        </ShortcutRow>
        <ShortcutRow>
          <Kbd.Root> {renderString("Drag a sticker")} </Kbd.Root>
          <span> {renderString("Swipe a sticker to turn that slice")} </span>
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
