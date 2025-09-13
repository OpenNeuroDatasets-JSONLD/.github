#!/bin/bash

# formerly datalad_get_single_dataset.sh

ds_id=$1

# Get the data
ds_portal="https://github.com/OpenNeuroDatasets-JSONLD/${ds_id}.git"
ds_git="git@github.com:OpenNeuroDatasets-JSONLD/${ds_id}"

ldin=data
mkdir -p ${ldin}
ldout=${ldin}/jsonld
mkdir -p ${ldout}

# NOTE: realpath is used to get an absolute path of the directory
workdir=$(realpath ${ldin}/${ds_id})
out_jsonld_path="${ldout}/${ds_id}.jsonld"

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
bagel pheno \
    --pheno ${workdir}/participants.tsv \
    --dictionary ${workdir}/participants.json \
    --output ${workdir}/pheno.jsonld \
    --name "$ds_name" \
    --portal $ds_portal

bagel bids2tsv --bids-dir ${workdir} --output ${workdir}/bids.tsv

bagel bids \
    --jsonld-path ${workdir}/pheno.jsonld \
    --bids-table ${workdir}/bids.tsv \
    --dataset-source-dir "/${ds_id}" \  # dataget expects OpenNeuro imaging session paths to be in the format /dsXXXX/sub-XXX/ses-XXX
    --output ${workdir}/pheno_bids.jsonld

cp ${workdir}/pheno_bids.jsonld ${out_jsonld_path}
