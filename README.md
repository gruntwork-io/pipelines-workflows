# Gruntwork Pipelines Workflows (Muon Space Fork)

This is a fork of [gruntwork-io/pipelines-workflows](https://github.com/gruntwork-io/pipelines-workflows) customized for Muon Space infrastructure.

## Why This Fork Exists

The upstream Gruntwork workflow has two limitations that this fork addresses:

### 1. Private credentials repo support

The upstream workflow uses `actions/checkout` to clone the credentials repo, which fails for private repos because `GITHUB_TOKEN` is scoped to the triggering repo only.

This fork removes the checkout step and instead references the credentials action directly via `uses: Muon-Space/gruntwork-pipeline-credentials@main`. GitHub's internal action resolution respects the repository [Access setting](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository#allowing-access-to-components-in-a-private-repository), so no extra tokens or deploy keys are needed.

### 2. GitHub Environment support for apply jobs

The upstream workflow does not run jobs within a [GitHub Environment](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment), so the OIDC token's subject claim uses `ref:refs/heads/main` instead of `environment:<name>`. This prevents IAM roles with environment-based trust conditions from being assumed.

This fork enriches the orchestrate output with a GitHub Environment name derived from the working directory path (e.g., `network-inspection/production/unit` -> `network-inspection-production`). Apply jobs run within this environment, adding the `environment:` claim to the OIDC token. Plan jobs run without an environment since they only need read access.

**Convention:** The GitHub Environment name must match the `.gruntwork/` environment label, which follows the pattern `<system>-<environment>` (matching the directory structure `<system>/<environment>/`).

## What Changed

Compared to upstream `v4.10.0`:

- **Removed** `actions/checkout` steps for `pipelines-credentials` (3 occurrences, one per job)
- **Replaced** `uses: ./pipelines-credentials` with `uses: Muon-Space/gruntwork-pipeline-credentials@main` (9 occurrences)
- **Removed** unused `pipelines_credentials_repo` and `pipelines_credentials_ref` inputs
- **Added** post-orchestrate enrichment step that injects `Environment` field into each job
- **Added** `environment:` to `pipelines_execute` job (conditional: apply only)

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
- GitHub Environments must exist in the calling repo matching the `<system>-<environment>` naming convention (e.g., `network-inspection-production`)
- IAM applier roles must have trust policies allowing `repo:<org>/<repo>:environment:<environment-name>`

## Maintenance

When Gruntwork releases a new version of `pipelines-workflows`:

1. Merge upstream changes into this fork
2. Reapply the customizations:
   - Remove credentials checkout steps, update `uses:` references
   - Ensure the enrichment step and environment field are preserved
3. The diff is small and mechanical

## Upstream

- **Forked from:** [gruntwork-io/pipelines-workflows@v4.10.0](https://github.com/gruntwork-io/pipelines-workflows/tree/v4.10.0)
- **Related:** [Muon-Space/gruntwork-pipeline-credentials](https://github.com/Muon-Space/gruntwork-pipeline-credentials)
