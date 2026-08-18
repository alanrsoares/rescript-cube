// BunTest.res - ReScript bindings for bun:test

@module("bun:test") external describe: (string, unit => unit) => unit = "describe"
@module("bun:test") external test: (string, unit => unit) => unit = "test"

module Expect = {
  type t
  @module("bun:test") external expect: 'a => t = "expect"
  @send external toEqual: (t, 'a) => unit = "toEqual"
  @send external toBe: (t, 'a) => unit = "toBe"
}
