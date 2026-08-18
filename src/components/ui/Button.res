// src/components/ui/Button.res - shadcn Button primitive using @styled-cva/rescript

open StyledCva

type variant = [#default | #accent | #secondary | #outline | #ghost | #move | #prime | #slice]
type buttonSize = [#default | #sm | #lg | #icon | #xs]

type props = {
  ...styledProps,
  @as("$variant") variant?: variant,
  @as("$size") btnSize?: buttonSize,
}

let make: React.component<props> = Tw.buttonWithConfig(
  "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md font-medium transition-colors cursor-pointer select-none outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50 active:scale-[0.98] disabled:pointer-events-none disabled:opacity-50",
  {
    "variants": {
      "$variant": {
        "default": "bg-primary text-primary-foreground shadow-xs hover:bg-primary/90",
        "accent": "bg-warning text-background shadow-xs hover:bg-warning/90",
        "secondary": "bg-secondary text-secondary-foreground shadow-xs hover:bg-secondary/80",
        "outline": "border bg-transparent text-foreground shadow-xs hover:bg-accent hover:text-accent-foreground",
        "ghost": "text-muted-foreground hover:bg-accent hover:text-accent-foreground",
        "move": "min-w-[42px] border bg-secondary/60 font-mono text-foreground hover:bg-secondary active:bg-primary active:text-primary-foreground",
        "prime": "min-w-[42px] border bg-card font-mono text-primary hover:bg-secondary active:bg-primary active:text-primary-foreground",
        "slice": "min-w-[42px] border border-primary/30 bg-primary/10 font-mono text-primary hover:bg-primary/20",
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
