const assert = require('node:assert/strict');
const { existsSync, readFileSync } = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const vm = require('node:vm');
const ts = require('typescript');

const root = path.resolve(__dirname, '..');
const entries = {
  StoreProduct: './store-product',
  StoreOverlay: './store-overlay',
};
const methods = {
  StoreProduct: ['showStoreProduct', 'dismissStoreProduct'],
  StoreOverlay: ['showStoreOverlay', 'dismissStoreOverlay'],
};

// Load the declared package subpaths without starting React Native or native UI.
function loadStoreKit({
  features = Object.keys(entries),
  imports = Object.keys(entries),
  implementations = {},
} = {}) {
  const calls = [];
  const loadedSources = [];
  const native = { getEnabledFeatures: () => features };
  for (const name of Object.values(methods).flat()) {
    native[name] = (...args) => {
      calls.push({ name, args });
      const implementation = implementations[name];
      return implementation ? implementation(...args) : Promise.resolve();
    };
  }
  const cache = new Map();
  function resolveSource(filename) {
    for (const candidate of [
      filename,
      `${filename}.ts`,
      `${filename}.tsx`,
      path.join(filename, 'index.ts'),
      path.join(filename, 'index.tsx'),
    ]) {
      if (existsSync(candidate) && /\.tsx?$/.test(candidate)) return candidate;
    }
    throw new Error(`Cannot resolve test source: ${filename}`);
  }
  function load(filename) {
    filename = resolveSource(filename);
    if (cache.has(filename)) return cache.get(filename).exports;
    const module = { exports: {} };
    cache.set(filename, module);
    loadedSources.push(path.relative(root, filename));
    const { outputText } = ts.transpileModule(readFileSync(filename, 'utf8'), {
      compilerOptions: { module: ts.ModuleKind.CommonJS },
    });
    const execute = vm.runInThisContext(
      `(function(require, module, exports) { ${outputText}\n})`,
      { filename }
    );
    execute(
      (request) => {
        if (request === 'react-native') {
          return {
            Platform: { OS: 'ios' },
            TurboModuleRegistry: {
              getEnforcing: (name) => {
                assert.equal(name, 'Tinykit');
                return native;
              },
            },
          };
        }
        assert.ok(request.startsWith('.'), `Unexpected dependency: ${request}`);
        return load(path.resolve(path.dirname(filename), request));
      },
      module,
      module.exports
    );
    return module.exports;
  }
  const manifest = JSON.parse(readFileSync(path.join(root, 'package.json')));
  const api = {};
  for (const feature of imports) {
    const entry = manifest.exports[entries[feature]];
    const source = entry && entry.source;
    assert.equal(
      typeof source,
      'string',
      `${entries[feature]} needs a source export`
    );
    Object.assign(api, load(path.resolve(root, source)));
  }
  return { ...api, calls, loadedSources };
}

function deferred() {
  let resolve;
  let reject;
  const promise = new Promise((resolvePromise, rejectPromise) => {
    resolve = resolvePromise;
    reject = rejectPromise;
  });
  return { promise, resolve, reject };
}

test('StoreKit subpaths work independently with only their own feature enabled', async () => {
  for (const feature of Object.keys(entries)) {
    const api = loadStoreKit({ features: [feature], imports: [feature] });
    const [show, dismiss] = methods[feature];
    assert.equal(api[feature].present, api[show]);
    assert.equal(api[feature].dismiss, api[dismiss]);
    await api[show]({ appId: '123456789' });
    await api[dismiss]();
    assert.deepEqual(
      api.calls.map(({ name }) => name),
      [show, dismiss]
    );
    const other = feature === 'StoreProduct' ? 'StoreOverlay' : 'StoreProduct';
    assert.equal(api[methods[other][0]], undefined);
    assert.equal(
      api.loadedSources.some((source) => source.startsWith(`src/${other}/`)),
      false
    );
  }
});

test('product IDs and attribution tokens reach native without losing precision or whitespace', async () => {
  const api = loadStoreKit();
  const options = {
    appId: '9007199254740993',
    affiliateToken: ' affiliate ',
    campaignToken: '中文 campaign 🚀',
    providerToken: '000123',
  };
  await api.showStoreProduct({
    ...options,
    ignored: 'not a StoreKit parameter',
  });
  assert.deepEqual(api.calls, [{ name: 'showStoreProduct', args: [options] }]);
  await api.showStoreProduct({ appId: '000123' });
  assert.equal(api.calls.at(-1).args[0].appId, '000123');
});

