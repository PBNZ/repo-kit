// Generate Power Platform custom-connector definitions (OpenAPI 2.0 / Swagger)
// from the committed Postman collection in source/.
//
//   Postman collection -> resolve {{vars}} -> postman-to-openapi (3.0)
//   -> api-spec-converter (Swagger 2.0) -> fix securityDefinitions from the
//   Postman auth -> measure -> split per top-level folder ONLY if a single
//   definition would be >= the size limit.
//
// Runs inside the pinned Docker image (p2o + api-spec-converter on PATH).

import { readFileSync, writeFileSync, mkdirSync, mkdtempSync, readdirSync, rmSync, existsSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

const cfg = JSON.parse(readFileSync('connectors.config.json', 'utf8'));
const LIMIT = cfg.sizeLimitBytes ?? 1048576;
const limitStr = LIMIT >= 1048576 ? `${+(LIMIT / 1048576).toFixed(2)} MB` : `${Math.round(LIMIT / 1024)} KB`;
const OUT = cfg.output ?? 'connectors';
const work = mkdtempSync(join(tmpdir(), 'ppc-')); // unique per run; removed on exit
process.on('exit', () => { try { rmSync(work, { recursive: true, force: true }); } catch { /* best-effort */ } });
const warnings = [];

// --- locate + load the committed collection (prefer the documented source/collection.json) ---
const jsons = existsSync('source') ? readdirSync('source').filter((f) => f.endsWith('.json')).sort() : [];
const srcName = jsons.includes('collection.json') ? 'collection.json' : jsons[0];
if (!srcName) {
  console.log('source/ has no *.json collection yet — export your Postman collection to source/collection.json. Nothing to do.');
  process.exit(0);
}
const rawObj = JSON.parse(readFileSync(join('source', srcName), 'utf8'));
const collection = rawObj.collection ?? rawObj; // unwrap Postman API {"collection":…}
const rootVars = collection.variable || [];
const rootAuth = collection.auth || null;

// --- helpers ---
const sizeOf = (o) => Buffer.byteLength(JSON.stringify(o, null, 2));
const slug = (s) => (s || 'connector').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '') || 'connector';
const kv = (arr, k) => arr?.find((e) => e.key === k)?.value;

// Pre-resolve collection variables that are set (including "" and "0") so host/basePath come out
// real instead of "%7B%7Bbaseurl%7D%7D". Walk the parsed object and substitute inside string values
// only — safe against values containing quotes/backslashes/newlines (a raw string-replace on the
// serialized JSON could produce invalid JSON).
function resolveVars(obj, vars) {
  if (typeof obj === 'string') {
    let s = obj;
    for (const v of vars) if (v && v.key && v.value != null) s = s.split(`{{${v.key}}}`).join(String(v.value));
    return s;
  }
  if (Array.isArray(obj)) return obj.map((x) => resolveVars(x, vars));
  if (obj && typeof obj === 'object') { const r = {}; for (const [k, val] of Object.entries(obj)) r[k] = resolveVars(val, vars); return r; }
  return obj;
}

// Map a Postman auth block to a valid Swagger 2.0 security definition. p2o mis-maps these
// (e.g. apikey -> {type:http, scheme:apikey}, which is invalid 2.0 AND drops the header name),
// so we build them from the source collection instead.
function pmAuthToSwagger(auth) {
  if (!auth || !auth.type) return null;
  switch (auth.type) {
    case 'apikey': {
      const a = auth.apikey || [];
      const loc = (kv(a, 'in') || 'header').toLowerCase() === 'query' ? 'query' : 'header';
      return { name: 'apiKeyAuth', def: { type: 'apiKey', name: kv(a, 'key') || 'Authorization', in: loc } };
    }
    case 'bearer':
      return { name: 'bearerAuth', def: { type: 'apiKey', name: 'Authorization', in: 'header' } };
    case 'basic':
      return { name: 'basicAuth', def: { type: 'basic' } };
    case 'oauth2': {
      const a = auth.oauth2 || [];
      return { name: 'oauth2Auth', def: { type: 'oauth2', flow: 'accessCode', authorizationUrl: kv(a, 'authUrl') || '', tokenUrl: kv(a, 'accessTokenUrl') || '', scopes: {} } };
    }
    default:
      return null;
  }
}

// Swagger 2.0 requires every response to have a `description`. p2o only sets it from the Postman
// response's `status` (reason phrase); collections that omit `status` yield a description-less
// (invalid) response. Backfill a sensible one so the output always validates.
const REASON = { 200: 'OK', 201: 'Created', 202: 'Accepted', 203: 'Non-Authoritative Information', 204: 'No Content', 206: 'Partial Content', 301: 'Moved Permanently', 302: 'Found', 304: 'Not Modified', 400: 'Bad Request', 401: 'Unauthorized', 403: 'Forbidden', 404: 'Not Found', 405: 'Method Not Allowed', 409: 'Conflict', 422: 'Unprocessable Entity', 429: 'Too Many Requests', 500: 'Internal Server Error', 502: 'Bad Gateway', 503: 'Service Unavailable' };
function fixResponses(sw) {
  for (const path of Object.values(sw.paths || {}))
    for (const op of Object.values(path))
      if (op && typeof op === 'object' && op.responses)
        for (const [code, r] of Object.entries(op.responses))
          if (r && typeof r === 'object' && !r.description) r.description = REASON[code] || 'Response';
}

