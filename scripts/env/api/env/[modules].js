// Vercel Node serverless function for /env/:modules
//
// Wires the pure renderer to HTTP. The dynamic segment arrives as
// req.query.modules (e.g. "java,android"). See ../../scripts/env/README.md.

const { render } = require("./render");

module.exports = (req, res) => {
  const seg = req.query && req.query.modules ? req.query.modules : "";
  let out;
  try {
    out = render(seg);
  } catch (err) {
    res.statusCode = 500;
    res.setHeader("content-type", "text/plain; charset=utf-8");
    res.end(`# coo.ee/env: render error: ${err.message}\n`);
    return;
  }

  res.statusCode = out.status;
  res.setHeader("content-type", out.contentType);
  // Canonical form is deterministic, so it caches well at the CDN edge.
  if (out.status === 200) {
    res.setHeader("cache-control", "public, max-age=300, s-maxage=86400");
    res.setHeader("x-cooee-modules", out.canonical.join(","));
  }
  res.end(out.body);
};