test('overlay options preserve explicit choices and apply defaults without changing the caller object', async () => {
  const api = loadStoreKit();
  const minimal = { appId: '123456789' };
  await api.showStoreOverlay(minimal);
  assert.deepEqual(minimal, { appId: '123456789' });
  assert.equal(api.calls[0].args[0].appId, minimal.appId);
  assert.equal(api.calls[0].args[0].position, 'bottom');
  assert.equal(api.calls[0].args[0].userDismissible, true);

  const options = {
    appId: '000123',
    position: 'bottomRaised',
    userDismissible: false,
    campaignToken: ' campaign ',
    providerToken: '供应商',
  };
  await api.showStoreOverlay({
    ...options,
    ignored: 'not a StoreKit parameter',
  });
  assert.deepEqual(api.calls.at(-1), {
    name: 'showStoreOverlay',
    args: [options],
  });
});

test('malformed objects and app IDs reject before calling native StoreKit', async () => {
  const api = loadStoreKit();
  const invalidOptions = [undefined, null, [], '123', 123, false, {}, () => {}];
  const invalidIds = [
    undefined,
    null,
    123,
    '',
    '0',
    '000',
    '-1',
    '+1',
    '1.5',
    '1e3',
    'id123',
    ' 123',
    '123 ',
    '123\n',
    '123\r\n',
    '１２３',
    '١٢٣',
    '18446744073709551616',
    '00018446744073709551616',
    '0'.repeat(1000) + '18446744073709551616',
    '999999999999999999999',
    {},
  ];
  for (const [show, code] of [
    ['showStoreProduct', 'E_STORE_PRODUCT_INVALID_OPTIONS'],
    ['showStoreOverlay', 'E_STORE_OVERLAY_INVALID_OPTIONS'],
  ]) {
    for (const options of invalidOptions) {
      await assert.rejects(api[show](options), { code });
    }
    for (const appId of invalidIds) {
      await assert.rejects(api[show]({ appId }), { code });
    }
  }
  assert.deepEqual(api.calls, []);
});

test('the maximum unsigned 64-bit ID is accepted without rounding or removing leading zeroes', async () => {
  const api = loadStoreKit();
  for (const show of ['showStoreProduct', 'showStoreOverlay']) {
    for (const appId of [
      '18446744073709551615',
      '00018446744073709551615',
      '0'.repeat(1000) + '18446744073709551615',
    ]) {
      await api[show]({ appId });
      assert.equal(api.calls.at(-1).args[0].appId, appId);
    }
  }
});

test('invalid attribution and overlay configuration reject before presentation', async () => {
  const api = loadStoreKit();
  for (const [show, code, tokens] of [
    [
      'showStoreProduct',
      'E_STORE_PRODUCT_INVALID_OPTIONS',
      ['affiliateToken', 'campaignToken', 'providerToken'],
    ],
    [
      'showStoreOverlay',
      'E_STORE_OVERLAY_INVALID_OPTIONS',
      ['campaignToken', 'providerToken'],
    ],
  ]) {
    for (const token of tokens) {
      for (const value of [null, '', ' \n ', 123, false, [], {}]) {
        await assert.rejects(api[show]({ appId: '123', [token]: value }), {
          code,
        });
      }
    }
  }
  for (const position of [null, '', 'top', 'bottom-raised', 0, false]) {
    await assert.rejects(api.showStoreOverlay({ appId: '123', position }), {
      code: 'E_STORE_OVERLAY_INVALID_OPTIONS',
    });
  }
  for (const userDismissible of [null, 0, 1, 'true', 'false']) {
    await assert.rejects(
      api.showStoreOverlay({ appId: '123', userDismissible }),
      { code: 'E_STORE_OVERLAY_INVALID_OPTIONS' }
    );
  }
  assert.deepEqual(api.calls, []);
});

test('disabled StoreKit features reject shows and dismissals without native calls', async () => {
  for (const feature of Object.keys(entries)) {
    const api = loadStoreKit({ features: [] });
    const [show, dismiss] = methods[feature];
    const message = new RegExp(`${feature} feature is not installed`);
    await assert.rejects(api[show]({ appId: '123' }), message);
    await assert.rejects(api[dismiss](), message);
    assert.deepEqual(api.calls, []);
  }
});

test('show and dismiss promises remain pending until native completion', async () => {
  for (const name of Object.values(methods).flat()) {
    const completion = deferred();
    const api = loadStoreKit({
      implementations: { [name]: () => completion.promise },
    });
    let settled = false;
    const promise = api[name]({ appId: '123' }).then((result) => {
      settled = true;
      return result;
    });
    await Promise.resolve();
    await Promise.resolve();
    assert.equal(settled, false, `${name} should await native completion`);
    completion.resolve();
    assert.equal(await promise, undefined);
    assert.equal(settled, true);
  }
});

test('native errors retain their identity, message and code for every StoreKit method', async () => {
  for (const name of Object.values(methods).flat()) {
    const error = Object.assign(new Error('StoreKit failed to finish.'), {
      code: 'E_STOREKIT_TEST_FAILURE',
    });
    const api = loadStoreKit({
      implementations: { [name]: () => Promise.reject(error) },
    });
    await assert.rejects(
      api[name]({ appId: '123' }),
      (actual) => actual === error
    );
    assert.equal(api.calls[0].name, name);
  }
});
