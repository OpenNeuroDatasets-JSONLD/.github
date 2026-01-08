#!/bin/bash
# formerly datalad_get_single_dataset.sh

set -euo pipefail

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

# Run the Neurobagel CLI
bagel pheno \
    --pheno ${workdir}/participants.tsv \
    --dictionary ${workdir}/participants.json \
    --output ${workdir}/pheno.jsonld \
    --dataset_description ${workdir}/nb_dataset_description.json \

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
    if bagel derivatives \
    --jsonld-path ${workdir}/pheno_bids.jsonld \
    --tabular ${np_status} \
    --output  ${workdir}/pheno_derivative.jsonld; then
        cp ${workdir}/pheno_derivative.jsonld ${derivative_jsonld_path}
        # And now we are done
        exit 0
    fi
fi

cp ${workdir}/pheno_bids.jsonld ${bids_jsonld_path}
