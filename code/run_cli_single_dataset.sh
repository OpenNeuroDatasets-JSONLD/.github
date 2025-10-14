#!/bin/bash
# formerly datalad_get_single_dataset.sh

set -euo pipefail

ds_id=$1

# Get the data
ds_portal="https://github.com/OpenNeuroDatasets-JSONLD/${ds_id}.git"

ldin=data
ldout=${ldin}/jsonld
failed_bids_tsvs=${ldin}/failed_bids_tsv
mkdir -p ${ldin}
mkdir -p ${ldout}
mkdir -p ${failed_bids_tsvs}

# NOTE: realpath is used to get an absolute path of the directory
workdir=$(realpath ${ldin}/${ds_id})
bids_jsonld_path="${ldout}/${ds_id}_bids.jsonld"
np_status="${workdir}/../../../openneuro-annotations/processing_status_files/${ds_id}.tsv"
derivative_jsonld_path="${ldout}/${ds_id}_derivative.jsonld"

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

bagel bids2tsv --bids-dir ${workdir} --output ${workdir}/${ds_id}_bids.tsv

# NOTE: dataget expects OpenNeuro imaging session paths to be in the format /dsXXXX/sub-XXX/ses-XXX
if ! bagel bids \
    --jsonld-path ${workdir}/pheno.jsonld \
    --bids-table ${workdir}/${ds_id}_bids.tsv \
    --dataset-source-dir "/${ds_id}" \
    --output ${workdir}/pheno_bids.jsonld; then

    cp ${workdir}/${ds_id}_bids.tsv ${failed_bids_tsvs}
    echo "Moved BIDS metadata table for failed dataset to ${failed_bids_tsvs}."
    exit 1
fi

if [ -f ${np_status} ]; then
    if ! bagel derivatives \
    --jsonld-path ${workdir}/pheno_bids.jsonld \
    --tabular ${np_status} \
    --output  ${workdir}/pheno_derivative.jsonld; then
        :
    else
        cp ${workdir}/pheno_derivative.jsonld ${derivative_jsonld_path}
        # And now we are done
        exit 0
    fi
fi

cp ${workdir}/pheno_bids.jsonld ${bids_jsonld_path}
