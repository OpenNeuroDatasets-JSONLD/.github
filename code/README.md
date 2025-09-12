ATM we are running the beast as 

    for j in openneuro-annotations/ds00*json; do ds=$(basename ${j%.json}); [ -e "$ds" ] && {echo "$ds skip - exists"} || { chronic code/prototype-neurobagel.sh $ds && echo "$ds done"; }; done

while taking annotions from https://github.com/neurobagel/openneuro-annotations

## Matrix Job Processing

The CLI processing has been enhanced to use GitHub Actions matrix strategy for parallel execution:

- **Individual Jobs**: Each dataset is processed as a separate matrix job
- **Parallel Execution**: Multiple datasets are processed simultaneously
- **Status Tracking**: Individual success/failure status for each dataset
- **Status Badges**: Automated generation of status badges for each dataset

See [Dataset Status Badges](../badge_status.md) for current processing status.

## Legacy Batch Processing

And here was the GNU parallel invocation -- needs to have openneuro-annotations already cloned locally:

    for j in openneuro-annotations/ds00*json; do ds=$(basename ${j%.json}); [ -e "$ds" ] && {echo "$ds skip - exists" >&2} || { echo "$ds"; }; done | parallel -j6 --jl parallel.log 'chronic code/prototype-neurobagel.sh {}' ::: 2>&1 | tee parallel.outs

- `chronic` is from [moreutils](https://joeyh.name/code/moreutils/).
- `parallel` is https://www.gnu.org/software/parallel/
- script uses `gh` CLI https://cli.github.com/

Script relies on having following configuration in your ~/.gitconfig

    [url "git@github.com:"]
        pushinsteadOf = https://github.com/
        pushinsteadOf = http://github.com/
        pushInsteadOf = git://github.com/


so you can keep cloning via https:// but pushing via ssh.
