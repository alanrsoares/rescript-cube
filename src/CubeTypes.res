// Rubik's Cube Types and Helpers

type moveDir = Clockwise | CounterClockwise | Double

type face = Up | Down | Left | Right | Front | Back

// Variant spreads (available in ReScript v12) keep the public move type flat
// while preserving the semantic families used throughout the cube model.
type faceMove =
  | MoveU(moveDir)
  | MoveD(moveDir)
  | MoveL(moveDir)
  | MoveR(moveDir)
  | MoveF(moveDir)
  | MoveB(moveDir)

type sliceMove =
  | MoveM(moveDir)
  | MoveE(moveDir)
  | MoveS(moveDir)

type rotationMove =
  | MoveX(moveDir)
  | MoveY(moveDir)
  | MoveZ(moveDir)

type move = | ...faceMove | ...sliceMove | ...rotationMove

type themeName = Classic | Neon | Pastel | Monochrome | Cyberpunk

let themeOptions = [
  (Classic, "Classic"),
  (Neon, "Neon"),
  (Cyberpunk, "Cyber"),
  (Pastel, "Pastel"),
  (Monochrome, "Mono"),
]

type colorScheme = {
  up: int,
  down: int,
  left: int,
  right: int,
  front: int,
  back: int,
  inner: int,
}

let moveDirToString = (dir: moveDir) => {
  switch dir {
  | Clockwise => ""
  | CounterClockwise => "'"
  | Double => "2"
  }
}

let moveDirQuarterTurns = (dir: moveDir): int =>
  switch dir {
  | Clockwise => 1
  | Double => 2
  | CounterClockwise => 3
  }

// `None` deliberately represents a full rotation: it cancels when adjacent
// moves are combined, rather than pretending it is another move direction.
let moveDirFromQuarterTurns = (turns: int): option<moveDir> =>
  switch mod(turns, 4) {
  | 0 => None
  | 1 => Some(Clockwise)
  | 2 => Some(Double)
  | _ => Some(CounterClockwise)
  }

let moveDirOf = (m: move): moveDir =>
  switch m {
  | MoveU(dir)
  | MoveD(dir)
  | MoveL(dir)
  | MoveR(dir)
  | MoveF(dir)
  | MoveB(dir)
  | MoveM(dir)
  | MoveE(dir)
  | MoveS(dir)
  | MoveX(dir)
  | MoveY(dir)
  | MoveZ(dir) => dir
  }

let withMoveDir = (m: move, dir: moveDir): move =>
  switch m {
  | MoveU(_) => MoveU(dir)
  | MoveD(_) => MoveD(dir)
  | MoveL(_) => MoveL(dir)
  | MoveR(_) => MoveR(dir)
  | MoveF(_) => MoveF(dir)
  | MoveB(_) => MoveB(dir)
  | MoveM(_) => MoveM(dir)
  | MoveE(_) => MoveE(dir)
  | MoveS(_) => MoveS(dir)
  | MoveX(_) => MoveX(dir)
  | MoveY(_) => MoveY(dir)
  | MoveZ(_) => MoveZ(dir)
  }

let moveSymbol = (m: move): string =>
  switch m {
  | MoveU(_) => "U"
  | MoveD(_) => "D"
  | MoveL(_) => "L"
  | MoveR(_) => "R"
  | MoveF(_) => "F"
  | MoveB(_) => "B"
  | MoveM(_) => "M"
  | MoveE(_) => "E"
  | MoveS(_) => "S"
  | MoveX(_) => "X"
  | MoveY(_) => "Y"
  | MoveZ(_) => "Z"
  }

let faceOfMove = (m: move): option<face> =>
  switch m {
  | MoveU(_) => Some(Up)
  | MoveD(_) => Some(Down)
  | MoveL(_) => Some(Left)
  | MoveR(_) => Some(Right)
  | MoveF(_) => Some(Front)
  | MoveB(_) => Some(Back)
  | _ => None
  }

