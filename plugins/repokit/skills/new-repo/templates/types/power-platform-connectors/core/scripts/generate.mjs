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
const work = mkdtempSync(join(tmpdir(), 'ppc-')); // unique per run; removed on exit / interrupt
const cleanup = () => { try { rmSync(work, { recursive: true, force: true }); } catch { /* best-effort */ } };
process.on('exit', cleanup);
for (const sig of ['SIGINT', 'SIGTERM']) process.on(sig, () => { cleanup(); process.exit(1); });
const warnings = [];
let hadError = false; // set when a (sub)collection fails to convert, so we still exit non-zero

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

// Detect auth set only on individual requests. We map collection/folder-level auth, not per-request
// auth, so without this a request-auth-only collection would ship with no securityDefinitions and no
// warning at all.
function hasRequestAuth(items) {
  for (const it of items || []) {
    if (it?.request?.auth?.type && it.request.auth.type !== 'noauth') return true;
    if (it?.item && hasRequestAuth(it.item)) return true;
  }
  return false;
}

// Pre-resolve collection variables that are set (including "" and "0") so host/basePath come out
// real instead of "%7B%7Bbaseurl%7D%7D". Walk the parsed object and substitute inside string values
// only — safe against values containing quotes/backslashes/newlines (a raw string-replace on the
// serialized JSON could produce invalid JSON).
function resolveVars(obj, vars) {
  if (typeof obj === 'string') {
    let s = obj;
    // Repeat until stable (bounded) so a nested var resolves regardless of its order in vars[]:
    // baseUrl="{{proto}}://host" needs a second pass to also resolve {{proto}}.
    for (let pass = 0; pass < 5 && s.includes('{{'); pass++) {
      const before = s;
      for (const v of vars) if (v && v.key && v.value != null) s = s.split(`{{${v.key}}}`).join(String(v.value));
      if (s === before) break;
    }
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
  if (!auth || !auth.type || auth.type === 'noauth') return null; // noauth = intentional no security
  const attrs = (k) => (Array.isArray(auth[k]) ? auth[k] : []); // v2.0 object-form auth would crash kv()
  switch (auth.type) {
    case 'apikey': {
      const a = attrs('apikey');
      const loc = (kv(a, 'in') || 'header').toLowerCase() === 'query' ? 'query' : 'header';
      return { name: 'apiKeyAuth', def: { type: 'apiKey', name: kv(a, 'key') || 'Authorization', in: loc } };
    }
    case 'bearer':
      return { name: 'bearerAuth', def: { type: 'apiKey', name: 'Authorization', in: 'header' } };
    case 'basic':
      return { name: 'basicAuth', def: { type: 'basic' } };
    case 'oauth2': {
      const a = attrs('oauth2');
      const authorizationUrl = kv(a, 'authUrl');
      const tokenUrl = kv(a, 'accessTokenUrl');
      const grant = (kv(a, 'grant_type') || '').toLowerCase();
      // Pick the Swagger 2.0 oauth2 flow. Prefer Postman's grant_type (substring match — robust to
      // the exact string), else infer from which URLs are present. Emit only the URL(s) that flow
      // requires, verified against the OpenAPI 2.0 spec: implicit->authorizationUrl,
      // password/application->tokenUrl, accessCode->both. (Postman's earlier hardcoded-accessCode
      // path shipped a NO-auth connector for client-credentials/password/implicit grants.)
      let flow;
      if (grant.includes('client')) flow = 'application';
      else if (grant.includes('password')) flow = 'password';
      else if (grant.includes('implicit')) flow = 'implicit';
      else if (grant.includes('authorization') || grant.includes('code')) flow = 'accessCode';
      else if (authorizationUrl && tokenUrl) flow = 'accessCode';
      else if (tokenUrl) flow = 'application';
      else if (authorizationUrl) flow = 'implicit';
      else return null; // no grant_type and no URLs — nothing usable
      const def = { type: 'oauth2', flow, scopes: {} };
      if (flow === 'accessCode' || flow === 'implicit') {
        if (!authorizationUrl) return null;
        def.authorizationUrl = authorizationUrl;
      }
      if (flow === 'accessCode' || flow === 'application' || flow === 'password') {
        if (!tokenUrl) return null;
        def.tokenUrl = tokenUrl;
      }
      return { name: 'oauth2Auth', def };
    }
    default:
      return null;
  }
}

// Swagger 2.0 requires every response to have a `description`. p2o only sets it from the Postman
// response's `status` (reason phrase); collections that omit `status` yield a description-less
// (invalid) response. Backfill a sensible one so the output always validates.
const REASON = { 200: 'OK', 201: 'Created', 202: 'Accepted', 203: 'Non-Authoritative Information', 204: 'No Content', 206: 'Partial Content', 301: 'Moved Permanently', 302: 'Found', 304: 'Not Modified', 400: 'Bad Request', 401: 'Unauthorized', 403: 'Forbidden', 404: 'Not Found', 405: 'Method Not Allowed', 409: 'Conflict', 422: 'Unprocessable Entity', 429: 'Too Many Requests', 500: 'Internal Server Error', 502: 'Bad Gateway', 503: 'Service Unavailable' };
const METHODS = ['get', 'put', 'post', 'delete', 'options', 'head', 'patch'];
function fixResponses(sw) {
  for (const path of Object.values(sw.paths || {})) {
    if (!path || typeof path !== 'object') continue;
    for (const m of METHODS) {
      const op = path[m];
      if (op && typeof op === 'object' && op.responses && typeof op.responses === 'object')
        for (const [code, r] of Object.entries(op.responses))
          if (r && typeof r === 'object' && !r.$ref && !r.description) r.description = REASON[code] || 'Response';
    }
  }
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
      for (const m of METHODS) {
        const op = item[m];
        if (op && typeof op === 'object') {
          if (!Array.isArray(op.parameters)) op.parameters = []; // tolerate a malformed non-array
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
  // Resolve committed {{vars}} in the auth block too — otherwise a variable used as an OAuth URL or
  // an apiKey header name would leak into securityDefinitions literally (and swagger-cli validates
  // with validateFormats:false, so a bad URL would pass silently).
  const s = pmAuthToSwagger(resolveVars(auth, rootVars));
  if (s) {
    sw.securityDefinitions = { [s.name]: s.def };
    sw.security = [{ [s.name]: [] }];
  } else {
    if (auth?.type && auth.type !== 'noauth')
      warnings.push(`auth type "${auth.type}" not fully mapped (missing URL/grant details?) — add security manually in the connector`);
    delete sw.securityDefinitions; // never ship an invalid securityDefinitions block
    delete sw.security;
  }
  // Drop any operation-level security the converter emitted — it points at the old (now replaced
  // or deleted) definition, i.e. a dangling reference. The single root-level security applies to
  // every operation.
  for (const path of Object.values(sw.paths || {})) {
    if (!path || typeof path !== 'object') continue;
    for (const m of METHODS) if (path[m] && typeof path[m] === 'object') delete path[m].security;
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
const usedNames = new Set();
function uniqueSlug(name) {
  const base = slug(name);
  let candidate = base, n = 1;
  while (usedNames.has(candidate)) candidate = `${base}-${++n}`; // avoids cross-collisions with real "…-2" names
  usedNames.add(candidate);
  return candidate;
}
// Report unresolved Postman tokens ({{var}} or its %7b%7b URL-encoding) ONLY in the fields Power
// Platform actually calls: host, basePath, schemes, path keys, and the security URLs / header name.
// A leftover in a description or example doesn't break the connector, so scanning the whole document
// would false-fail on collections that legitimately document a {{var}}. swagger-cli can't catch
// these itself — it validates with validateFormats:false, so an unresolved host or tokenUrl passes.
const TOKEN = /\{\{|%7[bB]%7[bB]/;
function unresolvedFields(sw) {
  const hits = [];
  const chk = (label, val) => { if (typeof val === 'string' && TOKEN.test(val)) hits.push(label); };
  chk('host', sw.host);
  chk('basePath', sw.basePath);
  (Array.isArray(sw.schemes) ? sw.schemes : []).forEach((s, i) => chk(`schemes[${i}]`, s));
  for (const k of Object.keys(sw.paths || {})) chk(`path "${k}"`, k);
  for (const [n, d] of Object.entries(sw.securityDefinitions || {})) {
    chk(`${n}.authorizationUrl`, d?.authorizationUrl);
    chk(`${n}.tokenUrl`, d?.tokenUrl);
    chk(`${n}.name`, d?.name);
  }
  return hits;
}
function emit(name, sw) {
  let bytes = sizeOf(sw);
  if (bytes >= LIMIT) { strip(sw); bytes = sizeOf(sw); } // last-ditch shrink for an oversize def
  const file = join(OUT, `${uniqueSlug(name)}.swagger.json`);
  writeFileSync(file, JSON.stringify(sw, null, 2));
  let valid = true;
  const hits = unresolvedFields(sw);
  const unresolved = hits.length > 0;
  if (unresolved)
    warnings.push(`${file}: unresolved {{variables}} in ${hits.join(', ')} — likely a Postman environment variable not in the committed collection; the connector will not work until these are provided`);
  try { execFileSync('swagger-cli', ['validate', file], { stdio: 'pipe' }); }
  catch (err) { valid = false; warnings.push(`validation failed for ${file}: ${(err.stderr?.toString() || err.message || '').trim()}`); }
  written.push({ file, bytes, over: bytes >= LIMIT, valid, unresolved });
}

// Convert one (sub)collection and emit it; on converter failure, record it and keep going so one
// bad folder doesn't abort the rest of the split (p2o / api-spec-converter throw on any non-zero).
function tryEmit(name, coll, tag, auth) {
  try {
    emit(name, convert(coll, tag, auth));
  } catch (err) {
    hadError = true;
    warnings.push(`"${name}" failed to convert: ${(err.message || err).toString().trim()}`);
  }
}

// H3: auth on individual requests is not mapped — warn rather than silently ship an authless connector.
if (!rootAuth && hasRequestAuth(collection.item)) {
  warnings.push('auth is set per-request in this collection; only collection/folder-level auth is mapped, so the connector(s) have no securityDefinitions — add auth manually after import');
}

// --- convert whole; split only if it *still* wouldn't fit after dropping examples ---
let whole = null, wholeBytes = Infinity;
try {
  whole = convert(collection, 'whole', rootAuth);
  wholeBytes = sizeOf(whole);
  if (wholeBytes >= LIMIT) { strip(whole); wholeBytes = sizeOf(whole); } // try examples-off before splitting
} catch (err) {
  warnings.push(`whole-collection conversion failed (${(err.message || err).toString().trim()}); falling back to per-folder`);
}
if (whole && wholeBytes < LIMIT) {
  emit(collection.info?.name || srcName.replace(/\.json$/, ''), whole);
} else {
  const roots = collection.item || [];
  for (const folder of roots.filter((it) => it && it.item)) {
    const fname = folder.name || 'folder';
    const sub = {
      info: { ...collection.info, name: `${collection.info?.name || ''} - ${fname}`.trim() },
      variable: rootVars,
      auth: folder.auth || rootAuth,
      item: folder.item,
    };
    tryEmit(fname, sub, slug(fname), folder.auth || rootAuth);
  }
  const loose = roots.filter((it) => it && it.request);
  if (loose.length) {
    const sub = { info: { ...collection.info, name: `${collection.info?.name || ''} - misc` }, variable: rootVars, auth: rootAuth, item: loose };
    tryEmit('misc', sub, 'misc', rootAuth);
  }
}

// --- report ---
for (const w of written) console.log(`${(w.bytes / 1024).toFixed(1)} KB  ${w.file}${w.over ? `  ** OVER ${limitStr} **` : ''}${!w.valid ? '  ** INVALID Swagger 2.0 **' : ''}${w.unresolved ? '  ** UNRESOLVED {{variables}} **' : ''}`);
for (const w of [...new Set(warnings)]) console.warn(`warning: ${w}`);
const bad = written.filter((w) => w.over || !w.valid || w.unresolved);
if (bad.length || hadError) {
  console.error(`\n${bad.length + (hadError ? 1 : 0)} problem(s): definitions over ${limitStr}, not valid Swagger 2.0, with unresolved {{variables}}, or a folder that failed to convert — split that folder further, trim the collection, or fix the source. See flags above.`);
  process.exit(2);
}
console.log(`\n${written.length} connector definition(s) written to ${OUT}/ — all valid Swagger 2.0, all < ${limitStr}.`);
