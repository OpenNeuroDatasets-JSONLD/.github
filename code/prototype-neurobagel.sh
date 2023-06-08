#!/bin/bash

set -eux

# to prevent git asking a password whenever it is "too early"
export GIT_ASKPASS=/bin/echo

neurobagel_annotations=openneuro-annotations


code_path=$(readlink -f $0 | xargs dirname)

# TODO: replace with the variables
upstream_remote_name=upstream  # could be openneuro to be more descriptive
orig_org=OpenNeuroDatasets
our_org=$orig_org-JSONLD

ds="$1"

repo_exists(){
    #response=$(curl -s -o /dev/null -w "%{http_code}" "https://api.github.com/repos/$1")
    # we better do authenticated one via gh
    response=$(gh api --include --silent repos/$1 2>/dev/null | head -n1 | awk '{print $2}')
    case "$response" in
      404)
        return 1;;
      200)
        return 0;;
      *)
        echo "Unknown response upon check: $response"
        return $response ;;
    esac
}

try(){
    n=$1
    sl=$2
    shift
    shift
    i=0
    while ! "$@"; do
        echo "It seems we need to wait";
        i+=0
        if [ ${#i} -gt $n ]; then
            echo "Waited $n iterations but still failing!"
            exit 1
        fi
        sleep $sl
    done
}

# Once

# TODO: may be later make into submodule and just do proper upgrades etc
if [ ! -e openneuro-annotations ]; then
    git clone https://github.com/neurobagel/openneuro-annotations
fi

if [ ! -e $ds ]; then
(
# 1. fork https://github.com/OpenNeuroDatasets to https://github.com/OpenNeuroDatasets-JSONLD
set +e
repo_exists "OpenNeuroDatasets-JSONLD/$ds" 
case $? in
  1)
    try 10 5 gh repo fork --org OpenNeuroDatasets-JSONLD OpenNeuroDatasets/$ds --clone=false;;
  0)
    ;;
  *)
    echo "Unknown response upon check: $response"
    exit 1 ;;
esac
set -e
git clone https://github.com/OpenNeuroDatasets/$ds
)
fi

# Add our remote
(
cd $ds
if ! git remote | grep -q jsonld; then 
    try 10 1 git remote add --fetch jsonld https://github.com/OpenNeuroDatasets-JSONLD/$ds
fi
)


# Every time
(
cd $ds

# could be main or master!
branch=$(sed -e 's,.*/,,g' .git/HEAD)
# in openneuro only main or master
if ! echo $branch | grep -e main -e master -q; then
    echo "Branch $branch is neither master nor main"
    exit 1
fi

# Update our jsonld fork, to be done regularly
git fetch origin
if [ ! -e .git/refs/heads/upstream/$branch ]; then
    # TODO: just update-ref, no need for checkout
    git checkout -b upstream/$branch --track origin/$branch
    if [ ! -e .git/refs/heads/jsonld/upstream/$branch ] || git diff upstream/$branch^..jsonld/upstream/$branch | grep -q .; then
        git push -u jsonld upstream/$branch
    fi
else
    git checkout upstream/$branch
    # may be not --ff-only -- may be just  reset --hard.
    # For now get alerted when isn't possible
    git merge --ff-only origin/$branch
    git push jsonld upstream/$branch
fi

# KISS attempt #1: just embed results from the neurobagel tool which were
# pre-generated Because Yarik made "origin" to be original organization repo
# and not our clone
# and then made clone from it, its $branch started to follow the original
# organization instead of our clone.  So when we do checkout $branch here
# even if we pull, we would not get our clone $branch. SO we workaround for now
git checkout $branch
git pull --ff-only jsonld $branch

# We need to update to the state of the upstream/$branch entirely, and only enhance one file
git merge -s ours --no-commit upstream/$branch && git read-tree -m -u upstream/$branch
# Run our super command
if [ -e participants.json ]; then
    action="Updated"
else
    action="Added"
fi

$code_path/update_json participants.json $neurobagel_annotations/${ds}.json
git add .
if [ -z "$(git status --porcelain)" ]; then
    echo "Clean -- no changes, boring"
else
    git commit -m "$action participants.json with Annotations for NeuroBagel"
    git push jsonld $branch
fi
)
