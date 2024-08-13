#!/bin/bash

logs_url="https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
msg="❌ Gruntwork Pipelines was unable to checkout the pipelines-actions repository. Please check to ensure <code>PIPELINES_READ_TOKEN</code> is valid and unexpired. [Learn More](https://docs.gruntwork.io/pipelines/security/machine-users#ci-read-only-user).\n\n[View full logs]($logs_url)"
echo "::error:: $msg"
echo $msg >> "$GITHUB_STEP_SUMMARY"
pull_number=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")
gh pr comment $pull_number -b "$msg" -R $GITHUB_ORG  || true