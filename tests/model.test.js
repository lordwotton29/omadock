const assert = require('node:assert/strict')
const { readFileSync } = require('node:fs')
const { join } = require('node:path')
const vm = require('node:vm')
const { test } = require('node:test')

const model = vm.createContext({ console, Quickshell: { iconPath: () => '' } })
vm.runInContext(readFileSync(join(__dirname, '../DockModel.js'), 'utf8'), model)
const plain = value => JSON.parse(JSON.stringify(value))
const library = {
  entryName: entry => entry.name,
  iconSource: name => ['ghostty', 'kitty', 'btop', 'firefox'].includes(name)
    ? `file:///icons/${name}.svg` : 'file:///icons/application-x-executable.svg',
}
const rows = [
  { id: 'com.mitchellh.ghostty', name: 'Ghostty', icon: 'ghostty' },
  { id: 'kitty', name: 'Kitty', icon: 'kitty' },
  { id: 'btop', name: 'btop', icon: 'btop' },
  { id: 'firefox', name: 'Firefox', icon: 'firefox' },
]
function entries(appId, host) {
  return model.buildEntries([], [{ appId, title: 'Window' }], rows, library,
    () => ({ address: 'abc', workspace: { name: '1' } }), '', {}, [], host)
}

test('custom TUI app-id displays its actual hosting terminal, not the TUI icon', () => {
  const result = entries('org.omarchy.btop', { '0xabc': 'com.mitchellh.ghostty' })
  assert.equal(result.running[0].icon, 'file:///icons/ghostty.svg')
  assert.equal(result.running[0].appId, 'org.omarchy.btop')
  assert.equal(result.running[0].name, 'btop')
})
test('host mapping uses the actual emulator rather than the default terminal', () => {
  assert.equal(entries('org.omarchy.btop', { '0xabc': 'kitty' }).running[0].icon,
    'file:///icons/kitty.svg')
})
test('GUI application icon resolution is unchanged', () => {
  assert.equal(entries('firefox', {}).running[0].icon, 'file:///icons/firefox.svg')
})
test('unknown apps have a non-blank generic fallback', () => {
  assert.equal(entries('unknown-app', {}).running[0].icon,
    'file:///icons/application-x-executable.svg')
})
test('persisted array-like objects cannot amplify bounded collection reads', () => {
  const hostile = { length: 1e9, 0: { id: 'g', apps: [] } }
  assert.deepEqual(plain(model.boundAppGroups(hostile)), [])
  assert.deepEqual(plain(model.boundPinnedFolders(hostile)), [])
  assert.deepEqual(plain(model.boundAppGroups([{ id: 'g', apps: { length: 1e9 } }])),
    [{ id: 'g', name: 'Group', icon: 'folder', apps: [], cols: 3, before: '' }])
})
test('UTF-8 byte ceiling counts surrogate pairs as four bytes', () => {
  assert.equal(model.readCapped('😀', 4), '😀')
  assert.equal(model.readCapped('😀', 3), '')
  assert.equal(model.readCapped('é', 2), 'é')
  assert.equal(model.readCapped('é', 1), '')
})
test('groups and folders retain their collection ceilings', () => {
  assert.equal(model.boundAppGroups(Array.from({ length: 100 }, (_, i) => ({ id: `g${i}` }))).length, 32)
  assert.equal(model.boundPinnedFolders(Array.from({ length: 100 }, () => ({ path: '/tmp' }))).length, 12)
})
test('presets include classic/long divider geometry and reject nonscalar look values', () => {
  const look = plain(model.pickLook({ dividerGeometry: 'long', hoverEffect: 'glow', bgColor: {}, iconSize: Infinity }))
  assert.equal(look.dividerGeometry, 'long')
  assert.equal(look.hoverEffect, 'glow')
  assert.equal(look.bgColor, undefined)
  assert.equal(look.iconSize, 0)
  assert.deepEqual(plain(model.boundPresets({ length: 1e9 })), [])
})
test('ungroup retains application order without duplicating existing pins', () => {
  const row = [{ kind: 'group', id: 'g', group: { apps: ['kitty', 'firefox'] } },
    { kind: 'app', appId: 'firefox' }]
  assert.deepEqual(plain(model.ungroupRow(row, 'g')), [
    { kind: 'app', appId: 'kitty' }, { kind: 'app', appId: 'firefox' },
  ])
})
