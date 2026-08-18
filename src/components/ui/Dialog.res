// src/components/ui/Dialog.res - shadcn Dialog primitive using @styled-cva/rescript

open StyledCva

module Overlay = {
  let make = Tw.div(
    "fixed inset-0 z-50 flex items-center justify-center bg-background/80 p-4 backdrop-blur-sm",
  )
}

module Content = {
  let make = Tw.div(
    "flex w-full max-w-md flex-col gap-5 rounded-xl border bg-popover p-6 text-popover-foreground shadow-lg",
  )
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
    "cursor-pointer border-0 bg-transparent p-0 text-lg font-medium text-muted-foreground transition-colors hover:text-foreground",
  )
}
