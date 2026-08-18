// src/components/ui/Badge.res - shadcn Badge primitive using @styled-cva/rescript

open StyledCva

type variant = [
  | #default
  | #secondary
  | #success
  | #warning
  | #info
  | #ghost
  | #active
  | #done
  | #pending
]

type props = {
  ...styledProps,
  @as("$variant") variant?: variant,
}

let make: React.component<props> = Tw.spanWithConfig(
  "inline-flex select-none items-center gap-1.5 rounded-md border px-2 py-0.5 font-mono text-xs font-medium transition-colors",
  {
    "variants": {
      "$variant": {
        "default": "border-primary/30 bg-primary/15 text-primary",
        "secondary": "bg-secondary text-secondary-foreground",
        "success": "border-success/30 bg-success/15 text-success",
        "warning": "animate-pulse border-warning/30 bg-warning/15 text-warning",
        "info": "border-ring/30 bg-ring/15 text-foreground",
        "ghost": "bg-background/60 text-muted-foreground",
        "active": "border-transparent bg-primary text-primary-foreground",
        "done": "border-transparent bg-muted text-muted-foreground line-through",
        "pending": "bg-card text-card-foreground",
      },
    },
    "defaultVariants": {"$variant": "default"},
  },
)
