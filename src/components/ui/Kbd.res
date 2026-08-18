// src/components/ui/Kbd.res - shadcn Kbd primitive using @styled-cva/rescript

open StyledCva

module Root = {
  let make = Tw.kbd(
    "select-none rounded-sm border bg-muted px-2 py-1 font-mono text-xs font-medium text-muted-foreground",
  )
}
