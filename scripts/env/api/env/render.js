// coo.ee/env — dynamic renderer (M2)
//
// Pure, testable core: given a list of requested modules, concatenate the
// shell fragments in scripts/env/modules into a single script — exactly what
// the M1 hardcoded `java,android` artifact is, but rendered on demand.
//
// Single source of truth: the ../../modules fragments. No shell is duplicated.

const fs = require("fs");
const path = require("path");

// api/env/render.js -> repo-root modules/  (repo root == this scripts/env tree,
// which is what graduates into the standalone coo-ee-env repo).
const MODULES_DIR = path.join(__dirname, "..", "..", "modules");

// Allowed modules = *.sh fragments that aren't framing (_header/_footer).
function allowedModules() {
  return fs
    .readdirSync(MODULES_DIR)
    .filter((f) => f.endsWith(".sh") && !f.startsWith("_"))
    .map((f) => f.replace(/\.sh$/, ""))
    .sort();
}

function readFragment(name) {
  return fs.readFileSync(path.join(MODULES_DIR, `${name}.sh`), "utf8");
}

// Parse the path segment ("java,android") into a canonical module list:
// trim, drop blanks, dedupe, force `base` first, sort the rest. Canonical
// order means android,java and java,android render identically and share a
// CDN cache entry.
function canonicalize(segment) {
  const requested = String(segment || "")
    .split(",")
    .map((s) => s.trim().toLowerCase())
    .filter(Boolean);
  const rest = [...new Set(requested.filter((m) => m !== "base"))].sort();
  return ["base", ...rest];
}

// render(segment) -> { status, contentType, body, canonical }
function render(segment) {
  const allowed = allowedModules();
  const modules = canonicalize(segment);
  const unknown = modules.filter((m) => m !== "base" && !allowed.includes(m));

  if (unknown.length) {
    return {
      status: 400,
      contentType: "text/plain; charset=utf-8",
      canonical: modules,
      body:
        `# coo.ee/env: unknown module(s): ${unknown.join(", ")}\n` +
        `# available: ${allowed.join(", ")}\n`,
    };
  }

  const parts = [
    readFragment("_header"),
    ...modules.map(readFragment),
    readFragment("_footer"),
  ];

  return {
    status: 200,
    contentType: "text/x-shellscript; charset=utf-8",
    canonical: modules,
    body: parts.join(""),
  };
}

module.exports = { render, canonicalize, allowedModules, MODULES_DIR };
