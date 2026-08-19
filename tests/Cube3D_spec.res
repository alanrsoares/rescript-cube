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

// The camera snaps to a 3×3 grid around each face without flipping a view from
// below back over the equator.
describe("Cube3D camera detents", () => {
  let up = Three.createVector3(0.0, 1.0, 0.0)
  let right = Three.createVector3(1.0, 0.0, 0.0)
  let front = Three.createVector3(0.0, 0.0, 1.0)

  test("lifts toward up when the drag ends above the equator", () => {
    let above = Three.createVector3(0.0, 0.4, 1.0)->Three.normalizeVector3
    expect(Cube3D.detentOffset(above, up))->toBe(1.0)
  })

  test("drops below when the drag ends under the equator", () => {
    let below = Three.createVector3(0.0, -0.4, 1.0)->Three.normalizeVector3
    expect(Cube3D.detentOffset(below, up))->toBe(-1.0)
  })

  test("faces straight on when the drag ends near the equator", () => {
    expect(Cube3D.detentOffset(front, up))->toBe(0.0)
    let centered = Cube3D.detentDirection(front, up, right, 0.0, 0.0)
    expect(Three.yVector3(centered))->toBe(0.0)
    expect(Math.abs(Three.zVector3(centered) -. 1.0) < 0.0001)->toBe(true)
  })

  test("mirrors the resting direction across the equator", () => {
    let raised = Cube3D.detentDirection(front, up, right, 1.0, 0.0)
    let lowered = Cube3D.detentDirection(front, up, right, -1.0, 0.0)
    expect(Three.yVector3(raised) > 0.0)->toBe(true)
    expect(Three.yVector3(lowered))->toBe(-.Three.yVector3(raised))
    expect(Three.zVector3(lowered))->toBe(Three.zVector3(raised))
  })

  test("uses the same three positions horizontally", () => {
    let left = Three.createVector3(-0.4, 0.0, 1.0)->Three.normalizeVector3
    let rightward = Three.createVector3(0.4, 0.0, 1.0)->Three.normalizeVector3
    expect(Cube3D.detentOffset(left, right))->toBe(-1.0)
    expect(Cube3D.detentOffset(front, right))->toBe(0.0)
    expect(Cube3D.detentOffset(rightward, right))->toBe(1.0)
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
