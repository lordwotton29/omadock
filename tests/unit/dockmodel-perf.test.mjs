// Performance helpers in DockModel.js. DOCKMODEL overrides the file.
import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

const file = process.env.DOCKMODEL || new URL("../../DockModel.js", import.meta.url)
const M = vm.createContext({})
vm.runInContext(readFileSync(file, "utf8"), M)

const win = (title, ws) => ({ title, address: "0x1", appId: "foot", workspaceName: ws, isMinimized: false })
const model = (title, ws) => ({
  pinned: [{ id: "foot", appId: "foot", pinned: true, running: true, windows: 1, windowList: [win(title, ws)] }],
  running: [],
  grouped: [],
})

test("sameModel: equal content in fresh objects", () => {
  assert.equal(M.sameModel(model("a", "2"), model("a", "2")), true)
})

test("sameModel: a window title change is a change", () => {
  assert.equal(M.sameModel(model("a", "2"), model("b", "2")), false)
})

test("sameModel: a workspace move is a change", () => {
  assert.equal(M.sameModel(model("a", "2"), model("a", "3")), false)
})

test("sameModel: an extra running app is a change", () => {
  const b = model("a", "2")
  b.running = [{ id: "zen", appId: "zen", pinned: false, running: true, windows: 1, windowList: [] }]
  assert.equal(M.sameModel(model("a", "2"), b), false)
})

test("sameModel: missing or empty models", () => {
  assert.equal(M.sameModel(null, model("a", "2")), false)
  assert.equal(M.sameModel({ pinned: [], running: [] }, { pinned: [], running: [] }), true)
})
