#!/usr/bin/env node
/**
 * HarmonyOS SDK 文档 BM25 索引构建工具。
 *
 * 扫描 references/ 下的技能定义文件（SUB_SKILL.md / SKILL.md，按 Kit 组织），解析 YAML frontmatter
 * （name/description/title/breadcrumb），对标题、描述、面包屑、正文进行分词并加权
 * （标题 5x、描述 3x、面包屑 2x、正文 1x、路径 1x），构建倒排索引并持久化为
 * gzip 压缩的 JSON 文件，供 search.ts 在毫秒级返回 Top N 文档。
 *
 * 用法：
 *     node scripts/build_index.ts            # 默认构建索引
 *     node scripts/build_index.ts --force    # 强制重建
 *
 * 索引产物（位于 scripts/index/）：
 *     - docs.json.gz    : 文档元信息列表（id/path/title/category/length/breadcrumb/description），gzip 压缩
 *     - inverted.json.gz: 倒排索引 {term: [doc_id, tf, ...]}，gzip 压缩
 *     - meta.json       : 索引元数据（avg_doc_length/total_docs/构建时间/参数）
 */

import * as fs from 'fs';
import * as path from 'path';
import * as zlib from 'zlib';
import { fileURLToPath } from 'url';

// ----------------------------- 配置 -----------------------------

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.dirname(__dirname);
const REFERENCES_DIR = path.join(ROOT);
const INDEX_DIR = path.join(ROOT, 'scripts', 'index');

const SKILL_FILES = new Set(['SUB_SKILL.md']);

// BM25 参数
const K1 = 1.5;
const B = 0.75;

// 字段权重
const TITLE_WEIGHT = 5.0;
const DESCRIPTION_WEIGHT = 3.0;
const BREADCRUMB_WEIGHT = 2.0;
const BODY_WEIGHT = 1.0;
const PATH_WEIGHT = 1.0;

// ----------------------------- 类型定义 -----------------------------

export interface Document {
  id: number;
  path: string;
  title: string;
  breadcrumb: string;
  category: string;
  url: string;
  length: number;
}

export type InvertedIndex = Record<string, number[]>;

export interface IndexMeta {
  built_at: string;
  built_at_epoch: number;
  total_docs: number;
  avg_doc_length: number;
  vocabulary_size: number;
  postings_format: string;
  max_tf: number;
  k1: number;
  b: number;
  title_weight: number;
  description_weight: number;
  breadcrumb_weight: number;
  body_weight: number;
  path_weight: number;
  skipped: number;
  compression: string;
  references_dir: string;
}

// ----------------------------- 分词 -----------------------------

// 中文 Unicode 范围（基础 + 扩展 A + 兼容）
const _CJK_RE = /[\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff]/g;
// 英文单词：含连字符的字母数字串
const _WORD_RE = /[A-Za-z0-9][A-Za-z0-9_-]*/g;
// CamelCase 切分
const _CAMEL_RE = /([a-z0-9])([A-Z])/g;
// 前端 frontmatter
const _FRONTMATTER_RE = /^---\s*\n(.*?\n)---\s*\n/s;

// 中英停用词（保守版，避免误杀技术词汇）
const _STOPWORDS = new Set<string>([
  // 中文
  '的', '了', '和', '是', '在', '与', '或', '及', '为', '对', '由', '从', '到',
  '可', '可以', '能够', '应', '应当', '需要', '需', '进行', '通过', '使用',
  '用于', '以及', '等', '其', '其中', '该', '这个', '这些',
  '一个', '一种', '一些', '上述', '下述', '如下', '例如', '比如',
  '不', '无', '非', '未', '若', '如果', '则', '那么', '即', '便', '都',
  // 英文
  'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
  'and', 'or', 'not', 'but', 'if', 'then', 'else', 'for', 'of', 'to',
  'in', 'on', 'at', 'by', 'with', 'from', 'as', 'into', 'onto',
  'this', 'that', 'these', 'those', 'it', 'its', 'they', 'them',
  'you', 'your', 'we', 'our', 'us', 'i', 'me', 'my',
  'do', 'does', 'did', 'done', 'have', 'has', 'had',
  'will', 'would', 'can', 'could', 'should', 'shall', 'may', 'might',
  'use', 'used', 'uses', 'using', 'example', 'examples', 'note', 'notes',
]);

function _splitCamel(token: string): string[] {
  if (!token) { return []; }
  const sub = token.replace(_CAMEL_RE, '$1 $2');
  const parts = sub.split(/[\s_-]+/).filter(p => p.length > 0);
  const out: string[] = [];
  for (const p of parts) {
    const low = p.toLowerCase();
    if (low) { out.push(low); }
  }
  const whole = token.toLowerCase();
  if (whole && !out.includes(whole)) {
    out.push(whole);
  }
  return out;
}

