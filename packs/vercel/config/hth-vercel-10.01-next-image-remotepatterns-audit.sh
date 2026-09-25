#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 10.1: Audit /_next/image remotePatterns Allowlist
# Profile Level: L1 (Crawl)
# Frameworks: NIST SC-7, SI-10
# Source: https://howtoharden.com/guides/vercel/#101-audit-next-image-remotepatterns
# Rationale: The /_next/image endpoint performs server-side fetch() against
# URLs matching remotePatterns. Wildcards in remotePatterns enable SSRF
# (CVE-2025-57822, CVE-2025-6087). Treat remotePatterns as an explicit allowlist.
# Type: config -- a repository audit. Every remotePatterns ENTRY is checked on
# its own: the config file is parsed as text by node (never executed). The
# audit reads that one file statically. When remotePatterns (or images) comes
# from a variable, an import, a spread or a function call, it cannot see the
# entries, so it says so and exits 2 rather than reporting the config clean.
# Exit: 0 restrictive, 1 finding, 2 the audit could not read every entry.
# =============================================================================

set -euo pipefail

# HTH Guide Excerpt: begin config

CONFIG_FILE=""
for candidate in next.config.js next.config.mjs next.config.ts next.config.cjs; do
  if [ -f "${candidate}" ]; then
    CONFIG_FILE="${candidate}"
    break
  fi
done

if [ -z "${CONFIG_FILE}" ]; then
  echo "No next.config.* detected — skipping /_next/image audit."
  exit 0
fi

echo "=== Auditing ${CONFIG_FILE} remotePatterns, entry by entry ==="

