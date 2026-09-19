const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const vm = require('node:vm');
const ts = require('typescript');

function loadTranslation({
  enabled = true,
  supported = true,
  platform = 'ios',
  result = { status: 'dismissed' },
  error,
} = {}) {
  const calls = [];
  const native = {
    getEnabledFeatures: () => (enabled ? ['Translation'] : []),
    isTranslationSupported: () => supported,
    showTranslation: async (options) => {
      calls.push(options);
      if (error) throw error;
      return result;
    },
    dismissTranslation: async () => {
      calls.push('dismiss');
    },
  };
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
          ? {
              Platform: { OS: platform },
              TurboModuleRegistry: { getEnforcing: () => native },
              UIManager: {
                measureInWindow: (tag, callback) => {
                  assert.equal(tag, 42);
                  callback(10, 20, 200, 50);
                },
              },
            }
          : load(path.resolve(path.dirname(filename), `${request}.ts`)),
      module,
      module.exports
    );
    return module.exports;
  }
  return {
    ...load(path.resolve(__dirname, '../src/Translation/index.ts')),
    calls,
  };
}

test('migration aliases preserve Unicode, whitespace and replacement results', async () => {
  const result = { status: 'replaced', translatedText: '你好 👨‍👩‍👧‍👦' };
  const api = loadTranslation({ result });
  assert.equal(api.Translation.present, api.present);
  assert.equal(api.present, api.showTranslation);
  assert.equal(api.Translation.isSupported(), true);
  const text = '  Hello 👨‍👩‍👧‍👦 🏳️‍🌈 café\n世界  ';
  assert.deepEqual(
    await api.present({ text, allowsReplacement: true }),
    result
  );
  assert.deepEqual(api.calls, [
    { text, allowsReplacement: true, anchor: undefined, arrowEdge: undefined },
  ]);
  await api.Translation.dismiss();
  assert.equal(api.calls.at(-1), 'dismiss');
});

test('native refs and legacy tags become serializable window rectangles', async () => {
  const api = loadTranslation();
  const anchor = { x: 10, y: 20, width: 200, height: 50 };
  for (const targetViewNode of [
    42,
    { measureInWindow: (callback) => callback(10, 20, 200, 50) },
  ]) {
    await api.present({ text: 'Hello', targetViewNode, arrowEdge: 'bottom' });
    assert.deepEqual(api.calls.at(-1), {
      text: 'Hello',
      anchor,
      arrowEdge: 'bottom',
      allowsReplacement: undefined,
    });
    assert.equal('targetViewNode' in api.calls.at(-1), false);
  }
  await api.present({ text: 'Hello', anchor });
  assert.deepEqual(api.calls.at(-1).anchor, anchor);
});

test('invalid input rejects before presenting native UI', async () => {
  const api = loadTranslation();
  for (const options of [
    undefined,
    {},
    { text: '' },
    { text: ' \n ' },
    { text: 123 },
  ]) {
    await assert.rejects(api.present(options), {
      code: 'E_TRANSLATION_INVALID_TEXT',
    });
  }
  for (const options of [
    { anchor: { x: NaN, y: 0, width: 10, height: 10 } },
    { anchor: { x: 0, y: 0, width: 0, height: 10 } },
    { anchor: { x: 0, y: 0, width: 10, height: Infinity } },
    { anchor: null },
    { targetViewNode: -1 },
    { targetViewNode: {} },
    { targetViewNode: 42, anchor: { x: 0, y: 0, width: 10, height: 10 } },
    { targetViewNode: { measureInWindow: (callback) => callback(0, 0, 0, 0) } },
  ]) {
    await assert.rejects(api.present({ text: 'Hello', ...options }), {
      code: 'E_TRANSLATION_INVALID_ANCHOR',
    });
  }
  for (const options of [{ arrowEdge: 'left' }, { allowsReplacement: 1 }]) {
    await assert.rejects(api.present({ text: 'Hello', ...options }), {
      code: 'E_TRANSLATION_INVALID_OPTIONS',
    });
  }
  assert.deepEqual(api.calls, []);
});

test('measurement failures and late callbacks cannot open a panel', async () => {
  const api = loadTranslation();
  const error = new Error('Unmounted view');
  await assert.rejects(
    api.present({
      text: 'Hello',
      targetViewNode: {
        measureInWindow: () => {
          throw error;
        },
      },
    }),
    (actual) => actual === error
  );
  let measured;
  await assert.rejects(
    api.present({
      text: 'Hello',
      targetViewNode: {
        measureInWindow: (callback) => {
          measured = callback;
        },
      },
    }),
    { code: 'E_TRANSLATION_INVALID_ANCHOR' }
  );
  measured(0, 0, 20, 20);
  await Promise.resolve();
  assert.deepEqual(api.calls, []);
});

test('unsupported devices, disabled features and other platforms never present', async () => {
  for (const config of [
    { supported: false },
    { platform: 'android' },
    { platform: 'web' },
  ]) {
    const api = loadTranslation(config);
    assert.equal(api.isTranslationSupported(), false);
    await assert.rejects(api.present({ text: 'Hello' }), {
      code: 'E_TRANSLATION_UNAVAILABLE',
    });
    assert.deepEqual(api.calls, []);
  }
  const api = loadTranslation({ enabled: false });
  assert.equal(api.isTranslationSupported(), false);
  await assert.rejects(
    api.present({ text: 'Hello' }),
    /Translation feature is not installed/
  );
  await assert.rejects(
    api.dismissTranslation(),
    /Translation feature is not installed/
  );
  assert.deepEqual(api.calls, []);
});

test('dismissal results and native errors propagate without being swallowed', async () => {
  const api = loadTranslation();
  assert.deepEqual(await api.present({ text: 'Hello' }), {
    status: 'dismissed',
  });
  await api.dismissTranslation();
  await api.dismissTranslation();
  assert.deepEqual(api.calls.slice(1), ['dismiss', 'dismiss']);
  const error = Object.assign(
    new Error('A translation panel is already open.'),
    {
      code: 'E_TRANSLATION_ALREADY_PRESENTED',
    }
  );
  await assert.rejects(
    loadTranslation({ error }).present({ text: 'Hello' }),
    (actual) => actual === error
  );
});
