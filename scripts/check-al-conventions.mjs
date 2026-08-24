/**
 * AL convention gate.
 *
 * These rules are enforced by the AL compiler and its analyzers at build time. This
 * script is not a replacement for that build — it is what makes them checkable in CI
 * before a compiler and a symbol download are available, and it catches the class of
 * mistake that is cheapest to fix in the same minute it is made.
 *
 * Every rule here corresponds to a documented standard, and each failure names it.
 * No dependencies: it runs on a bare Node.
 */
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, basename, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const repoRoot = fileURLToPath(new URL('..', import.meta.url));
const appRoot = join(repoRoot, 'app');
const srcRoot = join(appRoot, 'src');

const appJson = JSON.parse(readFileSync(join(appRoot, 'app.json'), 'utf8'));
const affixes = JSON.parse(readFileSync(join(appRoot, 'AppSourceCop.json'), 'utf8')).mandatoryAffixes ?? [];
const ranges = appJson.idRanges ?? [];

const FILE_SUFFIX = {
  table: 'Table', tableextension: 'TableExt', page: 'Page', pageextension: 'PageExt',
  codeunit: 'Codeunit', query: 'Query', report: 'Report', reportextension: 'ReportExt',
  enum: 'Enum', enumextension: 'EnumExt', interface: 'Interface',
  permissionset: 'PermissionSet', permissionsetextension: 'PermissionSetExt',
  xmlport: 'XmlPort', profile: 'Profile', entitlement: 'Entitlement',
};
const SHORT_NAME_TYPES = new Set(['permissionset', 'permissionsetextension', 'entitlement']);
// String.raw, not a plain template literal: `\s` in a plain template literal is an
// unrecognised escape and collapses to `s`, which silently turns this into a pattern
// that matches nothing and reports every file as having no declaration.
const DECLARATION = new RegExp(
  String.raw`^(${Object.keys(FILE_SUFFIX).join('|')})\s+(?:(\d+)\s+)?"?([^"\n{]+?)"?\s*(?:extends|implements|$|\{)`, 'm');

function walk(dir) {
  const found = [];
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) found.push(...walk(full));
    else if (entry.endsWith('.al')) found.push(full);
  }
  return found;
}

const failures = [];
const fail = (file, rule, message) => failures.push(`${relative(repoRoot, file)}: [${rule}] ${message}`);

const idsSeen = new Map();
const declaringNamespace = new Map();
const fileFacts = new Map();
const declaredObjects = new Set();
const referencedObjects = new Map();
const files = walk(srcRoot);

