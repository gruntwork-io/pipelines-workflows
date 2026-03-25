# Gruntwork Pipelines Workflows (Muon Space Fork)

This is a fork of [gruntwork-io/pipelines-workflows](https://github.com/gruntwork-io/pipelines-workflows) with one key change: **private credentials repo support**.

## Why This Fork Exists

The upstream Gruntwork workflow uses `actions/checkout` to clone the credentials repo, which fails for private repos because `GITHUB_TOKEN` is scoped to the triggering repo only.

This fork removes the checkout step and instead references the credentials action directly via `uses: Muon-Space/gruntwork-pipeline-credentials@main`. GitHub's internal action resolution respects the repository [Access setting](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository#allowing-access-to-components-in-a-private-repository), so no extra tokens or deploy keys are needed.

## What Changed

Compared to upstream `v4.10.0`:

- **Removed** `actions/checkout` steps for `pipelines-credentials` (3 occurrences, one per job)
- **Replaced** `uses: ./pipelines-credentials` with `uses: Muon-Space/gruntwork-pipeline-credentials@main` (9 occurrences)
- **Removed** unused `pipelines_credentials_repo` and `pipelines_credentials_ref` inputs

All other workflow logic is unchanged from upstream.

## Usage

In your infra-live repository's workflow:

```yaml
jobs:
  GruntworkPipelines:
    uses: Muon-Space/gruntwork-pipeline-workflows/.github/workflows/pipelines.yml@main
    secrets: inherit
```

## Prerequisites

- [Muon-Space/gruntwork-pipeline-credentials](https://github.com/Muon-Space/gruntwork-pipeline-credentials) must have its Access setting configured to "Accessible from repositories in the 'Muon-Space' organization"
- This repo must also have the same Access setting configured

## Maintenance

When Gruntwork releases a new version of `pipelines-workflows`:

1. Merge upstream changes into this fork
2. Reapply the customization (remove checkout steps, update `uses:` references)
3. The diff is small and mechanical: deletions + string replacements

## Upstream

- **Forked from:** [gruntwork-io/pipelines-workflows@v4.10.0](https://github.com/gruntwork-io/pipelines-workflows/tree/v4.10.0)
- **Related:** [Muon-Space/gruntwork-pipeline-credentials](https://github.com/Muon-Space/gruntwork-pipeline-credentials)
