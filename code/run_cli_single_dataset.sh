#!/bin/bash

# formerly datalad_get_single_dataset.sh

ds_id=$1

docker pull neurobagel/bagelcli:latest

# Get the data
ds_portal="https://github.com/OpenNeuroDatasets-JSONLD/${ds_id}.git"
ds_git="git@github.com:OpenNeuroDatasets-JSONLD/${ds_id}"

# ldin="inputs/openneuro-jsonld/"
# mkdir -p $ldin
# ldout="outputs/openneuro-jsonld/"
# mkdir -p $ldout


ldin=data
ldout=data/jsonld

# NOTE: realpath is needed to get an absolute path of the directory for mounting, 
# otherwise Docker will error out at the mount step
workdir=$(realpath ${ldin}/${ds_id})

mkdir -p ${ldin}
mkdir -p ${ldout}

out="${ldout}/${ds_id}.jsonld"

datalad clone ${ds_portal} ${workdir}
datalad get -d $workdir "${workdir}/participants.tsv"
datalad get -d $workdir "${workdir}/participants.json"
datalad get -d $workdir "${workdir}/dataset_description.json" # Check if the script will error out if the file doesn't exist

# Get the dataset label
ds_name=$(python extract_bids_dataset_name.py --ds $workdir)
if [ "$ds_name" == "None" ] ; then ds_name=$ds_id ; else ds_name=$ds_name ; fi

# Run the Neurobagel CLI
docker run --rm -v ${workdir}:${workdir} neurobagel/bagelcli pheno --pheno ${workdir}/participants.tsv --dictionary ${workdir}/participants.json --output ${workdir} --name "$ds_name" --portal $ds_portal
docker run --rm -v ${workdir}:${workdir} neurobagel/bagelcli bids --jsonld-path ${workdir}/pheno.jsonld  --bids-dir ${workdir} --output ${workdir}
cp ${workdir}/pheno_bids.jsonld ${out}
