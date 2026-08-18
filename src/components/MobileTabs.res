// src/components/MobileTabs.res - phone-only bottom bar. On lg every panel is
// visible at once, so this whole control disappears.

open StyledCva
open Utils

type tab = [#coach | #moves | #log]

let tabs = [
  (#coach, "Coach", Icon.graduationCap),
  (#moves, "Moves", Icon.gamepad),
  (#log, "Log", Icon.history),
]

module Bar = {
  let make = Tw.nav(
    "-mx-4 flex shrink-0 items-stretch gap-1 border-t bg-background px-2 pb-[env(safe-area-inset-bottom)] pt-1 lg:hidden",
  )
}

module Tab = {
  type props = {
    ...styledProps,
    @as("$active") active?: [#on | #off],
  }

  let make: React.component<props> = Tw.buttonWithConfig(
    "flex min-h-[48px] flex-1 cursor-pointer select-none flex-col items-center justify-center gap-0.5 rounded-md text-[11px] font-medium transition-colors",
    {
      "variants": {
        "$active": {
          "on": "bg-primary/10 text-primary",
          "off": "text-muted-foreground",
        },
      },
      "defaultVariants": {"$active": "off"},
    },
  )
}

// Tapping the open tab closes it, handing the whole screen back to the cube.
@react.component
let make = (~active: option<tab>, ~onSelect: option<tab> => unit) =>
  <Bar>
    {tabs
    ->Array.map(((t, label, icon)) => {
      let isActive = active == Some(t)
      <Tab
        key={label}
        active={isActive ? #on : #off}
        onClick={_ => onSelect(isActive ? None : Some(t))}
      >
        {Icon.render(icon, ~size=18)}
        {renderString(label)}
      </Tab>
    })
    ->renderArray}
  </Bar>
