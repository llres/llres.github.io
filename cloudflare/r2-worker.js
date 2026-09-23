/**
 * 落落资源站 · Cloudflare R2 Worker
 *
 * 在 Cloudflare Workers 中绑定一个 R2 Bucket：
 * 变量名：BUCKET
 *
 * 路由：
 * GET /list?prefix=xxx   -> 当前目录列表
 * GET /file/xxx          -> 文件下载/在线播放
 *
 * 默认不允许浏览器直接访问 R2，文件由 Worker 转发。
 */
const ALLOWED_ORIGIN = "https://llres.github.io";

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const origin = request.headers.get("Origin") || "";
    const headers = {
      "Access-Control-Allow-Origin": origin === ALLOWED_ORIGIN ? ALLOWED_ORIGIN : ALLOWED_ORIGIN,
      "Access-Control-Allow-Methods": "GET,HEAD,OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type,Range",
      "Access-Control-Expose-Headers": "Content-Length,Content-Range,Accept-Ranges,Content-Type"
    };

    if (request.method === "OPTIONS") return new Response(null, { status: 204, headers });

    if (url.pathname === "/list") {
      const prefix = (url.searchParams.get("prefix") || "").replace(/^\/+|\.\./g, "");
      const result = await listDirectory(env.BUCKET, prefix);
      return new Response(JSON.stringify(result), {
        headers: { ...headers, "Content-Type": "application/json; charset=utf-8", "Cache-Control": "public, max-age=60" }
      });
    }

    if (url.pathname.startsWith("/file/")) {
      const key = decodeURIComponent(url.pathname.slice(6)).replace(/^\/+|\.\./g, "");
      if (!key) return new Response("Not Found", { status: 404, headers });

      const object = await env.BUCKET.get(key, {
        range: request.headers,
        onlyIf: request.headers
      });
      if (!object) return new Response("Not Found", { status: 404, headers });

      const h = new Headers(headers);
      object.writeHttpMetadata(h);
      h.set("etag", object.httpEtag);
      h.set("Cache-Control", "public, max-age=3600");
      if (object.range) {
        h.set("Accept-Ranges", "bytes");
        h.set("Content-Range", `bytes ${object.range.offset}-${object.range.offset + object.range.length - 1}/${object.size}`);
      }
      return new Response(object.body, { status: object.range ? 206 : 200, headers: h });
    }

    return new Response("落落资源站 R2 API", { headers: { ...headers, "Content-Type": "text/plain; charset=utf-8" } });
  }
};

async function listDirectory(bucket, prefix) {
  const normalized = prefix ? prefix.replace(/\/+$/, "") + "/" : "";
  const listed = await bucket.list({ prefix: normalized, delimiter: "/" });
  const folders = (listed.delimitedPrefixes || []).map(p => {
    const name = p.slice(normalized.length).replace(/\/$/, "");
    return { name, path: normalized + name, type: "dir", size: 0, download_url: "" };
  });

  const files = (listed.objects || []).map(o => ({
    name: o.key.slice(normalized.length),
    path: o.key,
    type: "file",
    size: o.size,
    download_url: fileUrl(o.key)
  })).filter(x => x.name);

  return [...folders, ...files];
}

function fileUrl(key) {
  // Worker 页面部署在同一域名时使用相对路径；资源库会把它拼成绝对 URL。
  return `/file/${key.split("/").map(encodeURIComponent).join("/")}`;
}
