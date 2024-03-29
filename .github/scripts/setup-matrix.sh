#!/usr/bin/env bash

# This script is used to prepare the relevant outputs required to run the 2nd and 3rd jobs of the
# apply-new-sdlc-accounts-baseline.yml workflow.

# The most important output it creates
# is the `env_ids`, which needs to be determined here for the next job to start with a matrix
# of all the environment ids. This has to be done before the next job starts, as GitHub workflows require
# a static string to be used to define the elements of a matrix. By creating a JSON string representing the
# array of environments to be used in the matrix, we can then use the `fromJSON` function in the next job
# to convert the string into an array of environment ids.

# The rest of the outputs are just convenience outputs to avoid having to repeat the same logic in each
# iteration of the matrix.

set -euo pipefail
IFS=$'\n\t'

# Required environment variables

# A JSON string representing the team account data for the team account that is being created.
: "${TEAM_ACCOUNT_DATA:? TEAM_ACCOUNT_DATA is a required environment variable}"

# The path to the infra-live repo. The infra-live repo is inspected to determine the list of environments
# that need to be created, along with some other metadata about the account creation request.
: "${PATH_TO_INFRA_LIVE:? PATH_TO_INFRA_LIVE is a required environment variable}"

get_env_ids() {
    readonly path_to_infra_live="$1"
    readonly gruntwork_config_path="${path_to_infra_live}/.gruntwork/config.yml"
    readonly account_type="$2"

    local path=''

    case "$account_type" in
    'sdlc')
        path='.pipelines.account-vending.sdlc.account-identifiers'
        ;;
    'sandbox')
        path='.pipelines.account-vending.sandbox.account-identifiers'
        ;;
    *)
        echo "Account type '$account_type' is not recognised. Exiting."
        exit 1
        ;;
    esac

    yq --no-colors -o=json -I=0 "$path" "$gruntwork_config_path"
}

first_account_key="$(jq '. | keys[] | select(. | endswith("AccountName"))' <<< "$TEAM_ACCOUNT_DATA" | jq -s -r '.[0]')"
first_account_name="$(jq -r --arg first_account_key "$first_account_key" '.[$first_account_key]' <<< "$TEAM_ACCOUNT_DATA")"

request_file_path="${PATH_TO_INFRA_LIVE}/_new-account-requests/account-${first_account_name}.yml"
requesting_team_name="$(yq -r '.requesting_team_name' "$request_file_path")"
requesting_team_id="$(yq -r '.requesting_team_id' "$request_file_path")"
account_type="$(yq -r '.account_type' "$request_file_path")"

org_name_prefix="$(yq -r '.org_name_prefix' "$request_file_path")"
aws_region="$(yq -r '.aws_region' "$request_file_path")"
tags="$(yq -o=json -I=0 '.tags' "$request_file_path")"

full_team_name="${requesting_team_name}-${requesting_team_id}"
new_infra_live_repo_name="infra-live-${full_team_name}"

env_ids="$(get_env_ids "$PATH_TO_INFRA_LIVE" "$account_type")"

if [[ $env_ids == 'null' || "$(jq '. | length' <<< "$env_ids")" == '0' ]]; then
    echo "No environments found in the infra-live repo. Exiting."
    exit 1
fi

create_vpc="$(yq -r '.create_vpc' "$request_file_path")"

# This handles the edge case where the create_vpc field is not set in the account creation request.
# If so, we'll default to creating a VPC.
if [[ $create_vpc == 'null' ]]; then
    create_vpc='true'
fi

delegate_management="$(yq -r '.delegate_management // false' "$request_file_path")"
readonly delegate_management
delegate_repo_name="$(yq -r '.delegate_repo_name // ""' "$request_file_path")"
readonly delegate_repo_name

get_catalog_repositories() {
    local -r path_to_infra_live="$1"
    local -r gruntwork_config_path="${path_to_infra_live}/.gruntwork/config.yml"
    local -r account_type="$2"

    local -r path=".pipelines.account-vending.${account_type}.catalog-repositories"

    if [[ "$(yq "$path" "$gruntwork_config_path")" == null ]]; then
        echo "[]"
    else
        yq --no-colors -o=json -I=0 "$path" "$gruntwork_config_path"
    fi
}

account_type="$(yq -r '.account_type' "$request_file_path")"
readonly account_type
catalog_repositories="$(get_catalog_repositories "$PATH_TO_INFRA_LIVE" "$account_type")"
readonly catalog_repositories

# Outputs required in subsequent steps in the workflow in order create the new team's infrastructure-live repo
{
    echo "delegate_management=$delegate_management"
    echo "delegate_repo_name=$delegate_repo_name"
    echo "catalog_repositories=$catalog_repositories"
    echo "full_team_name=$full_team_name"
    echo "new_infra_live_repo_name=$new_infra_live_repo_name"
    echo "org_name_prefix=$org_name_prefix"
    echo "aws_region=$aws_region"
    echo "tags=$tags"
    echo "env_ids=$env_ids"
    echo "create_vpc=$create_vpc"
} >>"$GITHUB_OUTPUT"
