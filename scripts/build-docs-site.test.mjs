import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const builder = path.join(repoRoot, "scripts", "build-docs-site.mjs");

test("builds exact plain-text labels from escaped heading facts", (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "swabble-docs-test-"));
  const docs = path.join(root, "docs");
  fs.mkdirSync(docs);
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));

  const writeDoc = (name, body) => fs.writeFileSync(path.join(docs, name), body);
  writeDoc("index.md", "# Home\n\nWelcome.\n");
  writeDoc("install.md", "# Install\n\nInstall locally.\n");
  writeDoc("quickstart.md", "# Quickstart\n\nStart locally.\n");
  writeDoc(
    "cli.md",
    [
      "# CLI",
      "",
      "## Normal behavior",
      "",
      "### Use `swabble` with **strong**, *emphasis*, and _underscores_",
      "",
      "## Read [the docs](https://example.com) or <https://example.com>",
      "",
      '### Nested <scr<script>ipt>alert("toc")</scr<script>ipt>',
      "",
    ].join("\n"),
  );

  execFileSync(process.execPath, [builder], { cwd: root });

  const html = fs.readFileSync(path.join(root, "dist", "docs-site", "cli.html"), "utf8");
  const toc = html.match(/<nav class="toc"[\s\S]*?<\/nav>/)?.[0];
  assert.equal(
    toc,
    '<nav class="toc" aria-label="On this page"><h2>On this page</h2>' +
      '<a class="toc-l2" href="#normal-behavior">Normal behavior</a>' +
      '<a class="toc-l3" href="#use-swabble-with-strong-emphasis-and-underscores">' +
      "Use swabble with strong, emphasis, and underscores</a>" +
      '<a class="toc-l2" href="#read-the-docs-https-example-com-or-https-example-com">' +
      "Read the docs or https://example.com</a>" +
      '<a class="toc-l3" href="#nested-scr-script-ipt-alert-toc-scr-script-ipt">' +
      "Nested &lt;scr&lt;script&gt;ipt&gt;alert(&quot;toc&quot;)&lt;/scr&lt;script&gt;ipt&gt;</a></nav>",
  );
});
