#!/bin/bash

OWNER="OpenNeuroDatasets-JSONLD"

# TODO: Refactor out code to get list of repos in the organization, since we reuse this in run_cli_on_all_repos.yml
nRepos=$(gh api graphql -f query='{
    organization(login: "'"${OWNER}"'" ) {
        repositories {
            totalCount
        }
    }
}' | jq -r '.data.organization.repositories.totalCount')
# Return every repository name except .github (because that one is special)
# We also need to add 1 to number of repos to account for the .github repo
# NOTE: The returned repo order will be in order of most recently created/updated
reposON_LD=$(gh repo list "$OWNER" --limit $((nRepos+1)) --json name --jq '.[].name' | grep -v ".github")

do_cli_pheno_files_exist() {
    local repo=$1
    # Check if participants.tsv exists
    local participant_tsv_response=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${GH_TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/${OWNER}/${repo}/contents/participants.tsv)

    # check if participants.json exists
    local participant_json_response=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${GH_TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/${OWNER}/${repo}/contents/participants.json)

    if (( ($participant_tsv_response >= 200 && $participant_tsv_response < 300 ) && ($participant_json_response >= 200 && $participant_json_response < 300 ) )); then
        echo true
    else
        echo false
    fi
}

# Make empty file to keep track of repos that have changed
touch changed_repos.txt
for repo in $reposON_LD; do
    # Get the SHA of the latest commit in the repo (NOTE: This will always be from the default branch)
    # TODO: Test if the SHA we grab here changes with a new commit
    sha=$(curl -L \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GH_TOKEN}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/repos/${OWNER}/${repo}/commits | jq .[0].sha)

    # Get the line with the old SHA from sha.txt for the repo
    line=$(grep "$repo" sha.txt)

    # If line with repo SHA is found
    if [ ! -z "$line" ]; then
        echo "${repo}: SHA found in file"
        old_sha=$(echo $line | cut -d, -f2)
        # if the SHA is not the same as the old one
        if [ $old_sha != "$sha" ]; then
            echo "${repo}: latest SHA is different than existing SHA"
            if do_cli_pheno_files_exist $repo == true; then
                # Add repo ID and current SHA of repo to a list of datasets to run the CLI on
                echo "${repo}: Adding to job list for CLI"
                echo $repo,$sha >> changed_repos.txt
            else
                # If files needed for CLI not found, simply replace the old SHA with the new one
                echo "${repo}: participants.json and/or participants.tsv not found"
                echo "${repo}: Updating SHA in file"
                sed -i "s/${line}/${repo},${sha}/" sha.txt
            fi
        fi   
    # If repo not found in file, write current SHA to file 
    # and add repo to list of datasets to run the CLI on, if the files needed for the CLI are found
    else
        echo "${repo}: SHA not found"
        
        if do_cli_pheno_files_exist $repo == true; then
            echo "${repo}: Adding to job list for CLI"
            echo $repo,$sha >> changed_repos.txt
        fi

        echo "${repo}: Writing latest SHA to file"
        echo $repo,$sha >> sha.txt
    fi
done
