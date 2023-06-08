ATM we are running the beast as 

    for j in openneuro-annotations/ds00*json; do ds=$(basename ${j%.json}); [ -e "$ds" ] && {echo "$ds skip - exists"} || { chronic ../CON/job/code/prototype-neurobagel.sh $ds && echo "$ds done"; }; done

while taking annotions from https://github.com/neurobagel/openneuro-annotations

And here was the GNU parallel invocation -- needs to have openneuro-annotations already cloned locally:

    for j in openneuro-annotations/ds00*json; do ds=$(basename ${j%.json}); [ -e "$ds" ] && {echo "$ds skip - exists" >&2} || { echo "$ds"; }; done | parallel -j6 --jl parallel.log 'chronic ../CON/job/code/prototype-neurobagel.sh {}' ::: 2>&1 | tee parallel.outs

- `chronic` is from [moreutils](https://joeyh.name/code/moreutils/).
- `parallel` is https://www.gnu.org/software/parallel/
- script uses `gh` CLI https://cli.github.com/
