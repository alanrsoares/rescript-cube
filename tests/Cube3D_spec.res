// Regression coverage for forgiving slice selection near rounded cubie seams.

open BunTest
open BunTest.Expect

describe("Cube3D gesture layers", () => {
  test("keeps the lower edge of the middle slice in the center band", () => {
    expect(Cube3D.layerForCoordinate(-0.74))->toBe(0)
  })

  test("still selects deliberate outer slice drags", () => {
    expect(Cube3D.layerForCoordinate(-0.76))->toBe(-1)
    expect(Cube3D.layerForCoordinate(0.76))->toBe(1)
  })
})
