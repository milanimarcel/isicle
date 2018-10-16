from os.path import *
from isicle.utils import getOS
from pkg_resources import resource_filename


# snakemake configuration
include: 'adducts.snakefile'
IMPACT = resource_filename('isicle', 'resources/IMPACT/%s/impact' % getOS())


rule impact:
    input:
        rules.generateAdduct.output.xyz
    output:
        join(config['path'], 'output', 'mobility', 'impact', 'runs', '{id}_{adduct}.txt')
    version:
        '{IMPACT} -version -nocite'
    log:
        join(config['path'], 'output', 'mobility', 'impact', 'runs', 'logs', '{id}_{adduct}.log')
    benchmark:
        join(config['path'], 'output', 'mobility', 'impact', 'runs', 'benchmarks', '{id}_{adduct}.benchmark')
    # group:
    #     'mobility_alt'
    shell:
        # run impact on adducts
        'IMPACT_RANDSEED={config[impact][seed]} {IMPACT} {input} -o {output} -H \
         -shotsPerRot {config[impact][shotsPerRot]} -convergence {config[impact][convergence]} \
         -nRuns {config[impact][nRuns]} -nocite &> {log}'


rule postprocess:
    input:
        ccs = rules.impact.output,
        mass = rules.calculateMass.output
    output:
        he = join(config['path'], 'output', 'mobility', 'impact', 'ccs', '{id}_{adduct}.He.ccs'),
        n2 = join(config['path'], 'output', 'mobility', 'impact', 'ccs', '{id}_{adduct}.N2.ccs')
    version:
        'python -m isicle.scripts.parse_impact --version'
    log:
        join(config['path'], 'output', 'mobility', 'impact', 'ccs', 'logs', '{id}_{adduct}.benchmark')
    benchmark:
        join(config['path'], 'output', 'mobility', 'impact', 'ccs', 'benchmarks', '{id}_{adduct}.benchmark')
    # group:
    #     'mobility_alt'
    shell:
        'python -m isicle.scripts.parse_impact {input.ccs} {input.mass} {output.he} {output.n2} \
         --alpha {config[ccs][alpha]} --beta {config[ccs][beta]} &> {log}'

# # for report
# ID, adduct = splitext(basename(f))[0].rsplit('_', 1)
# mass = read_mass([x for x in input.mass if ID in x][0])
# formula = read_string([x for x in input.formula if ID in x][0])
# inchi = read_string([x for x in input.inchi if ID in x][0])
# p_inchi = read_string([x for x in input.p_inchi if ID in x][0])

# df = pd.DataFrame(data=[[ID, adduct, inchi, formula, mass, p_inchi, ccs]],
#                   columns=['ID', 'Adduct', 'Parent InChI', 'Parent Formula',
#                            'Parent Mass', 'Processed InChI', 'CCS_He'])