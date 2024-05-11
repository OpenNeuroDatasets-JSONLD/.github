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

    # If the CLI did not run successfully, exit loop without updating SHA
    if [ $? -eq 0 ]; then
        # Replace the old SHA with the new one
        echo "${repo}: CLI ran successfully!"

        line=$(grep "$repo" sha.txt)
        # TODO: Check if we need this section?
        # Prevents wf from exiting if the repo does not already exist in sha.txt (sed error)
        if [ ! -z "$line" ]; then
            echo "${repo}: Updating SHA in file"
            sed -i "s/${line}/${repo},${sha}/" sha.txt
        else
            echo "${repo}: SHA not found, writing latest SHA to file"
            echo $repo,$sha >> sha.txt
        fi
    else
        echo "${repo}: CLI failed"
    fi
done
