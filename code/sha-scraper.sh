#!/bin/bash

OWNER="OpenNeuroDatasets-JSONLD"

nRepos=$(gh api graphql -f query='{
    organization(login: "'"${OWNER}"'" ) {
        repositories {
            totalCount
        }
    }
}' | jq -r '.data.organization.repositories.totalCount')
# Return every repository name except .github (because that one is special)
reposON_LD=$(gh repo list "OpenNeuroDatasets-JSONLD" --limit ${nRepos} --json name --jq '.[].name' | grep -v ".github")

# check if sha.txt doesn't exists
#TODO refactor reusable part of the loop into a function
if [ ! -f sha.txt ]; then
    for repo in $reposON_LD; do

        response=$(gh api graphql -f query='query GetDefaultBranch($owner: String!, $name: String!) {
            repository(name: $name, owner: $owner) {
                defaultBranchRef {
                    branchName: na me
                }
            }
        }' -f owner="${OWNER}" -f name="${repo}")

        # delete if not needed
        defaultBranch=$(echo $response | jq -r '.data.repository.defaultBranchRef.branchName')
        # if it doesn't we need to create it and then run the following to populate for the first time
        
        # need to test if the sha we grab here changes with a new commit
        sha=$(curl -L \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer ${GH_PAT}" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            https://api.github.com/repos/${OWNER}/${repo}/commits/ | jq .[0].sha)
        
        echo $repo,$sha >> sha.txt

    done

else
    for repo in $reposON_LD; do

        response=$(gh api graphql -f query='query GetDefaultBranch($owner: String!, $name: String!) {
            repository(name: $name, owner: $owner) {
                defaultBranchRef {
                    branchName: name
                }
            }
        }' -f owner="${OWNER}" -f name="${repo}")

        # delete if not needed
        defaultBranch=$(echo $response | jq -r '.data.repository.defaultBranchRef.branchName')
        # if it doesn't we need to create it and then run the following to populate for the first time
        
        # need to test if the sha we grab here changes with a new commit
        sha=$(curl -L \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer ${GH_PAT}" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            https://api.github.com/repos/${OWNER}/${repo}/commits/ | jq .[0].sha)

        line=$(grep "$repo" sha.txt)
        old_sha=$(echo $line | cut -d, -f2)
        # if the sha is not the same as the old one
        if [ $old_sha != "$sha" ]; then
            #TODO Do CLI thingy

            # check if participants.tsv exists
            participant_tsv_http_code=$(curl -s -o /dev/null -w "%{http_code}" \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer ${GH_PAT}" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            https://api.github.com/repos/${OWNER}/${repo}/contents/participants.tsv)

            # check if participants.json exists
            participant_json_http_code=$(curl -s -o /dev/null -w "%{http_code}" \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer ${GH_PAT}" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            https://api.github.com/repos/${OWNER}/${repo}/contents/participants.json)

            
            if (( ($participant_tsv_http_code > 200 || $participant_tsv_http_code < 300 ) && ($participant_json_http_code > 200 || $participant_json_http_code < 300 ))); then
                ./run-cli-single-dataset.sh $repo

            #replace the old sha with the new one
            sed -i "s/${line}/${repo},${sha}/" sha.txt
        fi

fi

