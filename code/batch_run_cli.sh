#!/bin/bash

# A space-separated list where each item is: <repo ID>,"<SHA>"
dataset_list_path=$1

for dataset in $(cat $dataset_list_path); do
    echo "Repo: $dataset"
    repo=$(echo $dataset | cut -d ',' -f 1)
    sha=$(echo $dataset | cut -d ',' -f 2)

    echo "${repo}: Running the CLI"
    ./run_cli_single_dataset.sh $repo

    # If the CLI did not run successfully, exit loop without updating SHA
    if [ $? -eq 0 ]; then
        # Replace the old SHA with the new one
        echo "${repo}: Updating SHA in file"
        line=$(grep "$repo" sha.txt)
        sed -i "s/${line}/${repo},${sha}/" sha.txt
    else
        echo "${repo}: CLI failed"
    fi
done
