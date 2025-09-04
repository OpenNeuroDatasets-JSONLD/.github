#!/bin/bash

# formerly datalad_get_single_dataset.sh

ds_id=$1

docker pull neurobagel/bagelcli:v0.6.0

# Get the data
ds_portal="https://github.com/OpenNeuroDatasets-JSONLD/${ds_id}.git"
ds_git="git@github.com:OpenNeuroDatasets-JSONLD/${ds_id}"

ldin=data
mkdir -p ${ldin}
ldout=${ldin}/jsonld
mkdir -p ${ldout}

# NOTE: realpath is needed to get an absolute path of the directory for mounting, 
# otherwise Docker will error out at the mount step
workdir=$(realpath ${ldin}/${ds_id})
out="${ldout}/${ds_id}.jsonld"

datalad clone ${ds_portal} ${workdir}
datalad get -d $workdir "${workdir}/participants.tsv"
datalad get -d $workdir "${workdir}/participants.json"
datalad get -d $workdir "${workdir}/dataset_description.json"

# Get the dataset label
ds_name=$(cat ${workdir}/dataset_description.json 2>/dev/null | jq .Name)

# Strip the leading and trailing quotes (") from the ds_name, which are preserved by default when using jq
ds_name=${ds_name#\"}
ds_name=${ds_name%\"}

# Catches the cases where:
# - the dataset_description.json does not exist
# - the "Name" field does not exist
# - the "Name" field is an empty string "" or contains only whitespace characters (spaces, tabs, newlines, such as " ")
# and sets the dataset name to the dataset ID in those cases
if [ -z "$ds_name" ] || [ "$ds_name" == "null" ] || [[ "$ds_name" =~ ^[[:space:]]*$ ]]; then
    ds_name=$ds_id
fi

# Run the Neurobagel CLI
docker run --rm -v ${workdir}:${workdir} neurobagel/bagelcli pheno --pheno ${workdir}/participants.tsv --dictionary ${workdir}/participants.json --output ${workdir}/pheno.jsonld --name "$ds_name" --portal $ds_portal
docker run --rm -v ${workdir}:${workdir} neurobagel/bagelcli bids --jsonld-path ${workdir}/pheno.jsonld  --bids-dir ${workdir} --output ${workdir}/pheno_bids.jsonld
cp ${workdir}/pheno_bids.jsonld ${out}