let moveForFace = (face: face, dir: moveDir): move =>
  switch face {
  | Up => MoveU(dir)
  | Down => MoveD(dir)
  | Left => MoveL(dir)
  | Right => MoveR(dir)
  | Front => MoveF(dir)
  | Back => MoveB(dir)
  }

let moveToString = (m: move): string => moveSymbol(m) ++ moveDirToString(moveDirOf(m))

let invertDir = (dir: moveDir) => {
  switch dir {
  | Clockwise => CounterClockwise
  | CounterClockwise => Clockwise
  | Double => Double
  }
}

let invertMove = (m: move): move => withMoveDir(m, invertDir(moveDirOf(m)))

let moveDirFromSuffix = (suffix: string): option<moveDir> =>
  switch suffix {
  | "" => Some(Clockwise)
  | "'" | "i" => Some(CounterClockwise)
  | "2" => Some(Double)
  | _ => None
  }

let stringToMove = (str: string): option<move> => {
  let s = String.trim(str)
  if String.length(s) == 0 {
    None
  } else {
    let baseChar = String.substring(s, ~start=0, ~end=1)
    let suffix = String.substring(s, ~start=1, ~end=String.length(s))
    suffix
    ->moveDirFromSuffix
    ->Option.flatMap(dir =>
      switch String.toUpperCase(baseChar) {
      | "U" => Some(MoveU(dir))
      | "D" => Some(MoveD(dir))
      | "L" => Some(MoveL(dir))
      | "R" => Some(MoveR(dir))
      | "F" => Some(MoveF(dir))
      | "B" => Some(MoveB(dir))
      | "M" => Some(MoveM(dir))
      | "E" => Some(MoveE(dir))
      | "S" => Some(MoveS(dir))
      | "X" => Some(MoveX(dir))
      | "Y" => Some(MoveY(dir))
      | "Z" => Some(MoveZ(dir))
      | _ => None
      }
    )
  }
}

// Face colours. White sits on D and yellow on U: the beginner method is taught
// holding the cube white-side-down, so the standard algorithms apply verbatim.
let getTheme = (theme: themeName): colorScheme => {
  switch theme {
  | Classic => {
      up: 0xffd500, // Yellow
      down: 0xffffff, // White
      left: 0xc41e3a, // Red
      right: 0xff5800, // Orange
      front: 0x009e60, // Green
      back: 0x0051ba, // Blue
      inner: 0x18181c,
    }
  | Neon => {
      up: 0xccff00, // Lime
      down: 0x00ffff, // Cyan
      left: 0xff3300, // Bright Red
      right: 0xff007f, // Pink/Magenta
      front: 0x00ff66, // Electric Green
      back: 0x9933ff, // Purple
      inner: 0x0f0f1b,
    }
  | Pastel => {
      up: 0xfde4cf, // Peach
      down: 0xfbf8cc, // Cream
      left: 0xf1c0e8, // Soft Pink
      right: 0xffcfd2, // Soft Coral
      front: 0xb9fbc0, // Mint
      back: 0x90e0ef, // Soft Sky Blue
      inner: 0x222226,
    }
  | Monochrome => {
      up: 0xd6d8d9, // Light Slate
      down: 0xf8f9fa, // Pure White
      left: 0x6c757d, // Mid Gray
      right: 0xa8abaf, // Slate
      front: 0x495057, // Dark Slate
      back: 0x343a40, // Graphite
      inner: 0x121214,
    }
  | Cyberpunk => {
      up: 0x7209b7, // Deep Purple
      down: 0xf72585, // Neon Pink
      left: 0x4361ee, // Bright Royal
      right: 0x3a0ca3, // Blue Violet
      front: 0x4cc9f0, // Cyan
      back: 0xf8961e, // Sunset Orange
      inner: 0x0d0d12,
    }
  }
}
