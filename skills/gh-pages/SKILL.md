---
name: gh-pages
description: Use when deploying a repository to GitHub Pages from the `main` branch and guiding users to complete required setup in GitHub repository Settings.
---

# GitHub Pages

Deploy repositories to GitHub Pages from the `main` branch, with clear guidance for the required GitHub repository settings.

## When to Use

Use this skill when the user wants to:
- Publish project docs, landing pages, or static assets to GitHub Pages
- Create or fix a `.github/workflows/deploy.yml` for Pages
- Publish from `main` branch using either Actions or branch source
- Troubleshoot common failures such as 404, missing artifact, or permission errors

## Deployment Strategy

Use `main` branch only:

1. **Static site already built in repo**
   - Use branch publishing from `main` (`/docs` or `/root`)
2. **Site needs build step (Vite, Next static export, SSG, etc.)**
   - Use GitHub Actions Pages workflow (recommended default)

When uncertain, prefer the Actions workflow because it is reproducible and CI-driven. For Workflow A, you can set Pages "Build and deployment" to GitHub Actions via `gh api`; for Workflow B, remind the user to use `Settings > Pages`.

## Preflight Checklist

Before configuring deployment:

- Confirm repository visibility and owner (`user` or `org`)
- Confirm default branch is `main`
- Confirm output directory (`dist`, `build`, `out`, `site`, etc.)
- Ensure `Settings > Pages` is available for the repo
- Ensure workflow has required permissions (`pages: write`, `id-token: write`)

## Workflow A: Official Actions Pages Deployment (Recommended)

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: ["main"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Pages
        uses: actions/configure-pages@v5

      # Optional: install deps and run your build
      # - run: npm ci
      # - run: npm run build

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./dist

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

After adding the workflow:

1. Push to default branch
2. Open `Actions` tab and confirm both `build` and `deploy` succeed
3. Set Pages "Build and deployment" to **GitHub Actions** via `gh api`:
   - `gh api -X PUT /repos/<OWNER>/<REPO>/pages -f build_type=workflow`
   - Example (replace `<OWNER>` and `<REPO>` as needed): `gh api -X PUT /repos/yuler/vibe-coding-demo-20260326/pages -f build_type=workflow`

## Workflow B: Branch-Based Static Publishing

Use this when files are already static and committed.

Supported options:
- `main` branch + `/docs` folder
- `main` branch + `/ (root)` folder

Steps:

1. Place published files in selected source location
2. Open `Settings > Pages`
3. Set `Build and deployment` source to **Deploy from a branch**
4. Select branch `main` and target folder, then save
5. Wait for Pages deployment and verify the public URL

## Verification

After setup, verify:

- Workflow or branch deployment shows success
- `Settings > Pages` shows the expected URL
- Site opens without 404
- Asset paths resolve correctly (especially for project pages with subpath base URL)

For project pages (`https://<user>.github.io/<repo>/`), ensure app base path matches `/<repo>/`.

## Common Failures and Fixes

- **404 after successful deploy**
  - Check repository URL type (`user/org` pages vs `project` pages)
  - Check base path and asset URLs
  - Ensure `index.html` exists in deployed artifact root

- **`actions/deploy-pages` permission error**
  - Add `pages: write` and `id-token: write` in workflow `permissions`

- **Deploy job waits forever / environment issue**
  - Ensure deploy job uses environment `github-pages`

- **Uploaded wrong folder**
  - Verify `upload-pages-artifact` `path` points to actual build output

- **No deployment triggered**
  - Confirm workflow trigger branch is `main`

## Practical Notes

- Prefer Actions for most repos; it avoids manual branch publishing drift
- Keep workflow minimal first, then add build caching/optimizations later
- If user only needs a quick static publish, branch publishing is acceptable
