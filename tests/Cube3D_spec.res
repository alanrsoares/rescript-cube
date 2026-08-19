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

// The camera detent has to respect the hemisphere the drag ended in: settling
// always-upward would flip a view from below back over the equator.
describe("Cube3D detent tilt", () => {
  let up = Three.createVector3(0.0, 1.0, 0.0)
  let front = Three.createVector3(0.0, 0.0, 1.0)

  test("lifts toward up when the drag ends above the equator", () => {
    let above = Three.createVector3(0.0, 0.4, 1.0)->Three.normalizeVector3
    expect(Cube3D.detentTiltSign(above, up))->toBe(1.0)
  })

  test("drops below when the drag ends under the equator", () => {
    let below = Three.createVector3(0.0, -0.4, 1.0)->Three.normalizeVector3
    expect(Cube3D.detentTiltSign(below, up))->toBe(-1.0)
  })

  test("resolves a dead-level release upward", () => {
    expect(Cube3D.detentTiltSign(front, up))->toBe(1.0)
  })

  test("mirrors the resting direction across the equator", () => {
    let raised = Cube3D.detentDirection(front, up, 1.0)
    let lowered = Cube3D.detentDirection(front, up, -1.0)
    expect(Three.yVector3(raised) > 0.0)->toBe(true)
    expect(Three.yVector3(lowered))->toBe(-.Three.yVector3(raised))
    expect(Three.zVector3(lowered))->toBe(Three.zVector3(raised))
  })

  // Squaring `up` to the view is what keeps an upside-down view upside-down.
  test("offers only the axes square to the viewing direction as up", () => {
    let candidates = Cube3D.squareUpCandidates(front)->Array.map(Three.yVector3)
    expect(Array.length(candidates))->toBe(4)
    expect(candidates->Array.includes(1.0))->toBe(true)
    expect(candidates->Array.includes(-1.0))->toBe(true)
  })

  test("picks the axis nearest the target", () => {
    let drifted = Three.createVector3(0.1, 0.2, 0.97)->Three.normalizeVector3
    expect(Three.zVector3(Cube3D.nearestAxis(Cube3D.axisDirections, drifted)))->toBe(1.0)
  })
})
