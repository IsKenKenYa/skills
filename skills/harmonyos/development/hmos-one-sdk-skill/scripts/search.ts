#!/usr/bin/env node
/**
 * HarmonyOS SDK 文档 BM25 检索工具。
 *
 * 加载 build_index.ts 构建的倒排索引，对用户查询进行分词并按 BM25 算法打分，
 * 返回 Top N 最相关文档（路径、标题、分类、得分、摘要）。
 *
 * 用法：
 *     node scripts/search.ts "ArkUI 状态管理"
 *     node scripts/search.ts "如何播放音频" --top 5
 *     node scripts/search.ts "Push Token" --category "Push Kit" --top 8
 *     node scripts/search.ts "Web组件加载本地资源" --snippet
 *     node scripts/search.ts "状态管理" --json         # 机器可读输出
 *
 * 说明：
 *     - 若索引不存在或过期，会自动调用 build_index.ts 重建
 *     - 摘要片段优先展示包含查询词的上下文
 */

import * as fs from 'fs';
import * as path from 'path';
import { execFileSync } from 'child_process';
import { fileURLToPath } from 'url';
import {
  tokenize,
  parseFrontmatter,
  loadGzipJson,
  PATHS,
  type Document,
  type InvertedIndex,
  type IndexMeta,
} from './build_index.ts';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const { REFERENCES_DIR, INDEX_DIR } = PATHS;

// ----------------------------- 索引加载 -----------------------------

function _rebuildIndex(): void {
  execFileSync(process.execPath, [path.join(__dirname, 'build_index.ts')], { stdio: 'inherit' });
}

function _loadMeta(): IndexMeta {
  return JSON.parse(fs.readFileSync(PATHS.META_PATH, 'utf-8')) as IndexMeta;
}

// 与 references 目录最新技能文件 mtime 对比，用于过期检测
function _newestReferenceMtime(dir: string): number {
  let newest = 0;
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      const m = _newestReferenceMtime(full);
      if (m > newest) { newest = m; }
    } else if (entry.isFile() && PATHS.SKILL_FILES.has(entry.name)) {
      try {
        const m = fs.statSync(full).mtimeMs / 1000;
        if (m > newest) { newest = m; }
      } catch {
        // ignore
      }
    }
  }
  return newest;
}

function _ensureIndex(): IndexMeta {
  const { DOCS_PATH, INVERTED_PATH } = PATHS;
  if (!fs.existsSync(DOCS_PATH) || !fs.existsSync(INVERTED_PATH) || !fs.existsSync(PATHS.META_PATH)) {
    console.error('[info] 索引不存在，开始构建...');
    _rebuildIndex();
  }
  const meta = _loadMeta();

  const newest = _newestReferenceMtime(REFERENCES_DIR);
  if ((meta.built_at_epoch || 0) < newest - 1) {
    console.error('[info] 检测到文档更新，重建索引...');
    _rebuildIndex();
    return _loadMeta();
  }
  return meta;
}

function loadIndex(): [Document[], InvertedIndex, IndexMeta] {
  const meta = _ensureIndex();
  const documents = loadGzipJson<Document[]>(PATHS.DOCS_PATH);
  const inverted = loadGzipJson<InvertedIndex>(PATHS.INVERTED_PATH);
  return [documents, inverted, meta];
}

// ----------------------------- BM25 打分 -----------------------------

function bm25Score(
  queryTerms: string[],
  inverted: InvertedIndex,
  documents: Document[],
  avgdl: number,
  k1: number = 1.5,
  b: number = 0.75,
): Map<number, number> {
  const nDocs = documents.length;
  const scores = new Map<number, number>();
  if (queryTerms.length === 0) { return scores; }

  for (const term of queryTerms) {
    const postings = inverted[term];
    if (!postings || postings.length === 0) {
      continue;
    }
    const df = postings.length / 2; // 扁平 [doc_id, tf, ...]
    const idf = Math.log(1 + (nDocs - df + 0.5) / (df + 0.5));
    for (let i = 0; i < postings.length; i += 2) {
      const docId = postings[i];
      const tf = postings[i + 1];
      const docLen = documents[docId].length;
      const denom = tf + k1 * (1 - b + (b * docLen) / (avgdl || 1.0));
      const s = (idf * (tf * (k1 + 1))) / denom;
      scores.set(docId, (scores.get(docId) || 0.0) + s);
    }
  }
  return scores;
}

