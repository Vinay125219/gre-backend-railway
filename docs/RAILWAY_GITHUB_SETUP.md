# Railway Backend Setup (Beginner, GitHub First)

This guide assumes you are new to Railway and want a safe, step-by-step setup.

## 1. Prerequisites

- GitHub account
- Railway account
- Git installed locally
- Your project folder ready (this repo)

Official references:

- Railway Quick Start: https://docs.railway.com/guides/quick-start
- Railway GitHub Deploys: https://docs.railway.com/guides/github
- Railway Variables: https://docs.railway.com/guides/variables
- Railway Public Domain: https://docs.railway.com/reference/public-networking

## 2. Push This Project To GitHub

Run these commands in your project root:

```bash
git init
git add .
git commit -m "chore: clean workspace and prepare Railway migration"
git branch -M main
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```

If the repository already exists locally, skip `git init` and use your current branch/remote.

## 3. Create Railway Project From GitHub

In Railway dashboard:

1. Click `New Project`.
2. Choose `Empty Project`.
3. Click `+ New` and choose `GitHub Repo`.
4. Select your repository.
5. Confirm deployment.

Railway will trigger deployments from your selected branch.

## 4. Why Your Previous Deploy Failed

Railway detected Node but could not find a start command.

This repo now includes:

- `package.json` with `"start": "node server/index.js"`
- backend entrypoint at `server/index.js`
- health endpoint at `/health`

So Railway can deploy directly from repository root.

## 5. Configure Environment Variables In Railway

In your Railway service:

1. Open `Variables` tab.
2. Add required variables (example):
   - `NODE_ENV=production`
   - `PORT=8080` (optional, Railway injects `PORT` automatically)
   - `CORS_ORIGIN=*` (tighten later to your real frontend domain)

Do not commit real secrets to GitHub.

## 6. Attach a Public Domain

In Railway service:

1. Open `Settings` -> `Networking`.
2. Click `Generate Domain`.
3. Copy the generated URL (example: `https://your-service.up.railway.app`).

You will use this URL as your API base URL in Flutter once backend endpoints are ready.

## 7. Deploy Flow You Will Use Every Time

1. Make backend changes locally.
2. Commit and push to GitHub.
3. Railway auto-deploys from the connected branch.
4. Check Railway deploy logs if anything fails.

## 8. Flutter Integration After Backend Is Live

Current app is in mock mode by design.

After your Railway backend endpoints are ready, we will do these next steps together:

1. Add a new API client layer in Flutter.
2. Add a single `API_BASE_URL` config point.
3. Replace mock repositories feature by feature.
4. Verify login, courses, content, tests, and analytics against Railway.

## 9. Quick Verify Commands

After Railway deploy succeeds, test:

```bash
curl https://<YOUR-RAILWAY-DOMAIN>/health
curl https://<YOUR-RAILWAY-DOMAIN>/api/v1/status
```
