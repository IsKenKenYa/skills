import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { detectSdkCandidates, validateSdkDir, sdkVersionOf } from './sdk-locator.js';

function makeSdk(files) {
  const root = mkdtempSync(join(tmpdir(), 'f2-sdk-'));
  const apiDir = join(root, 'ets', 'api');
  mkdirSync(apiDir, { recursive: true });
  for (const [name, content] of Object.entries(files)) {
    writeFileSync(join(apiDir, name), content, 'utf8');
  }
  return root;
}

const VALID_DTS = [
  '/**',
  ' * @syscap SystemCapability.Test',
  ' * @crossplatform',
  ' */',
  'declare namespace demo {',
  '  function foo(): void;',
  '}',
  'export default demo;'
].join('\n');

test('validateSdkDir：含 ets/api 的 @ohos.*.d.ts → ok 且返回 apiDir', () => {
  const root = makeSdk({ '@ohos.demo.d.ts': VALID_DTS });
  const result = validateSdkDir(root);
  assert.ok(result.ok);
  assert.ok(result.apiDir.endsWith('api'));
  rmSync(root, { recursive: true, force: true });
});

test('validateSdkDir：缺 ets/api 或无 @ohos.*.d.ts → 不 ok（改指无效目录再次请求依据）', () => {
  const root = mkdtempSync(join(tmpdir(), 'f2-sdk-'));
  assert.equal(validateSdkDir(root).ok, false);
  assert.match(validateSdkDir(root).reason, /未找到 ets\/api/);
  assert.equal(validateSdkDir('/nonexistent/path').ok, false);
  rmSync(root, { recursive: true, force: true });
});

test('detectSdkCandidates：显式路径优先且仅返回该候选', () => {
  const candidates = detectSdkCandidates('/explicit/sdk');
  assert.equal(candidates.length, 1);
  assert.equal(candidates[0].origin, 'explicit');
});

test('detectSdkCandidates：环境变量候选', () => {
  process.env.OH_SDK_DIR = '/env/sdk';
  try {
    const candidates = detectSdkCandidates(null);
    assert.ok(candidates.some((c) => c.origin === 'env:OH_SDK_DIR' && c.path === '/env/sdk'));
  } finally {
    delete process.env.OH_SDK_DIR;
  }
});

test('sdkVersionOf：取目录名', () => {
  assert.equal(sdkVersionOf('/a/b/26.0.0'), '26.0.0');
});
