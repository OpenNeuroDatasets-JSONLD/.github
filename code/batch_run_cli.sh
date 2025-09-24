#!/bin/bash

# This script accepts a list of repository (dataset) IDs and their corresponding latest SHAs.
# It runs the Neurobagel CLI on each dataset and updates the SHA in sha.txt if the CLI runs successfully.

# A space-separated list where each item is: <repo ID>,<SHA>
dataset_list_path=$1

update_sha_file() {
    local repo=$1
    local sha=$2
    local old_repo_sha

    # Look for an existing SHA for the repo in sha.txt
    old_repo_sha=$(grep "$repo" sha.txt)

    # The following section is similar to code in sha_scraper.sh, but instead updates SHAs in sha.txt for
    # each repo that has *successfully run the CLI*, to ensure we now record their most up to date SHA
    # (i.e., to indicate when the last successful CLI run happened).
    # To achieve this:
    # - if the repo DOES already have an entry in sha.txt, we replace (update) the existing SHA with the current SHA
    # - if the repo DOES NOT already have an entry in sha.txt (meaning this is a newly added repo), add the repo and its SHA
    if [ -n "$old_repo_sha" ]; then
        echo "${repo}: Updating SHA in file"
        sed -i "s/${old_repo_sha}/${repo},${sha}/" sha.txt
    else
        echo "${repo}: SHA not found, writing latest SHA to file"
        echo "${repo},${sha}" >> sha.txt
    fi
}

total_datasets=$(wc -l < $dataset_list_path)
count=1
for dataset in $(cat $dataset_list_path); do
    repo=$(echo $dataset | cut -d ',' -f 1)
    sha=\"$(echo $dataset | cut -d ',' -f 2)\"
    echo "($count/$total_datasets) Repo info: $repo,$sha"

    echo "${repo}: Running the CLI"
    cli_output=$(./run_cli_single_dataset.sh $repo)
    cli_exit_code=$?

    # Check if the CLI ran successfully
    if [ $cli_exit_code -eq 0 ]; then
        echo "${repo}: CLI ran successfully!"
        update_sha_file "$repo" "$sha"
    else
        # Look in the error message for substring from 
        # "...must contain at least one column with Neurobagel annotations"
        # to indicate that data dictionary is missing Neurobagel annotations
        # (we use a substring to avoid issues with logs being wrapped)
        if echo "$cli_output" | grep -q "one column with Neurobagel annotations"; then
            echo "${repo}: participants.json is missing Neurobagel annotations. Saving repo ID to temp_datasets_missing_annotations.txt"
            echo "${repo}" >> temp_datasets_missing_annotations.txt
            update_sha_file "$repo" "$sha"
        fi
        # If the CLI failed for the repo and the dataset was annotated, 
        # we do not update or add an entry to sha.txt so that the next time this script is called, 
        # the CLI will be attempted again for that repo.
        echo "${repo}: CLI failed"
        echo "${repo}" >> failed_cli_datasets.txt
    fi

    count=$((count + 1))
done