function _tokenizeWords(text: string): string[] {
  const wordMatches = text.match(_WORD_RE);
  if (!wordMatches) { return []; }
  const tokens: string[] = [];
  for (const raw of wordMatches) {
    for (const sub of _splitCamel(raw)) {
      if (sub.length <= 1) { continue; }
      if (_STOPWORDS.has(sub)) { continue; }
      tokens.push(sub);
    }
  }
  return tokens;
}

function _tokenizeCjk(text: string): string[] {
  const cjkChars = text.match(_CJK_RE);
  if (!cjkChars) { return []; }
  const tokens: string[] = [];
  for (const ch of cjkChars) {
    if (_STOPWORDS.has(ch)) { continue; }
    tokens.push(ch);
  }
  for (let i = 0; i < cjkChars.length - 1; i++) {
    const bigram = cjkChars[i] + cjkChars[i + 1];
    if (_STOPWORDS.has(bigram)) { continue; }
    tokens.push(bigram);
  }
  return tokens;
}

export function tokenize(text: string): string[] {
  if (!text) { return []; }
  return [..._tokenizeWords(text), ..._tokenizeCjk(text)];
}

// ----------------------------- frontmatter -----------------------------

function _parseFrontmatterLine(line: string): [string, string] | null {
  const idx = line.indexOf(':');
  if (idx < 0) { return null; }
  const k = line.slice(0, idx).trim();
  const v = line.slice(idx + 1).trim().replace(/^["']|["']$/g, '');
  if (!k || !v) { return null; }
  return [k, v];
}

export function parseFrontmatter(content: string): [Record<string, string>, string] {
  const m = _FRONTMATTER_RE.exec(content);
  if (!m) { return [{}, content]; }
  const fmText = m[1];
  const body = content.slice(m.index + m[0].length);
  const meta: Record<string, string> = {};
  for (const line of fmText.split('\n')) {
    const parsed = _parseFrontmatterLine(line);
    if (parsed) {
      meta[parsed[0]] = parsed[1];
    }
  }
  return [meta, body];
}

export function extractPathSegments(relPath: string): string {
  const noExt = relPath.replace(/\.[^/.]+$/, '');
  const parts = noExt.split(/[\\/]+/);
  const skip = new Set(['', '.']);
  return parts.filter(p => p && !skip.has(p)).join(' ');
}

// ----------------------------- 索引加载 -----------------------------

export function loadGzipJson<T>(filePath: string): T {
  const buf = fs.readFileSync(filePath);
  const json = zlib.gunzipSync(buf).toString('utf-8');
  return JSON.parse(json) as T;
}

export function dumpGzipJson(obj: unknown, filePath: string): void {
  const json = JSON.stringify(obj);
  const compressed = zlib.gzipSync(json, { level: 9 });
  fs.writeFileSync(filePath, compressed);
}

export const PATHS = {
  ROOT,
  REFERENCES_DIR,
  INDEX_DIR,
  SKILL_FILES,
  DOCS_PATH: path.join(INDEX_DIR, 'docs.json.gz'),
  INVERTED_PATH: path.join(INDEX_DIR, 'inverted.json.gz'),
  META_PATH: path.join(INDEX_DIR, 'meta.json'),
};

// ----------------------------- 索引构建 -----------------------------

function _walkDir(dir: string): string[] {
  const results: string[] = [];
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(..._walkDir(fullPath));
    } else if (entry.isFile() && SKILL_FILES.has(entry.name)) {
      results.push(fullPath);
    }
  }
  return results;
}

function _newestSkillMtime(): number {
  let newest = 0;
  const files = _walkDir(REFERENCES_DIR);
  for (const f of files) {
    try {
      const stat = fs.statSync(f);
      if (stat.mtimeMs > newest) {
        newest = stat.mtimeMs / 1000;
      }
    } catch {
      // ignore
    }
  }
  return newest;
}

