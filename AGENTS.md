# Engineering instructions

Instructions for any agent or contributor working in this repository. Read this
before editing. It documents invariants that the type system does not enforce.

## What this project is

An interactive 3D Rubik's Cube trainer. ReScript throughout, React 19 for the
UI, Three.js for the geometry, React Three Fiber (R3F) for the canvas.

## The one invariant that matters

**`src/cube/CubeState.res` is the source of truth. Three.js only renders.**

Moves flow in one direction:

```
user input → Cube3D queues a turn → animation lands
           → onMoveCompleted → CubeState.applyMove → React state
```

Never derive cube logic by reading mesh positions, and never mutate `CubeState`
from a renderer callback other than `onMoveCompleted`. Stage detection, solved
detection, and the coach all read the logical cube, so a shortcut here silently
breaks the curriculum.

`CubeState` uses Kociemba indexing in a **fixed frame** (white D, green F,
orange R). Whole-cube rotations never touch permutation or orientation — they
only move `orient`. If you are writing an algorithm, write it in the fixed frame
and let `CubeState.localize` relabel it.

## Layout

| Path | Role |
|---|---|
| `src/cube/` | Pure domain: state, method curriculum, practice setup. No Three.js, no React. |
| `src/Cube3D.res` | Imperative Three.js engine: materials, turn animation, gestures. |
| `src/components/RubikView.res` | The R3F boundary. Owns canvas, frame loop, lifecycle. |
| `src/Three.res`, `src/ReactThreeFiber.res` | Hand-written bindings. |
| `src/components/ui/` | Presentational primitives (`styled-cva` + Tailwind v4). |
| `tests/` | `bun:test` specs via the `BunTest.res` bindings. |

`src/cube/` must stay importable without a DOM. That is what keeps it testable.

## Rules

**Never edit generated output.** `*.res.mjs` and `lib/` are compiler artifacts
and are gitignored. Edit the `.res` source and recompile.

**Keep the bindings narrow.** `Three.res` and `ReactThreeFiber.res` describe
only what the app actually calls. Add a binding when a call site needs it now,
never speculatively — an unused binding is a false claim about what the app
touches. The reverse also holds: if you delete the last caller, delete the
binding.

**Don't grow `Cube3D.res`.** It is already the largest module in the repo. A new
subsystem gets its own module rather than another section here.

**`%identity` casts are a last resort.** The existing ones exist because
Three.js accessors are read-only or untyped, and each is commented. Do not add
one to route around a type error.

**New domain logic ships with a spec.** Anything in `src/cube/` is pure and
therefore cheap to test; there is no excuse for an untested branch.

## Verifying

```sh
bun run check   # format check, compile, tests, production build
```

Run it before reporting work as done. It is the same gate CI runs, so a green
local run means a green PR. `bun run res:dev` and `bun run dev` in separate
shells is the normal development loop.

Git hooks are installed by `bun install` (via `lefthook`): formatting and
compilation on commit, commit-message linting, and the full gate on push.

## Commits

Conventional Commits, **scope required**, subject ≤72 characters, imperative
mood. Enforced by `commitlint`.

```
fix(cube): resolve slice layer from the pointer hit point
refactor(three): drop bindings unused after the R3F migration
```

Use the body only when the "why" is not obvious from the diff. Do not add
agent or tool attribution, co-author trailers, or emoji.
