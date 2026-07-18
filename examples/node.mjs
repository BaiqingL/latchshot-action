import { writeFile } from 'node:fs/promises';

const apiKey = process.env.LATCHSHOT_API_KEY;
const targetUrl = process.argv[2] || 'https://example.com';
const outputPath = process.argv[3] || 'latchshot.png';

if (!apiKey) throw new Error('Set LATCHSHOT_API_KEY to your trial or paid key.');

const retryable = new Set([429, 502, 503, 504]);

function retryDelay(response, attempt) {
  const retryAfter = Number.parseInt(response.headers.get('retry-after') || '', 10);
  return Number.isFinite(retryAfter) ? Math.min(retryAfter * 1000, 10_000) : 500 * (2 ** attempt);
}

async function render(input, retries = 2) {
  for (let attempt = 0; ; attempt += 1) {
    let response;
    try {
      response = await fetch('https://latchshot.fly.dev/v1/render', {
        method: 'POST',
        headers: {
          authorization: `Bearer ${apiKey}`,
          'content-type': 'application/json',
        },
        body: JSON.stringify(input),
        signal: AbortSignal.timeout(45_000),
      });
    } catch (error) {
      if (attempt >= retries) throw error;
      await new Promise((resolve) => setTimeout(resolve, 500 * (2 ** attempt)));
      continue;
    }

    if (response.ok) return response;
    if (attempt < retries && retryable.has(response.status)) {
      await response.body?.cancel();
      await new Promise((resolve) => setTimeout(resolve, retryDelay(response, attempt)));
      continue;
    }
    throw new Error(`Latchshot ${response.status}: ${await response.text()}`);
  }
}

const response = await render({
  url: targetUrl,
  kind: 'screenshot',
  format: 'png',
  width: 1440,
  height: 900,
});

const bytes = Buffer.from(await response.arrayBuffer());
await writeFile(outputPath, bytes);
console.log(JSON.stringify({
  outputPath,
  bytes: bytes.length,
  contentType: response.headers.get('content-type'),
  renderMs: response.headers.get('x-latchshot-render-ms'),
  remaining: response.headers.get('x-quota-remaining'),
}));
