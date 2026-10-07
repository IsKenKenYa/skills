import { test } from 'node:test';
import assert from 'node:assert/strict';
import { confirmScanBuckets } from './skeleton.js';

function fakeReadline(answers) {
  const q = [];
  return {
    readline: {
      question: async (prompt) => { q.push(prompt); return answers.shift() ?? ''; },
      close: () => {}
    },
    prompts: q
  };
}

function docOf(buckets) {
  return { project_model: 'stage', adaptation: buckets };
}

test('SD31：--yes 跳过逐桶确认（仍打印全桶摘要）；非 TTY 无 --yes → 退出码 6', async () => {
  const doc = docOf({ full_direct: [{ module: '@ohos.router', symbol: 'router', reason: 'r' }], unknown: [] });
  let logs = [];
  const origLog = console.log; console.log = (...a) => logs.push(a.join(' '));
  try {
    const r = await confirmScanBuckets(doc, '/x/f2-out/scan-report.json', { yes: true });
    assert.equal(r, 'ok');
    assert.ok(logs.some((l) => l.includes('完整直用（full_direct） 1')), '摘要含桶计数');
    assert.ok(logs.some((l) => l.includes('--yes：跳过逐桶确认')));
    assert.ok(logs.some((l) => l.includes('migration-advice.md')), '提示报告路径');
    // SD31 交互序修正：非 TTY 未确认 → 零产出 exit 6（与 SD32 SDK 确认同款强制）
    const origErr2 = console.error; console.error = (...a) => logs.push(a.join(' '));
    const origExit2 = process.exit;
    let exitCode2 = null;
    process.exit = (c) => { exitCode2 = c; throw new Error('__exit2__'); };
    try {
      await confirmScanBuckets(doc, '/x/scan-report.json', {}, { isTTY: false });
      assert.fail('应 exit 6');
    } catch (e) { assert.match(String(e), /__exit2__/); }
    process.exit = origExit2; console.error = origErr2;
    assert.equal(exitCode2, 6, '非 TTY 未确认退出码 6');
    assert.ok(logs.some((l) => l.includes('呈报块')), '输出预格式化呈报块');
    assert.ok(logs.some((l) => l.includes('【⑦ unknown（待人工确认）】共 0 条')), '呈报块含 unknown 桶行');
    assert.ok(logs.some((l) => l.includes('呈报块结束')), '呈报块闭合');
  } finally {
    console.log = origLog;
  }
});

test('SD31：风险序逐桶（unknown 先于 full_direct）；y 逐桶确认；a 剩余全确认；空桶跳过', async () => {
  const doc = docOf({
    unknown: [{ module: '@kit.X', symbol: 'x', reason: '未知' }],
    full_direct: [{ module: '@ohos.a', symbol: 'a1', reason: 'r' }, { module: '@ohos.b', symbol: 'b1', reason: 'r2' }]
  });
  const { readline, prompts } = fakeReadline(['y', 'a']);
  let logs = [];
  const origLog = console.log; console.log = (...a) => logs.push(a.join(' '));
  try {
    const r = await confirmScanBuckets(doc, '/x/scan-report.json', {}, { isTTY: true, readline });
    assert.equal(r, 'ok');
    const order = logs.findIndex((l) => l.includes('unknown（待人工确认）'));
    const orderFd = logs.findIndex((l) => l.includes('（2）① 完整直用'));
    assert.ok(order >= 0 && orderFd > order, 'unknown 先确认、full_direct 其后（风险序）');
    assert.equal(prompts.length, 2, '两个非空桶各问一次（空桶不问）');
    assert.ok(logs.some((l) => l.includes('剩余桶全部确认')), 'a 键生效');
  } finally { console.log = origLog; }
});

test('SD31：n 中止 → 退出码 6 + 复核指引；无效输入重问', async () => {
  const doc = docOf({ unknown: [{ module: '@kit.X', symbol: 'x', reason: '未知' }] });
  const { readline } = fakeReadline(['bad', 'n']);
  const origLog = console.log, origErr = console.error;
  const logs = [];
  console.log = (...a) => logs.push(a.join(' '));
  console.error = (...a) => logs.push(a.join(' '));
  let exitCode = null;
  const origExit = process.exit;
  process.exit = (c) => { exitCode = c; throw new Error('__exit__'); };
  try {
    await confirmScanBuckets(doc, '/x/scan-report.json', {}, { isTTY: true, readline });
    assert.fail('应中止');
  } catch (e) {
    assert.match(String(e), /__exit__/);
  } finally {
    process.exit = origExit; console.log = origLog; console.error = origErr;
  }
  assert.equal(exitCode, 6);
  assert.ok(logs.some((l) => l.includes('输入无效')), '无效输入重问提示');
  assert.ok(logs.some((l) => l.includes('复核') && l.includes('migration-advice.md')), '中止给复核指引');
});
