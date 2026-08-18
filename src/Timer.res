// Timer module for Speedcubing & Personal Record tracking

type timerState =
  | Idle
  | Inspecting(int)
  | Running(float)
  | Solved(float)

let formatTime = (timeInMs: float): string => {
  let totalSeconds = timeInMs /. 1000.0
  let minutes = Math.floor(totalSeconds /. 60.0)->Float.toInt
  let seconds = Math.floor(totalSeconds % 60.0)->Float.toInt
  let hundredths = Math.floor(timeInMs % 1000.0 /. 10.0)->Float.toInt

  let minStr = if minutes > 0 {
    Int.toString(minutes) ++ ":"
  } else {
    ""
  }
  let secStr = if minutes > 0 && seconds < 10 {
    "0" ++ Int.toString(seconds)
  } else {
    Int.toString(seconds)
  }
  let msStr = if hundredths < 10 {
    "0" ++ Int.toString(hundredths)
  } else {
    Int.toString(hundredths)
  }

  `${minStr}${secStr}.${msStr}`
}

@val external localStorageGetItem: string => Nullable.t<string> = "window.localStorage.getItem"
@val external localStorageSetItem: (string, string) => unit = "window.localStorage.setItem"

let getBestTime = (): option<float> => {
  let val = localStorageGetItem("rescript_cube_best_time")
  switch Nullable.toOption(val) {
  | Some(str) => Float.fromString(str)
  | None => None
  }
}

let saveBestTime = (timeInMs: float): bool => {
  let currentBest = getBestTime()
  switch currentBest {
  | None =>
    localStorageSetItem("rescript_cube_best_time", Float.toString(timeInMs))
    true
  | Some(best) =>
    if timeInMs < best {
      localStorageSetItem("rescript_cube_best_time", Float.toString(timeInMs))
      true
    } else {
      false
    }
  }
}
