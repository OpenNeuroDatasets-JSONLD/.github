#!/bin/bash

# This script fetches all current repos in OpenNeuroDatasets-JSONLD and
# checks if the SHA of the latest commit in each repo has changed.
# If the SHA has changed, the script checks if participants.tsv and participants.json exist in the repo.
# If both files exist, the repo ID and current SHA are added to a list of datasets to run the CLI on.
# If a file needed for the CLI is not found, the script only updates the SHA in sha.txt without doing anything else.

flag="$1"

OWNER="OpenNeuroDatasets-JSONLD"
DATASETS_FOR_CLI_LIMIT=150

# TODO: Refactor out code to get list of repos in the organization, since we reuse this in run_cli_on_all_repos.yml
nRepos=$(gh api graphql -f query='{
    organization(login: "'"${OWNER}"'" ) {
        repositories {
            totalCount
        }
    }
}' | jq -r '.data.organization.repositories.totalCount')
# Return every repository fork name (excluding .github)
# NOTE: The returned repo order will be in order of most recently created/updated
reposON_LD=$(gh repo list "$OWNER" --fork --limit ${nRepos} --json name --jq '.[].name')

do_cli_pheno_files_exist() {
    local repo=$1
    local participant_tsv_response participant_json_response

    # Check if participants.tsv exists
    participant_tsv_response=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GH_TOKEN}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/repos/${OWNER}/${repo}/contents/participants.tsv)

    # check if participants.json exists
    participant_json_response=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GH_TOKEN}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/repos/${OWNER}/${repo}/contents/participants.json)

    if (( ($participant_tsv_response >= 200 && $participant_tsv_response < 300 ) && ($participant_json_response >= 200 && $participant_json_response < 300 ) )); then
        return 0
    else
        return 1
    fi
}

# Make empty file to keep track of repos to run the CLI on
touch repos_for_cli.txt
for repo in $reposON_LD; do
    # Get the SHA of the latest commit in the repo (NOTE: This will always be from the default branch)
    # TODO: Test if the SHA we grab here changes with a new commit
    sha=$(curl -sS -L \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GH_TOKEN}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/repos/${OWNER}/${repo}/commits | jq .[0].sha)

    if [[ "$flag" == "--all-repos" ]]; then
        if [ $(wc -l < repos_for_cli.txt) -eq $DATASETS_FOR_CLI_LIMIT ]; then
            echo "Reached limit of $DATASETS_FOR_CLI_LIMIT datasets in repos_for_cli.txt."
            break
        fi
        # When running the CLI on all repos from scratch, we don't compare the SHAs, 
        # we just check if the repo has been 'seen' before
        if grep -q "$repo" sha.txt; then
            echo "${repo}: Dataset found in sha.txt. Skipping."
        elif grep -q "$repo" failed_cli_datasets.txt; then
            echo "${repo}: Dataset previously failed CLI. Skipping."
        else
            if do_cli_pheno_files_exist "$repo"; then
                echo "${repo}: Adding to job list for CLI"
                echo "${repo},${sha}" >> repos_for_cli.txt
            else
                echo "${repo}: participants.json and/or participants.tsv not found"
                echo "${repo}: Writing latest SHA to file"
                echo "${repo},${sha}" >> sha.txt
            fi
        fi
    else
        # Get the line with the old SHA from sha.txt for the repo
        line=$(grep "$repo" sha.txt)

        # If line with repo SHA is found
        if [ -n "$line" ]; then
            echo "${repo}: SHA found in file"
            old_sha=$(echo $line | cut -d, -f2)
            # if the SHA is not the same as the old one
            if [ "$old_sha" != "$sha" ]; then
                echo "${repo}: latest SHA is different than existing SHA"
                if do_cli_pheno_files_exist "$repo"; then
                    # Add repo ID and current SHA of repo to a list of datasets to run the CLI on
                    echo "${repo}: Adding to job list for CLI"
                    echo "${repo},${sha}" >> repos_for_cli.txt
                else
                    # If files needed for CLI not found, simply replace the old SHA with the new one
                    echo "${repo}: participants.json and/or participants.tsv not found"
                    echo "${repo}: Updating SHA in file"
                    sed -i "s/${line}/${repo},${sha}/" sha.txt
                fi
            fi   
        # If repo not found in sha.txt, add repo to list of datasets to run the CLI on if the required input files are found,
        # otherwise write current SHA to file 
        else
            echo "${repo}: SHA not found"
            if do_cli_pheno_files_exist "$repo"; then
                echo "${repo}: Adding to job list for CLI"
                echo "${repo},${sha}" >> repos_for_cli.txt
            else
                echo "${repo}: participants.json and/or participants.tsv not found"
                echo "${repo}: Writing latest SHA to file"
                echo "${repo},${sha}" >> sha.txt
            fi
        fi
    fi
done
