---
name: crawl-x
description: Extract tweet/post text and long-form article content from X/Twitter status URLs and save it as Markdown. Use when the user provides an `x.com` or `twitter.com` status link and wants the tweet body, article body, author metadata, or media links captured locally without browser login.
allowed-tools: Bash,Write
---

# Crawl X

Extract content from X/Twitter status URLs through public mirror APIs such as `api.fxtwitter.com`, then save either tweet text or X Article content as readable Markdown.

## When to Use

Use this skill when the user:
- Provides an `x.com/.../status/...` or `twitter.com/.../status/...` URL
- Wants tweet or article content saved locally
- Needs author, publish date, source URL, or media links preserved
- Wants content forwarded later to another tool or platform

## Quick Workflow

1. Parse the username and status ID from the URL.
2. Run the helper script in `scripts/extract-x.sh`.
3. Let the script fetch the mirror API response and render either tweet text or article blocks.
4. Save the result as Markdown with metadata.
5. Show the saved filename and preview the first 10 lines.

## Recommended Command

Run the bundled helper script:

```bash
bash scripts/extract-x.sh "https://x.com/plantegg/status/2032002697331949891"
```

## Script

- Main helper: `scripts/extract-x.sh`
- Renderer: `scripts/extract-x.ts`
- Input: one X/Twitter status URL
- Output: one Markdown file in the current working directory
- Behavior: the shell script fetches mirror API JSON, then the TypeScript script renders Markdown output through Bun for either tweets or articles
- Fallback: tries `api.fxtwitter.com` first and then `api.vxtwitter.com`

## Output Format

The Markdown file should include:
- Title derived from the article title or tweet text
- Author name and handle
- Publish date
- Original post URL
- Tweet body or article body
- Media URLs when available

## Fallbacks

If `api.fxtwitter.com` fails, try:
- `https://api.vxtwitter.com/<username>/status/<status_id>`

Stop and report the issue if:
- The post is private, deleted, or region-restricted
- The mirror API returns invalid JSON
- The extracted body is empty

## Requirements

- `curl`
- `bun`
- UTF-8 terminal environment for non-ASCII output

## Compatibility

- Supports regular tweets/posts that only contain post text
- Supports X Articles attached to a status
- Uses the same workflow for both content types

## Best Practices

- Always confirm the saved filename with the user.
- Always show a short preview after extraction.
- Preserve the source URL in the output file.
- Include media links even if media files are not downloaded.
- Suggest sending the saved file with `system-macro` only after extraction succeeds.

## Example

```bash
bash scripts/extract-x.sh "https://x.com/plantegg/status/2032002697331949891"
Saved to: Jack-Ma-Is-Back.md
```
