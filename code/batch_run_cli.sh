#!/bin/bash

# Each repo ID to run the CLI on (and their corresponding SHA) is on a separate line
dataset_list=$1

for dataset in $(cat "$dataset_list"); do
    repo=$(echo $dataset | cut -d ',' -f 1)
    sha=$(echo $dataset | cut -d ',' -f 2)

    echo "${repo}: Running the CLI"
    ./run_cli_single_dataset.sh $repo

    # If the CLI did not run successfully, exit loop without updating SHA
    if [ $? -ne 0 ]; then
        echo "${repo}: CLI run failed"
        break
    fi

    # Replace the old SHA with the new one
    echo "${repo}: Updating SHA in file"
    line=$(grep "$repo" sha.txt)
    sed -i "s/${line}/${repo},${sha}/" sha.txt
done
