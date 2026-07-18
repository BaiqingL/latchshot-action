# Latchshot Screenshot Action

Capture a public webpage as PNG or JPEG in GitHub Actions without installing or maintaining Chromium in the workflow.

Latchshot runs the bounded browser job, blocks private-network targets, returns render diagnostics, and counts only successful direct renders against quota. It intentionally does not support login sessions, cookies, arbitrary scripts, CAPTCHA solving, proxy rotation, or anti-bot bypass.

## Quick start

1. [Create an instant 100-render trial](https://latchshot.fly.dev/#trial).
2. Add the returned key as a repository secret named `LATCHSHOT_API_KEY`.
3. Add this step to a workflow:

```yaml
- name: Capture public webpage
  id: screenshot
  uses: BaiqingL/latchshot-action@v1
  with:
    api_key: ${{ secrets.LATCHSHOT_API_KEY }}
    url: https://example.com
    output: webpage.png

- uses: actions/upload-artifact@v4
  with:
    name: webpage-capture
    path: ${{ steps.screenshot.outputs.path }}
```

The repository includes a complete [manually triggered workflow](.github/workflows/capture-page.yml).

For the repository-secret setup, artifact outputs, scheduled captures, and the hosted-versus-runner tradeoff, read the [website screenshot GitHub Action guide](https://latchshot.fly.dev/guides/website-screenshot-github-action.html).

## Inputs

| Input | Required | Default | Meaning |
| --- | --- | --- | --- |
| `api_key` | yes | — | Trial or paid key; pass from a GitHub Actions secret |
| `url` | yes | — | Public HTTP or HTTPS webpage URL |
| `output` | no | `latchshot.png` | Output image path |
| `width` | no | `1440` | Viewport width, 320–2560 |
| `height` | no | `900` | Viewport height, 240–1440 |
| `format` | no | `png` | `png` or `jpeg` |
| `full_page` | no | `false` | Bounded full-page capture |
| `dark_mode` | no | `false` | Emulate dark color scheme |

## Outputs

| Output | Meaning |
| --- | --- |
| `path` | Requested output path |
| `render_ms` | Server-side render duration |
| `quota_remaining` | Successful renders remaining this month |
| `navigation` | `complete` or `timed-out` when usable content was still captured |

## Other environments

Dependency-free clients are included for:

- [Node.js 18+](examples/node.mjs)
- [Python 3](examples/python.py)

```sh
export LATCHSHOT_API_KEY='ls_live_replace_me'
node examples/node.mjs 'https://example.com' example.png
python3 examples/python.py 'https://example.com' example.png
```

## Product boundaries

- Public HTTP/HTTPS targets on ports 80 and 443 only.
- Private, loopback, link-local, and special-use destinations are blocked.
- No authenticated pages, cookies, sessions, arbitrary scripts, proxy rotation, CAPTCHA solving, or anti-bot bypass.
- Retry loops are bounded. Treat `400` and `401` as permanent errors.
- This is private-beta software. The published [197/200 supported-page benchmark](https://latchshot.fly.dev/docs.md#beta-evidence-and-boundaries) is engineering evidence, not an SLA.

- Full documentation: <https://latchshot.fly.dev/docs.md>
- URL-to-screenshot guide: <https://latchshot.fly.dev/guides/url-to-screenshot-api.html>
- Service health: <https://latchshot.fly.dev/healthz>

## License

The action and examples in this repository are MIT licensed. The hosted Latchshot service is separate proprietary software governed by its product terms.
