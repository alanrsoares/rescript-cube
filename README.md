# ReScript 3D Rubik's Cube

An interactive Rubik's Cube trainer with a Three.js renderer, move controls,
keyboard and gesture input, a beginner-method coach, practice scrambles, and a
speedcubing timer.

**[Play it →](https://alanrsoares.github.io/rescript-cube/)**

## Development

Install dependencies and run the ReScript compiler and Vite in separate shells:

```sh
bun install
bun run res:dev
```

```sh
bun run dev
```

## Verification

```sh
bun run check
```

This compiles the ReScript sources, runs the Bun test suite, and creates a
production Vite build. Generated `.res.mjs` files and build artifacts are
intentionally ignored; `bun.lock` is committed for reproducible installs.

`bun install` also installs git hooks (via lefthook) that run formatting and
compilation on commit, lint the commit message, and run the full gate on push.

## Deployment

Every push to `main` builds and publishes to GitHub Pages. The site is served
from `/rescript-cube/`, which is why `vite.config.js` sets `base`.

## Contributing

See [AGENTS.md](AGENTS.md) for the architecture invariants and conventions.

## License

[MIT](LICENSE)