for (const file of files) {
  const source = readFileSync(file, 'utf8');
  const name = basename(file);
  const lines = source.split(/\r?\n/);

  if (!lines[0]?.startsWith('namespace ')) {
    fail(file, 'namespace', 'the first line must declare a namespace');
  }

  const usings = lines.filter((l) => l.trim().startsWith('using ')).map((l) => l.trim());
  const sorted = [...usings].sort();
  if (usings.join('\n') !== sorted.join('\n')) {
    fail(file, 'AA0477', `using statements are not sorted; expected ${sorted.join(', ')}`);
  }

  for (const [index, line] of lines.entries()) {
    const withoutStrings = line.replace(/'(?:[^']|'')*'/g, "''");
    const comment = withoutStrings.indexOf('//');
    if (comment >= 0 && withoutStrings[comment + 2] !== '/') {
      fail(file, 'no-comments', `line ${index + 1} has an inline // comment`);
    }
    if (line.trim().startsWith('/// <summary>')) {
      // The attribute sits between the doc comment and the signature, so the exemption
      // has to look forward from the summary rather than back at it.
      const ahead = lines.slice(index + 1, index + 10);
      const signatureAt = ahead.findIndex((l) => /\bprocedure\b/.test(l));
      const target = signatureAt >= 0 ? ahead[signatureAt] : undefined;
      const attributes = signatureAt >= 0 ? ahead.slice(0, signatureAt).join('\n') : '';
      // An OnResolve publisher is local by necessity and is a documented extension
      // point -- the one case the standard's own pattern shows documented.
      const isPublisher = /\[IntegrationEvent|\[BusinessEvent|\[ExternalBusinessEvent/.test(attributes);
      if (target && /\blocal\s+procedure\b/.test(target) && !isPublisher) {
        fail(file, 'summary-scope', `line ${index + 1} documents a local procedure`);
      }
    }
  }

  const match = DECLARATION.exec(source);
  if (!match) {
    fail(file, 'declaration', 'no object declaration found');
    continue;
  }
  const [, type, id, objectName] = match;
  declaredObjects.add(objectName);
  declaringNamespace.set(objectName, lines[0].replace(/^namespace\s+|;\s*$/g, '').trim());
  fileFacts.set(file, {
    namespace: lines[0].replace(/^namespace\s+|;\s*$/g, '').trim(),
    usings: new Set(usings.map((u) => u.replace(/^using\s+|;\s*$/g, '').trim())),
    references: new Set([...source.matchAll(/"((?:CMC) [^"]+)"/g)].map((m) => m[1])),
  });

  if (!affixes.some((affix) => objectName.startsWith(`${affix} `))) {
    fail(file, 'affix', `object name "${objectName}" does not start with a mandatory affix`);
  }

  const cap = SHORT_NAME_TYPES.has(type) ? 20 : 30;
  if (objectName.length > cap) {
    fail(file, 'name-length', `"${objectName}" is ${objectName.length} characters; the cap for ${type} is ${cap}`);
  }

  if (id) {
    const numeric = Number(id);
    if (!ranges.some((r) => numeric >= r.from && numeric <= r.to)) {
      fail(file, 'id-range', `id ${id} is outside the ranges declared in app.json`);
    }
    const key = `${type} ${id}`;
    if (idsSeen.has(key)) {
      fail(file, 'id-unique', `id ${id} is already used by ${idsSeen.get(key)}`);
    } else {
      idsSeen.set(key, objectName);
    }
  } else if (type !== 'interface') {
    fail(file, 'id-missing', `${type} "${objectName}" has no object id`);
  }

  const affix = affixes.find((a) => objectName.startsWith(`${a} `));
  const stripped = affix ? objectName.slice(affix.length + 1) : objectName;
  const expected = `${stripped.replace(/[^A-Za-z0-9]/g, '')}.${FILE_SUFFIX[type]}.al`;
  if (name !== expected) {
    fail(file, 'AA0215/LC0015', `file should be named ${expected} for object "${objectName}"`);
  }

  for (const reference of source.matchAll(/"((?:CMC) [^"]+)"/g)) {
    if (!referencedObjects.has(reference[1])) referencedObjects.set(reference[1], file);
  }
}

for (const [reference, file] of referencedObjects) {
  if (!declaredObjects.has(reference)) {
    fail(file, 'unresolved', `references "${reference}", which no file in this app declares`);
  }
}

/*
 * A missing `using` for one of our own namespaces.
 *
 * The moment a file declares a namespace it loses the global lookup, so a reference to
 * an object in a sibling feature needs an explicit `using` or it will not resolve. The
 * compiler reports this as AL0185 with no file name attached, which makes it tedious to
 * locate in a large app -- so it is worth catching here, where the file is known.
 *
 * Only our own objects are checked. Microsoft namespaces cannot be resolved without
 * symbols, and guessing at them would produce false failures.
 */
for (const [file, facts] of fileFacts) {
  for (const reference of facts.references) {
    const owner = declaringNamespace.get(reference);
    if (!owner || owner === facts.namespace) continue;
    if (!facts.usings.has(owner)) {
      fail(file, 'AL0185', `references "${reference}" from ${owner} without "using ${owner};"`);
    }
  }
}

console.log(`Checked ${files.length} AL files against ${affixes.join(', ')} and id range `
  + ranges.map((r) => `${r.from}-${r.to}`).join(', '));

if (failures.length > 0) {
  console.error(`\n${failures.length} convention problem(s):`);
  for (const failure of failures) console.error(`  - ${failure}`);
  process.exitCode = 1;
} else {
  console.log('No convention problems.');
}
