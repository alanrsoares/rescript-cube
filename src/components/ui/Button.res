// src/components/ui/Button.res - shadcn Button primitive using @styled-cva/rescript
//
// Every button is a moulded keycap: lit top edge, sheen down the face, tight
// shadow underneath, and 1px of travel when pressed. The move grids read as tiers
// by luminance rather than by hue, since the cube owns all the colour: a plain
// turn sits highest, its prime sits lower, slices and whole-cube turns lowest.

open StyledCva

type variant = [#default | #secondary | #outline | #ghost | #move | #prime | #slice]
type buttonSize = [#default | #sm | #lg | #icon | #xs]

type props = {
  ...styledProps,
  @as("$variant") variant?: variant,
  @as("$size") btnSize?: buttonSize,
}

let make: React.component<props> = Tw.buttonWithConfig(
  "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md font-medium cursor-pointer select-none outline-none transition-[background-color,box-shadow,translate,color] duration-150 ease-plastic focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-45 disabled:bg-none disabled:shadow-none",
  {
    "variants": {
      "$variant": {
        "default": "bg-primary text-primary-foreground plastic hover:bg-primary/90 active:plastic-press",
        "secondary": "bg-secondary text-secondary-foreground plastic hover:bg-accent active:plastic-press",
        "outline": "border bg-card text-foreground plastic hover:bg-accent active:plastic-press",
        "ghost": "text-muted-foreground hover:bg-accent hover:text-accent-foreground active:translate-y-px",
        "move": "min-w-[42px] bg-secondary font-mono font-semibold text-foreground plastic hover:bg-accent active:plastic-press",
        "prime": "min-w-[42px] bg-secondary font-mono font-normal text-muted-foreground plastic hover:bg-accent hover:text-foreground active:plastic-press",
        "slice": "plastic-well min-w-[42px] border bg-background font-mono text-muted-foreground hover:text-foreground active:translate-y-px",
      },
      "$size": {
        "default": "h-9 px-4 py-2 text-sm",
        "sm": "h-8 rounded-md px-3 text-xs",
        "lg": "h-10 rounded-md px-6 text-base",
        "icon": "size-9 rounded-md p-0",
        "xs": "h-7 rounded-sm px-2.5 text-xs",
      },
    },
    "defaultVariants": {"$variant": "default", "$size": "default"},
  },
)