// ----------------------------- 摘要 -----------------------------

// 去除 markdown 链接/图片/标记，简化展示
function _cleanMarkdownBody(body0: string): string {
  return body0
    .replace(/!\[[^\]]*\]\([^)]*\)/g, '')
    .replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')
    .replace(/[`*_>#|]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

// 找最早出现的查询词位置，无匹配返回 -1
function _findFirstQueryPosition(lowerBody: string, queryTerms: string[]): number {
  let first = -1;
  for (const q of queryTerms) {
    if (!q) { continue; }
    const idx = lowerBody.indexOf(q.toLowerCase());
    if (idx >= 0 && (first < 0 || idx < first)) {
      first = idx;
    }
  }
  return first;
}

function _extractSnippetWindow(body: string, center: number, maxLen: number): string {
  const half = Math.floor(maxLen / 2);
  const start = Math.max(0, center - half);
  const end = Math.min(body.length, center + half);
  let snippet = body.slice(start, end);
  if (start > 0) { snippet = '...' + snippet; }
  if (end < body.length) {
    snippet = snippet + '...';
  }
  return snippet;
}

function makeSnippet(relPath: string, queryTerms: string[], maxLen: number = 240): string {
  const absPath = path.join(REFERENCES_DIR, relPath);
  let content: string;
  try {
    content = fs.readFileSync(absPath, 'utf-8');
  } catch {
    return '';
  }

  const [, body0] = parseFrontmatter(content);
  const body = _cleanMarkdownBody(body0);
  if (!body) { return ''; }

  const center = _findFirstQueryPosition(body.toLowerCase(), queryTerms);
  if (center < 0) {
    return body.slice(0, maxLen) + (body.length > maxLen ? '...' : '');
  }
  return _extractSnippetWindow(body, center, maxLen);
}

// ----------------------------- 输出 -----------------------------

function _categoryShort(cat: string): string {
  const idx = cat.indexOf('(');
  if (idx > 0) {
    return cat.slice(0, idx).trim();
  }
  return cat.slice(0, 20);
}

function _normalizeCategory(category: string): string {
  const catLower = category.toLowerCase().replace(/[\s\-_]/g, '');
  try {
    // Scan all subdirectories under REFERENCES_DIR (e.g., hmos-sdk-basic-skill/, and future dirs)
    for (const sub of fs.readdirSync(REFERENCES_DIR)) {
      const subPath = path.join(REFERENCES_DIR, sub);
      if (!fs.statSync(subPath).isDirectory()) { continue; }
      for (const name of fs.readdirSync(subPath)) {
        const full = path.join(subPath, name);
        if (!fs.statSync(full).isDirectory()) { continue; }
        // 完整匹配
        if (name === category) { return name; }
        // 英文名匹配（括号前部分）
        const en = name.split('(')[0].trim();
        if (en.toLowerCase().replace(/[\s\-_]/g, '') === catLower) { return name; }
        // 中文匹配（括号内）
        if (name.includes('(') && name.includes(')')) {
          const cnMatch = name.slice(name.indexOf('(') + 1, name.indexOf(')'));
          if (cnMatch && cnMatch.includes(category)) { return name; }
        }
        // 英文名包含匹配
        if (en.toLowerCase().replace(/[\s\-_]/g, '').includes(catLower)) {
          return name;
        }
      }
    }
  } catch {
    // ignore
  }
  return category;
}

function formatResults(
  query: string,
  hits: [number, number][],
  documents: Document[],
  queryTerms: string[],
  elapsed: number,
  totalSearched: number,
  withSnippet: boolean,
): string {
  const lines: string[] = [];
  lines.push(`Top ${hits.length} results for "${query}" (searched ${totalSearched} docs in ${elapsed.toFixed(3)}s)`);
  lines.push('');
  if (hits.length === 0) {
    lines.push('（无匹配文档。可尝试：拆分关键词、改用 Kit 名、去掉版本号、或查阅 hmos-sdk-basic-skill/kit-routing.md）');
    return lines.join('\n');
  }
  for (let rank = 0; rank < hits.length; rank++) {
    const [docId, score] = hits[rank];
    const doc = documents[docId];
    const cat = _categoryShort(doc.category || '');
    const title = doc.title || '';
    const docPath = doc.path || '';
    const bc = doc.breadcrumb || '';
    lines.push(`[${rank + 1}] score=${score.toFixed(2)}  ${cat}  ${docPath}`);
    if (title) { lines.push(`    Title: ${title}`); }
    if (bc) { lines.push(`    Breadcrumb: ${bc}`); }
    if (withSnippet) {
      const snip = makeSnippet(docPath, queryTerms);
      if (snip) {
        lines.push(`    Snippet: ${snip}`);
      }
    }
    lines.push('');
  }
  return lines.join('\n').replace(/\s+$/, '') + '\n';
}

function formatJson(
  query: string,
  hits: [number, number][],
  documents: Document[],
  queryTerms: string[],
  elapsed: number,
  totalSearched: number,
  withSnippet: boolean,
): string {
  const results = hits.map(([docId, score], rank) => {
    const doc = documents[docId];
    const item: Record<string, unknown> = {
      rank: rank + 1,
      score: Math.round(score * 10000) / 10000,
      path: doc.path || '',
      title: doc.title || '',
      breadcrumb: doc.breadcrumb || '',
      category: doc.category || '',
      url: doc.url || '',
    };
    if (withSnippet) {
      item.snippet = makeSnippet(doc.path || '', queryTerms);
    }
    return item;
  });
  const payload = {
    query,
    query_terms: queryTerms,
    total_searched: totalSearched,
    elapsed_sec: Math.round(elapsed * 10000) / 10000,
    count: results.length,
    results,
  };
  return JSON.stringify(payload, null, 2);
}

// ----------------------------- 主入口 -----------------------------

export function search(
  query: string,
  top: number = 10,
  category?: string,
  withSnippet: boolean = false,
): [[number, number][], Document[], string[], number, number] {
  const [documents, inverted, meta] = loadIndex();
  const avgdl = meta.avg_doc_length || 1.0;
  const queryTerms = tokenize(query);

  // 检查 query term 的 df=0 占比，超过半数不存在说明结果基本是噪声
  const uniqueTerms = [...new Set(queryTerms)];
  const missingCount = uniqueTerms.filter(t => !inverted[t] || inverted[t].length === 0).length;
  const missingRatio = uniqueTerms.length > 0 ? missingCount / uniqueTerms.length : 0;

  const t0 = Date.now();
  const scores = missingRatio > 0.5
    ? new Map<number, number>()
    : bm25Score(queryTerms, inverted, documents, avgdl, meta.k1 || 1.5, meta.b || 0.75);
  const elapsed = (Date.now() - t0) / 1000;

  // 按分类过滤
  let filteredScores = scores;
  if (category) {
    const normCat = _normalizeCategory(category);
    filteredScores = new Map<number, number>();
    for (const [did, s] of scores) {
      if (documents[did].category === normCat) {
        filteredScores.set(did, s);
      }
    }
  }

  // 排序取 Top N
  const hits: [number, number][] = [...filteredScores.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, top);
  return [hits, documents, queryTerms, elapsed, documents.length];
}

function main(): number {
  const args = process.argv.slice(2);
  if (args.length === 0) {
    console.error('用法: node scripts/search.ts "查询字符串" [--top N] [--category CAT] [--snippet] [--json]');
    return 1;
  }

  const query = args[0];
  let top = 10;
  let category: string | undefined;
  let withSnippet = false;
  let asJson = false;

  for (let i = 1; i < args.length; i++) {
    const a = args[i];
    if (a === '--top' && i + 1 < args.length) {
      top = parseInt(args[++i], 10);
    } else if (a === '--category' && i + 1 < args.length) {
      category = args[++i];
    } else if (a === '--snippet') {
      withSnippet = true;
    } else if (a === '--json') {
      asJson = true;
    }
  }

  const [hits, documents, queryTerms, elapsed, total] = search(query, top, category, withSnippet);

  if (asJson) {
    console.log(formatJson(query, hits, documents, queryTerms, elapsed, total, withSnippet));
  } else {
    console.log(formatResults(query, hits, documents, queryTerms, elapsed, total, withSnippet));
  }
  return 0;
}

main();
