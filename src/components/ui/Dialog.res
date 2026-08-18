// src/components/ui/Dialog.res - native modal dialog with project styling

open StyledCva

type nativeDialog = {
  @as("open") open_: bool,
  showModal: unit => unit,
  close: unit => unit,
}

external nativeDialog: Dom.element => nativeDialog = "%identity"

module NativeDialog = {
  type props = {
    ...styledProps,
    onClose?: Dom.event => unit,
    onCancel?: Dom.event => unit,
  }

  let make = (Tw.dialog(
    "m-auto w-[calc(100%-2rem)] max-w-md border border-border bg-popover p-0 text-popover-foreground shadow-2xl outline-none backdrop:bg-background/80 backdrop:backdrop-blur-sm",
  ) :> React.component<props>)
}

@react.component
let root = (~isOpen: bool, ~onClose: unit => unit, ~children: React.element) => {
  let dialogRef = React.useRef(Nullable.null)

  React.useEffect(() => {
    switch dialogRef.current->Nullable.toOption {
    | Some(element) => {
        let dialog = nativeDialog(element)
        if isOpen && !dialog.open_ {
          dialog.showModal()
        } else if !isOpen && dialog.open_ {
          dialog.close()
        }
      }
    | None => ()
    }
    None
  }, [isOpen])

  <NativeDialog
    ref={ReactDOM.Ref.domRef(dialogRef)} onClose={_ => onClose()} onCancel={_ => onClose()}
  >
    {children}
  </NativeDialog>
}

module Content = {
  let make = Tw.div("flex w-full flex-col gap-5 p-6")
}

module Header = {
  let make = Tw.div("flex items-center justify-between border-b pb-3")
}

module Title = {
  let make = Tw.h3("flex items-center gap-2 text-lg font-semibold tracking-tight")
}

module Description = {
  let make = Tw.p("text-sm text-muted-foreground")
}

module Close = {
  let make = Tw.button(
    "cursor-pointer rounded-md border-0 bg-transparent p-1 text-muted-foreground transition-colors hover:bg-accent hover:text-foreground focus-visible:ring-[3px] focus-visible:ring-ring/50",
  )
}
