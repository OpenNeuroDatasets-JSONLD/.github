#!/bin/bash

OWNER="OpenNeuroDatasets-JSONLD"

# TODO: Uncomment once we've confirmed that a few work
# nRepos=$(gh api graphql -f query='{
#     organization(login: "'"${OWNER}"'" ) {
#         repositories {
#             totalCount
#         }
#     }
# }' | jq -r '.data.organization.repositories.totalCount')
# Return every repository name except .github (because that one is special)
nRepos=10
# We need to add 1 to num of repos b/c by default .github will always be first in the list
reposON_LD=$(gh repo list "OpenNeuroDatasets-JSONLD" --limit $((nRepos+1)) --json name --jq '.[].name' | grep -v ".github")

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
            # check if participants.tsv exists
            echo "${repo}: latest SHA is different than existing SHA"
            participant_tsv_http_code=$(curl -s -o /dev/null -w "%{http_code}" \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer ${GH_TOKEN}" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            https://api.github.com/repos/${OWNER}/${repo}/contents/participants.tsv)

            # check if participants.json exists
            participant_json_http_code=$(curl -s -o /dev/null -w "%{http_code}" \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer ${GH_TOKEN}" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            https://api.github.com/repos/${OWNER}/${repo}/contents/participants.json)

            if (( ($participant_tsv_http_code > 200 || $participant_tsv_http_code < 300 ) && ($participant_json_http_code > 200 || $participant_json_http_code < 300 ))); then
                echo "${repo}: running the CLI"
                ./run_cli_single_dataset.sh $repo

                # TODO: Revisit
                # If the CLI did not run successfully, exit loop without updating SHA
                if [ $? -ne 0 ]; then
                    echo "Error occurred while running the CLI for ${repo}"
                    break
                fi
            fi

            # Replace the old SHA with the new one
            echo "${repo}: Updating SHA in file"
            sed -i "s/${line}/${repo},${sha}/" sha.txt
        fi   
    # Otherwise, write current SHA to file
    else
        echo "${repo}: SHA not found, writing latest SHA to file"
        echo $repo,$sha >> sha.txt
    fi
done
