// src/components/ui/Card.res - shadcn Card primitive using @styled-cva/rescript

open StyledCva

module Root = {
  let make = Tw.div(
    "plastic-panel flex flex-col gap-4 rounded-xl border bg-card p-5 text-card-foreground",
  )
}

module Header = {
  let make = Tw.div("flex items-center justify-between border-b pb-3")
}

module Title = {
  let make = Tw.h3("flex items-center gap-2 text-sm font-semibold tracking-tight")
}

module Description = {
  let make = Tw.p("text-xs text-muted-foreground")
}

module Content = {
  let make = Tw.div("flex flex-col gap-4")
}

module Footer = {
  let make = Tw.div("flex items-center justify-between border-t pt-3")
}