function buildIndex(force: boolean = false): void {
  fs.mkdirSync(INDEX_DIR, { recursive: true });

  const docsPath = PATHS.DOCS_PATH;
  const invertedPath = PATHS.INVERTED_PATH;
  const metaPath = PATHS.META_PATH;

  // 清理旧格式文件（pickle/zst），避免残留
  for (const oldName of ['docs.pkl', 'docs.pkl.xz', 'docs.pkl.zst', 'inverted.pkl', 'inverted.pkl.xz', 'inverted.pkl.zst']) {
    const oldPath = path.join(INDEX_DIR, oldName);
    if (fs.existsSync(oldPath)) {
      try {
        fs.unlinkSync(oldPath);
      } catch {
        // ignore
      }
    }
  }

  // 增量构建：若索引已存在且较新则跳过
  if (!force && fs.existsSync(metaPath) && fs.existsSync(docsPath) && fs.existsSync(invertedPath)) {
    const oldMeta = JSON.parse(fs.readFileSync(metaPath, 'utf-8')) as IndexMeta;
    const oldBuilt = oldMeta.built_at_epoch || 0;
    const newest = _newestSkillMtime();
    if (oldBuilt >= newest) {
      return;
    }
  }

  const t0 = Date.now();
  const documents: Document[] = [];
  const inverted: Map<string, number[]> = new Map();
  let totalLength = 0;
  let skipped = 0;
  let maxTf = 0;

  const skillFiles = _walkDir(REFERENCES_DIR);
  for (let i = 0; i < skillFiles.length; i++) {
    const absPath = skillFiles[i];
    const relPath = path.relative(REFERENCES_DIR, absPath).replace(/\\/g, '/');

    let content: string;
    try {
      content = fs.readFileSync(absPath, 'utf-8');
    } catch (e) {
      console.error(`[warn] 读取失败 ${relPath}: ${e}`);
      skipped++;
      continue;
    }

    const [meta, body] = parseFrontmatter(content);
    const title = meta.title || meta.name || path.basename(absPath, path.extname(absPath));
    const description = meta.description || '';
    const breadcrumb = meta.breadcrumb || description || '';
    const category = meta.category || relPath.split('/')[1] || relPath.split('/')[0];
    const url = meta.url || '';

    // 分词 + 加权
    const tfMap = new Map<string, number>();
    const fieldTokens: [string[], number][] = [
      [tokenize(title), TITLE_WEIGHT],
      [tokenize(description), DESCRIPTION_WEIGHT],
      [tokenize(breadcrumb), BREADCRUMB_WEIGHT],
      [tokenize(extractPathSegments(relPath)), PATH_WEIGHT],
      [tokenize(body), BODY_WEIGHT],
    ];
    for (const [toks, w] of fieldTokens) {
      for (const t of toks) {
        tfMap.set(t, (tfMap.get(t) || 0) + w);
      }
    }

    let docLength = 0;
    for (const tf of tfMap.values()) { docLength += tf; }
    if (docLength === 0) {
      skipped++;
      continue;
    }

    const docId = documents.length;
    documents.push({
      id: docId,
      path: relPath,
      title,
      breadcrumb,
      category,
      url,
      length: docLength,
    });
    totalLength += docLength;

    for (const [term, tf] of tfMap) {
      let postings = inverted.get(term);
      if (!postings) {
        postings = [];
        inverted.set(term, postings);
      }
      postings.push(docId, tf);
      if (tf > maxTf) {
        maxTf = tf;
      }
    }
  }

  const totalDocs = documents.length;
  const avgDocLength = totalDocs > 0 ? totalLength / totalDocs : 0.0;

  // 持久化（gzip 压缩 JSON，零第三方依赖）
  dumpGzipJson(documents, docsPath);

  // 倒排索引转为普通对象
  const invertedPlain: InvertedIndex = {};
  for (const [term, postings] of inverted) {
    invertedPlain[term] = postings;
  }
  dumpGzipJson(invertedPlain, invertedPath);

  const meta: IndexMeta = {
    built_at: new Date().toISOString().replace(/\.\d+Z$/, ''),
    built_at_epoch: Date.now() / 1000,
    total_docs: totalDocs,
    avg_doc_length: Math.round(avgDocLength * 100) / 100,
    vocabulary_size: Object.keys(invertedPlain).length,
    postings_format: 'flat_number_array_interleaved',
    max_tf: maxTf,
    k1: K1,
    b: B,
    title_weight: TITLE_WEIGHT,
    description_weight: DESCRIPTION_WEIGHT,
    breadcrumb_weight: BREADCRUMB_WEIGHT,
    body_weight: BODY_WEIGHT,
    path_weight: PATH_WEIGHT,
    skipped,
    compression: 'gzip',
    references_dir: '.',
  };
  fs.writeFileSync(metaPath, JSON.stringify(meta, null, 2), 'utf-8');
}

// ----------------------------- 主入口 -----------------------------

function main(): number {
  const args = process.argv.slice(2);
  const force = args.includes('--force') || args.includes('-f');
  buildIndex(force);
  return 0;
}

main();
