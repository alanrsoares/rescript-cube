// src/components/ui/Icon.res - lucide-react icon bindings

type props = {
  size?: int,
  strokeWidth?: float,
  className?: string,
  @as("aria-hidden") ariaHidden?: bool,
}

type t = React.component<props>

@module("lucide-react") external box: t = "Box"
@module("lucide-react") external keyboard: t = "Keyboard"
@module("lucide-react") external shuffle: t = "Shuffle"
@module("lucide-react") external rotateCcw: t = "RotateCcw"
@module("lucide-react") external gamepad: t = "Gamepad2"
@module("lucide-react") external brain: t = "Brain"
@module("lucide-react") external target: t = "Target"
@module("lucide-react") external timer: t = "Timer"
@module("lucide-react") external eye: t = "Eye"
@module("lucide-react") external partyPopper: t = "PartyPopper"
@module("lucide-react") external trophy: t = "Trophy"
@module("lucide-react") external skipBack: t = "SkipBack"
@module("lucide-react") external skipForward: t = "SkipForward"
@module("lucide-react") external play: t = "Play"
@module("lucide-react") external pause: t = "Pause"
@module("lucide-react") external x: t = "X"
@module("lucide-react") external check: t = "Check"
@module("lucide-react") external snail: t = "Snail"
@module("lucide-react") external rocket: t = "Rocket"
@module("lucide-react") external zap: t = "Zap"
@module("lucide-react") external history: t = "History"
@module("lucide-react") external circle: t = "Circle"
@module("lucide-react") external circleCheck: t = "CircleCheck"
@module("lucide-react") external lightbulb: t = "Lightbulb"
@module("lucide-react") external graduationCap: t = "GraduationCap"
@module("lucide-react") external dumbbell: t = "Dumbbell"

// Renders a lucide glyph at the surrounding text's cadence.
let render = (icon: t, ~size=16) =>
  React.createElement(icon, {size, strokeWidth: 2.0, ariaHidden: true})