rc=0
node - "${CONFIG_FILE}" <<'JS' || rc=$?
const fs = require('node:fs');
const src = fs.readFileSync(process.argv[2], 'utf8')
  .replace(/\/\*[\s\S]*?\*\//g, '')          // block comments
  .replace(/(^|[^:'"])\/\/.*$/gm, '$1');     // line comments (not inside URLs)
let findings = 0, unread = 0;
const report = (level, msg) => { console.log(`${level}: ${msg}`); findings++; };
const cannot = (msg) => { console.log(`WARN: ${msg} — cannot statically parse; review by hand.`); unread++; };
const near = (i) => src.slice(i, i + 60).replace(/\s+/g, ' ').trim();

// images.domains: deprecated, no protocol/path granularity
if (/\bdomains\s*:\s*\[/.test(src)) {
  report('WARN', 'images.domains is deprecated and wildcard-prone. Migrate to remotePatterns.');
}

// `images` must be an object literal in this file: `images: imported` or a
// spread inside it (`images: { ...base }`) hides remotePatterns from the audit.
for (const m of src.matchAll(/\bimages['"`]?\s*:/g)) {
  const lead = src.slice(m.index + m[0].length).match(/^\s*\{/);
  if (!lead) { cannot(`images is not an object literal (${near(m.index)})`); continue; }
  const props = entriesAt(m.index + m[0].length + lead[0].length - 1);
  if (props && props.some(p => p.startsWith('...'))) cannot(`images spreads another object (${near(m.index)})`);
}

// Bracket-match the array that opens at `open`, then split its top-level entries.
function entriesAt(open) {
  let i = open, depth = 0, quote = null, start = open + 1;
  const out = [];
  for (; i < src.length; i++) {
    const c = src[i];
    if (quote) { if (c === '\\') { i++; } else if (c === quote) { quote = null; } continue; }
    if (c === "'" || c === '"' || c === '`') { quote = c; continue; }
    if (c === '[' || c === '{' || c === '(') depth++;
    if (c === ']' || c === '}' || c === ')') depth--;
    if (depth === 1 && c === ',') { out.push(src.slice(start, i)); start = i + 1; }
    if (depth === 0) { out.push(src.slice(start, i)); return out.map(e => e.trim()).filter(Boolean); }
  }
  return null;
}

// Every mention of remotePatterns must be a literal array: a property
// (`remotePatterns: [`, quoted or not) or a declaration (`remotePatterns = [`,
// with an optional TypeScript type). Anything else -- `remotePatterns: PATTERNS`,
// the `{ remotePatterns }` shorthand, `.concat(...)` -- is reported as unread.
const LITERAL = /^['"`]?\s*(?::\s*[A-Za-z_$][\w$.<>]*(?:\[\])?\s*=|[:=])\s*\[/;
const field = (e, k) => { const m = e.match(new RegExp(`\\b${k}\\s*['"\`]?\\s*:\\s*['"\`]([^'"\`]*)['"\`]`)); return m ? m[1] : null; };
const hasKey = (e, k) => new RegExp(`\\b${k}\\s*['"\`]?\\s*:`).test(e);
// `{ remotePatterns }` shorthand is readable only when this file declares
// `const remotePatterns = [ ... ]` -- that declaration is parsed below.
const declared = /\b(?:const|let|var)\s+remotePatterns\s*(?::[^=;]+)?=\s*\[/.test(src);
let arrays = 0, total = 0;
for (const m of src.matchAll(/\bremotePatterns\b/g)) {
  const after = m.index + 'remotePatterns'.length;
  const lit = src.slice(after).match(LITERAL);
  if (!lit && declared && /^\s*[,}]/.test(src.slice(after))) continue;
  if (!lit) { cannot(`remotePatterns is not a literal array (${near(m.index)})`); continue; }
  const list = entriesAt(after + lit[0].length - 1);
  if (!list) { console.error('ERROR: could not parse the remotePatterns array.'); process.exit(2); }
  const name = arrays === 0 ? 'remotePatterns' : `remotePatterns#${arrays + 1}`;
  arrays++; total += list.length;
  list.forEach((e, n) => {
    const label = `${name}[${n}]`;
    let protocol, hostname, pathname;
    const url = e.match(/^new\s+URL\(\s*['"`]([^'"`]+)['"`]/);
    if (url) {
      const u = url[1].match(/^([a-z*]+):\/\/([^/]+)(\/.*)?$/i);
      if (!u) { report('WARN', `${label} unparseable URL pattern ${url[1]}`); return; }
      [protocol, hostname, pathname] = [u[1], u[2], u[3] && u[3] !== '/**' ? u[3] : null];
    } else if (e.startsWith('{')) {
      protocol = field(e, 'protocol'); hostname = field(e, 'hostname'); pathname = field(e, 'pathname');
      if (!hostname && hasKey(e, 'hostname')) { cannot(`${label} hostname is not a string literal`); return; }
    } else {
      cannot(`${label} is not a literal object or new URL(...): ${e.slice(0, 80)}`);
      return;
    }
    if (!hostname || hostname === '*' || hostname === '**') report('BLOCK', `${label} bare hostname wildcard ('${hostname}')`);
    else if (hostname.startsWith('*')) report('WARN', `${label} wildcard subdomain '${hostname}' — any tenant of that domain can serve images`);
    if (protocol === '*') report('BLOCK', `${label} wildcard protocol`);
    else if (protocol === 'http') report('WARN', `${label} http:// protocol — prefer https:// only`);
    if (!pathname) report('WARN', `${label} (${hostname}) has no pathname restriction — any path is allowed`);
  });
}

if (unread) process.exit(2);
if (arrays === 0) {
  if (!findings) console.log('OK: no remotePatterns declared (remote images disabled).');
  process.exit(findings ? 1 : 0);
}
if (!findings) console.log(`OK: ${total} remotePatterns entr${total === 1 ? 'y' : 'ies'}, all restrictive.`);
process.exit(findings ? 1 : 0);
JS

if [ "${rc}" -eq 1 ] || [ "${rc}" -eq 2 ]; then
  echo ""
  echo "Recommended shape (a literal array; hostname and pathname on EVERY entry):"
  echo "  { protocol: 'https', hostname: 'cdn.example.com', pathname: '/images/**' }"
fi
exit "${rc}"

# HTH Guide Excerpt: end config