// Swagger 2.0 requires (a) every path key to start with "/", and (b) every "{token}" in a path to
// have a matching path parameter. p2o sometimes emits neither. Backfill both.
function fixPaths(sw) {
  if (!sw.paths) return;
  const fixed = {};
  for (const [key, item] of Object.entries(sw.paths)) {
    const pathKey = key.startsWith('/') ? key : '/' + key;
    const tokens = [...pathKey.matchAll(/\{([^}]+)\}/g)].map((m) => m[1]);
    if (tokens.length && item && typeof item === 'object') {
      for (const op of Object.values(item)) {
        if (op && typeof op === 'object' && op.responses) {
          op.parameters = op.parameters || [];
          for (const t of tokens)
            if (!op.parameters.some((p) => p.in === 'path' && p.name === t))
              op.parameters.push({ name: t, in: 'path', required: true, type: 'string' });
        }
      }
    }
    fixed[pathKey] = item;
  }
  sw.paths = fixed;
}

// Replace whatever the converter produced with a correct security definition derived from the
// Postman auth (Power Platform picks the single top securityDefinition, so we emit exactly one).
function fixSecurity(sw, auth) {
  const s = pmAuthToSwagger(auth);
  if (s) {
    sw.securityDefinitions = { [s.name]: s.def };
    sw.security = [{ [s.name]: [] }];
  } else {
    if (auth?.type) warnings.push(`auth type "${auth.type}" not mapped — add security manually in the connector`);
    delete sw.securityDefinitions; // never ship an invalid securityDefinitions block
    delete sw.security;
  }
}

// One Postman (sub)collection -> validated Swagger 2.0 object.
function convert(coll, tag, effectiveAuth) {
  const pin = join(work, `${tag}.postman.json`);
  const oas = join(work, `${tag}.oas3.yml`);
  writeFileSync(pin, JSON.stringify(resolveVars(coll, coll.variable?.length ? coll.variable : rootVars)));
  // Show the converters' own warnings/errors (stderr) so a bad collection is debuggable; still
  // capture api-spec-converter's stdout (the Swagger JSON).
  execFileSync('p2o', [pin, '-f', oas], { stdio: ['ignore', 'ignore', 'inherit'] });
  const raw = execFileSync('api-spec-converter', ['--from=openapi_3', '--to=swagger_2', '--syntax=json', oas], { stdio: ['ignore', 'pipe', 'inherit'] });
  const sw = JSON.parse(raw.toString());
  fixPaths(sw);
  fixResponses(sw);
  fixSecurity(sw, effectiveAuth);
  return sw;
}

// Strip verbose example fields (shrinks size; also improves Power Platform compatibility).
function strip(o) {
  if (Array.isArray(o)) o.forEach(strip);
  else if (o && typeof o === 'object') { delete o.example; delete o.examples; for (const k of Object.keys(o)) strip(o[k]); }
  return o;
}

// --- fresh output dir ---
mkdirSync(OUT, { recursive: true });
for (const f of readdirSync(OUT)) if (f.endsWith('.swagger.json')) rmSync(join(OUT, f));

const written = [];
function emit(name, sw) {
  let bytes = sizeOf(sw);
  if (bytes >= LIMIT) { strip(sw); bytes = sizeOf(sw); } // last-ditch shrink for an oversize def
  const file = join(OUT, `${slug(name)}.swagger.json`);
  writeFileSync(file, JSON.stringify(sw, null, 2));
  let valid = true;
  try { execFileSync('swagger-cli', ['validate', file], { stdio: 'pipe' }); }
  catch (err) { valid = false; warnings.push(`validation failed for ${file}: ${(err.stderr?.toString() || err.message || '').trim()}`); }
  written.push({ file, bytes, over: bytes >= LIMIT, valid });
}

// --- convert whole; split only if it wouldn't fit ---
const whole = convert(collection, 'whole', rootAuth);
if (sizeOf(whole) < LIMIT) {
  emit(collection.info?.name || srcName.replace(/\.json$/, ''), whole);
} else {
  const roots = collection.item || [];
  for (const folder of roots.filter((it) => it.item)) {
    const sub = {
      info: { ...collection.info, name: `${collection.info?.name || ''} - ${folder.name}`.trim() },
      variable: rootVars,
      item: folder.item,
    };
    emit(folder.name, convert(sub, slug(folder.name), folder.auth || rootAuth));
  }
  const loose = roots.filter((it) => it.request);
  if (loose.length) {
    const sub = { info: { ...collection.info, name: `${collection.info?.name || ''} - misc` }, variable: rootVars, item: loose };
    emit('misc', convert(sub, 'misc', rootAuth));
  }
}

// --- report ---
for (const w of written) console.log(`${(w.bytes / 1024).toFixed(1)} KB  ${w.file}${w.over ? `  ** OVER ${limitStr} **` : ''}${w.valid ? '' : '  ** INVALID Swagger 2.0 **'}`);
for (const w of [...new Set(warnings)]) console.warn(`warning: ${w}`);
const bad = written.filter((w) => w.over || !w.valid);
if (bad.length) {
  console.error(`\n${bad.length} definition(s) are over ${limitStr} or not valid Swagger 2.0 — split that folder further, trim the collection, or fix the source. See flags above.`);
  process.exit(2);
}
console.log(`\n${written.length} connector definition(s) written to ${OUT}/ — all valid Swagger 2.0, all < ${limitStr}.`);
