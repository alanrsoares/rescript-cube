// tests/Timer_spec.res - Tests for Timer time formatting

open Timer
open BunTest
open BunTest.Expect

describe("Timer Spec", () => {
  describe("Time formatting", () => {
    test(
      "formats sub-second time correctly",
      () => {
        expect(formatTime(450.0))->toBe("0.45")
      },
    )

    test(
      "formats seconds with two digits",
      () => {
        expect(formatTime(12340.0))->toBe("12.34")
      },
    )

    test(
      "formats minutes and seconds cleanly",
      () => {
        expect(formatTime(65430.0))->toBe("1:05.43")
      },
    )
  })
})
