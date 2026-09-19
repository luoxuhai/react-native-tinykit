const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const path = require('node:path');
const { test } = require('node:test');
const vm = require('node:vm');
const ts = require('typescript');

// Exercise the public wrappers and feature guards without loading RN's runtime.
function loadOverlays(features = ['Toast', 'Alert', 'Confetti'], failure) {
  const calls = [];
  const native = { getEnabledFeatures: () => features };
  for (const name of [
    'showToast',
    'showAlert',
    'dismissAllAlerts',
    'startConfetti',
    'stopConfetti',
  ]) {
    native[name] = (...args) => {
      calls.push({ name, args });
      return failure ? Promise.reject(failure) : Promise.resolve();
    };
  }
  const cache = new Map();
  function load(filename) {
    if (cache.has(filename)) return cache.get(filename).exports;
    const module = { exports: {} };
    cache.set(filename, module);
    const { outputText } = ts.transpileModule(readFileSync(filename, 'utf8'), {
      compilerOptions: { module: ts.ModuleKind.CommonJS },
    });
    const execute = vm.runInThisContext(
      `(function(require, module, exports) { ${outputText}\n})`,
      { filename }
    );
    execute(
      (request) =>
        request === 'react-native'
          ? { TurboModuleRegistry: { getEnforcing: () => native } }
          : load(path.resolve(path.dirname(filename), `${request}.ts`)),
      module,
      module.exports
    );
    return module.exports;
  }
  return {
    ...load(path.resolve(__dirname, '../src/Toast/index.ts')),
    ...load(path.resolve(__dirname, '../src/Alert/index.ts')),
    ...load(path.resolve(__dirname, '../src/Confetti/index.ts')),
    calls,
  };
}

test('existing overlay calls keep their options and millisecond units', async () => {
  const { Toast, Alert, Confetti, dismissAll, calls } = loadOverlays();
  const toast = { title: 'Saved', icon: 'error', haptic: 'warning' };
  const alert = { message: 'Loading', icon: 'spinner', duration: 0 };
  await Toast.show(toast);
  await Alert.show(alert);
  await Confetti.start({ duration: 2500 });
  await Alert.dismissAll();
  await Confetti.stop();
  assert.equal(dismissAll, Alert.dismissAll);
  assert.deepEqual(calls, [
    { name: 'showToast', args: [toast] },
    { name: 'showAlert', args: [alert] },
    { name: 'startConfetti', args: [{ duration: 2500 }] },
    { name: 'dismissAllAlerts', args: [] },
    { name: 'stopConfetti', args: [] },
  ]);
});

test('omitted options reach native defaults', async () => {
  const { Toast, Alert, Confetti, calls } = loadOverlays();
  await Toast.show();
  await Alert.show();
  await Confetti.start();
  assert.deepEqual(
    calls.map((call) => call.args),
    [[{}], [{}], [{}]]
  );
});

test('disabled features reject every public method without native side effects', async () => {
  const { Toast, Alert, Confetti, calls } = loadOverlays([]);
  for (const [feature, invoke] of [
    ['Toast', () => Toast.show()],
    ['Alert', () => Alert.show()],
    ['Alert', () => Alert.dismissAll()],
    ['Confetti', () => Confetti.start()],
    ['Confetti', () => Confetti.stop()],
  ]) {
    await assert.rejects(
      invoke(),
      new RegExp(`${feature} feature is not installed`)
    );
  }
  assert.deepEqual(calls, []);
});

test('each overlay is usable independently of the other features', async () => {
  for (const feature of ['Toast', 'Alert', 'Confetti']) {
    const api = loadOverlays([feature]);
    await (feature === 'Confetti' ? api.Confetti.start() : api[feature].show());
    assert.equal(api.calls.length, 1);
  }
});

test('invalid durations reject before scheduling native timers', async () => {
  const { Alert, Confetti, calls } = loadOverlays();
  for (const duration of [NaN, Infinity, -Infinity]) {
    await assert.rejects(Alert.show({ duration }), /finite/);
    await assert.rejects(Confetti.start({ duration }), /finite/);
  }
  await assert.rejects(Confetti.start({ duration: -1 }), /non-negative/);
  assert.deepEqual(calls, []);
  await Alert.show({ duration: -1 });
  assert.equal(calls.length, 1);
});

test('native presentation failures propagate to the caller', async () => {
  const error = new Error('No presentation window');
  const { Toast, Alert, Confetti } = loadOverlays(undefined, error);
  for (const invoke of [
    () => Toast.show(),
    () => Alert.show(),
    () => Alert.dismissAll(),
    () => Confetti.start(),
    () => Confetti.stop(),
  ]) {
    await assert.rejects(invoke(), (actual) => actual === error);
  }
});
