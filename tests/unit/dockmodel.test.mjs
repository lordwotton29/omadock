// Regression tests for DockModel.js. The file is plain JS with no Qt
// globals, so it runs in a vm context; DOCKMODEL overrides the path.
import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

const file = process.env.DOCKMODEL || new URL("../../DockModel.js", import.meta.url)
const M = vm.createContext({})
vm.runInContext(readFileSync(file, "utf8"), M)
// Values from the vm realm have foreign prototypes; compare plain copies.
const plain = (v) => JSON.parse(JSON.stringify(v))

test("boundAppGroups ignores array-like objects", () => {
  assert.deepEqual(plain(M.boundAppGroups({ length: 1, 0: { id: "g" } })), [])
})

test("boundAppGroups keeps real arrays", () => {
  assert.equal(M.boundAppGroups([{ id: "g", apps: ["a"] }]).length, 1)
})

test("group apps must be a real array", () => {
  const g = M.boundAppGroups([{ id: "g", apps: { length: 1, 0: "a" } }])
  assert.deepEqual(plain(g[0].apps), [])
})

test("boundPinnedFolders ignores array-like objects", () => {
  assert.deepEqual(plain(M.boundPinnedFolders({ length: 1, 0: { path: "/tmp" } })), [])
})

test("parsePinned ignores array-like pinned lists", () => {
  assert.deepEqual(plain(M.parsePinned('{"pinned": {"length": 1, "0": "a"}}')), [])
  assert.deepEqual(plain(M.parsePinned('{"length": 1, "0": "a"}')), [])
})

test("parsePinned keeps real lists, deduped and without .desktop", () => {
  assert.deepEqual(plain(M.parsePinned('{"pinned": ["a.desktop", "b", "a"]}')), ["a", "b"])
  assert.deepEqual(plain(M.parsePinned('["x"]')), ["x"])
})

test("a huge claimed length returns at once", () => {
  const t0 = performance.now()
  M.boundAppGroups({ length: 1e7 })
  M.parsePinned('{"pinned": {"length": 10000000}}')
  assert.ok(performance.now() - t0 < 50, `took ${performance.now() - t0} ms`)
})
