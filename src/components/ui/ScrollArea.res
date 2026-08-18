// src/components/ui/ScrollArea.res - shadcn ScrollArea, native-overflow flavour:
// a scroll container with a slim, token-coloured bar instead of the OS default.

open StyledCva

// The bar styling on its own, for scroll regions that need their own box classes.
let bar = "[scrollbar-color:var(--color-border)_transparent] [scrollbar-width:thin] [&::-webkit-scrollbar-thumb]:rounded-full [&::-webkit-scrollbar-thumb]:bg-border [&::-webkit-scrollbar-track]:bg-transparent [&::-webkit-scrollbar]:w-1.5"

let make = Tw.div("min-h-0 flex-1 overflow-y-auto overscroll-contain " ++ bar)
