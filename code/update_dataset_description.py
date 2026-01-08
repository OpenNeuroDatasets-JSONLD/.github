"""
Create or update a dataset_description.json with relevant metadata for the CLI.
See: https://neurobagel.org/user_guide/dataset_description/ for reference
"""

import argparse
import json
import logging
from pathlib import Path


logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def main(ds_description_path: Path, ds_id: int, ds_website: str, ds_repos: str):
    """
    Update an existing dataset_description.json file with relevant metadata for the CLI.
    """
    ds_description = json.load(open(ds_description_path))

    # Figure out if ds has a name and if not, set it to ds_id
    ds_name = ds_description.get("Name", "")
    if ds_name.strip() == "":
        ds_name = str(ds_id)

    addition = {
        **ds_description,
        "Name": ds_name,
        "RepositoryURL": ds_repos,
    }

    if not ds_website in ds_description.get("ReferencesAndLinks", []):
        addition = {
            **addition,
            "ReferencesAndLinks": [
                ds_website,
                *ds_description.get("ReferencesAndLinks", []),
            ]
        }

    # Write out new json
    out_path = ds_description_path.parent / "nb_dataset_description.json"
    with open(out_path, "w") as out_file:
        json.dump(addition, out_file, indent=4)

    logger.info(f"Wrote updated dataset_description.json to {out_path}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Create or update a dataset_description.json with relevant metadata for the CLI."
    )
    parser.add_argument(
        "ds_description_path",
        type=Path,
        help="Path to the dataset_description.json file.",
    )
    parser.add_argument(
        "ds_id", type=int, help="The dataset id."
    )
    parser.add_argument(
        "ds_website", type=str, help="The OpenNeuro website for the dataset."
    )
    parser.add_argument(
        "ds_repos", type=str, help="The GH or datalad repo for the dataset."
    )
    args = parser.parse_args()
    main(args.ds_description_path, args.ds_id, args.ds_website, args.ds_repos)
