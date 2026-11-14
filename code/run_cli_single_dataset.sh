#!/bin/bash
# formerly datalad_get_single_dataset.sh

set -euo pipefail

# Set datalad logging to ERROR only
export DATALAD_LOG_LEVEL=error

ds_id=$1

# Get the data
ds_repository="https://github.com/OpenNeuroDatasets-JSONLD/${ds_id}.git"
ds_homepage="https://openneuro.org/datasets/${ds_id}"

script_dir="$(dirname "$0")"

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

datalad clone ${ds_repository} ${workdir}
datalad get -d $workdir "${workdir}/participants.tsv"
datalad get -d $workdir "${workdir}/participants.json"
datalad get -d $workdir "${workdir}/dataset_description.json"

# Update the description
python ${script_dir}/update_dataset_description.py ${workdir}/dataset_description.json ${ds_id} ${ds_homepage} ${ds_repository}

# Generate the BIDS metadata table
bagel bids2tsv --bids-dir ${workdir} --output ${workdir}/${ds_id}_bids.tsv --verbosity 0

# Run the Neurobagel CLI

# Disable exit on error temporarily to allow capturing error logs from the CLI
set +e
# NOTE: dataget expects OpenNeuro imaging session paths to be in the format /dsXXXX/sub-XXX/ses-XXX
result=$(bagel create \
    --pheno ${workdir}/participants.tsv \
    --dictionary ${workdir}/participants.json \
    --dataset-description ${workdir}/nb_dataset_description.json \
    --bids-table ${workdir}/${ds_id}_bids.tsv \
    --imaging-source-dir "/${ds_id}" \
    --output ${workdir}/pheno_bids.jsonld \
    --strict \
    --verbosity 0 2>&1)

exit_code=$?
set -e

# We exclude any datasets where BIDS processing failed,
# so all OpenNeuro datasets in the graph have at minimum phenotypic and BIDS information
if [ $exit_code -ne 0 ]; then
    if echo "$result" | grep -iqE "BIDS table|BIDS metadata table"; then
        cp ${workdir}/${ds_id}_bids.tsv ${failed_bids_tsvs}
        echo "Copied BIDS metadata table for failed dataset to ${failed_bids_tsvs}."
    fi
    exit 1
fi

if [ -f ${np_status} ]; then
    if bagel create \
    --pheno ${workdir}/participants.tsv \
    --dictionary ${workdir}/participants.json \
    --dataset-description ${workdir}/nb_dataset_description.json \
    --bids-table ${workdir}/${ds_id}_bids.tsv \
    --imaging-source-dir "/${ds_id}" \
    --processing-status ${np_status} \
    --output  ${workdir}/pheno_derivative.jsonld \
    --verbosity 0; then
        cp ${workdir}/pheno_derivative.jsonld ${derivative_jsonld_path}
        # And now we are done
        exit 0
    fi
fi

cp ${workdir}/pheno_bids.jsonld ${bids_jsonld_path}
