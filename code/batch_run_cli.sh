#!/bin/bash

# This script accepts a list of repository (dataset) IDs and their corresponding latest SHAs.
# It runs the Neurobagel CLI on each dataset and updates the SHA in sha.txt if the CLI runs successfully.

# A space-separated list where each item is: <repo ID>,<SHA>
dataset_list_path=$1

for dataset in $(cat $dataset_list_path); do
    repo=$(echo $dataset | cut -d ',' -f 1)
    sha=\"$(echo $dataset | cut -d ',' -f 2)\"
    echo "Repo info: $repo,$sha"

    echo "${repo}: Running the CLI"
    ./run_cli_single_dataset.sh $repo

    # Check if the CLI ran successfully
    if [ $? -eq 0 ]; then
        echo "${repo}: CLI ran successfully!"

        line=$(grep "$repo" sha.txt)

        # The following section updates SHAs in sha.txt and is similar to code in sha_scraper.sh.
        # The goal is, for a repo that has *successfully run the CLI*, make sure we now record their most up to date SHA
        # (i.e., to indicate when the last successful CLI run happened).
        # To achieve this:
        # - if the repo DOES already have an entry in sha.txt, we replace (update) the existing SHA with the current SHA
        # - if the repo DOES NOT already have an entry in sha.txt (meaning this is a newly added repo), add the repo and its SHA
        if [ ! -z "$line" ]; then
            echo "${repo}: Updating SHA in file"
            sed -i "s/${line}/${repo},${sha}/" sha.txt
        else
            echo "${repo}: SHA not found, writing latest SHA to file"
            echo $repo,$sha >> sha.txt
        fi
    # If the CLI failed for the repo, we do not update or add an entry to sha.txt so that
    # the next time this script is called, the CLI will be attempted again for that repo.
    else
        echo "${repo}: CLI failed"
    fi
done
