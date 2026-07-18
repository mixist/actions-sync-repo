# Sync Repo

GitHub action to synchronize code to other Git platforms (GitLab, Gitee, Codeup, etc.).

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `target-url` | yes | — | Target repo URL |
| `target-username` | yes | — | Target repo username |
| `target-token` | yes | — | Target token |
| `target-force-push` | no | `false` | Force push branches and tags |
| `mirror` | no | `false` | Mirror all refs (branches + tags) and prune refs deleted on the source. Overrides `target-force-push` |
| `only-on-version-change` | no | `false` | Only sync when the `version` field in `version-file` changed across the push |
| `version-file` | no | `package.json` | JSON file whose `version` field is compared |
| `before-ref` | no | `github.event.before` | Git SHA before the push, used to read the previous version |

## Usage

Requires `fetch-depth: 0` so the previous version can be read from history.
Pin to a released tag (e.g. `@v1`) rather than `@main` for reproducible runs.

```yaml
- uses: actions/checkout@v6
  with:
    fetch-depth: 0
- uses: gactions/repo-sync@main
  with:
    target-url: https://codeup.aliyun.com/your/repo.git
    target-username: github
    target-token: ${{ secrets.TARGET_TOKEN }}
    target-force-push: true
    only-on-version-change: true
```

Branches and tags are both pushed. Set `mirror: true` for a faithful mirror that
also prunes refs deleted on the source (inherently forced, so `target-force-push`
does not apply).

When `only-on-version-change` is `true`, the sync is skipped unless the `version`
field in `version-file` differs between the commit before the push and the current
commit. A missing/zero before-ref (first push, force push) is treated as changed.
