## HOWTO

1. Run `1-telechargement-donnees.r` to save all required datasets to `donnees`.
2. Run `2-preparation-donnees.r` to process all datasets.
3. Run `3-selection-bureaux.r` to get the _bureaux_ classified.

Processed datasets and final results will be saved into `sorties`, including a summary map of the top 5 representative clusters in each class:

![](sorties/resultats-CAH-Lille.png)
![](sorties/resultats-CAH-Grenoble.png)

## Changes from Tristan's code

Mostly notes to self:

- automated all required data downloads
- automated all package installs
- updated [`spReapportion`][spReapportion] to [`sfReapportion`][sfReapportion]
- most data saved in, and read from, zipped archives, to save disk space
- code rewritten in order to allow easier re-use with other cities
- edited column selection within Insee files to avoid a few duplicates
- corrected a typo that created very slightly incorrect results (_bureau_ 901)
- visualization of the final results

The code has less package dependencies and works without having to install some retired packages that were required by [`spReapportion`][spReapportion].

[spReapportion]: https://github.com/joelgombin/spReapportion
[sfReapportion]: https://github.com/briatte/sfReapportion

## Data sources

- Insee, [Proposition de contours des bureaux de vote][contours-bv], 2023
- Insee, [Contours... IRIS®][contours-iris], 2019
- Insee, Recensement de la population - Base infracommunale (IRIS), 2019
  - [Activité des résidents][actifs]
  - [Population][population]
  - [Diplômes - Formation][diplome-formation]
  - [Logement][logement]
  <!-- - [Couples - Familles - Ménages][menages] -->
- Ministère de l'Intérieur, [Résultats des élections européennes du 9 juin 2024][eur24]
- Ministère de l'Intérieur, [Election présidentielle des 10 et 24 avril 2022 - Résultats définitifs du 1er tour][prt122]

[contours-bv]: https://www.data.gouv.fr/datasets/proposition-de-contours-des-bureaux-de-vote/
[contours-iris]: https://geoservices.ign.fr/contoursiris
[actifs]: https://www.insee.fr/fr/statistiques/6543289
[population]: https://www.insee.fr/fr/statistiques/6543200
[diplome-formation]: https://www.insee.fr/fr/statistiques/6543298
[logement]: https://www.insee.fr/fr/statistiques/6543302
<!-- [menages]: https://www.insee.fr/fr/statistiques/6543224 -->
[eur24]: https://www.data.gouv.fr/datasets/resultats-des-elections-europeennes-du-9-juin-2024
[prt122]: https://www.data.gouv.fr/datasets/election-presidentielle-des-10-et-24-avril-2022-resultats-definitifs-du-1er-tour

## Package dependencies

All from CRAN except noted otherwise:

- `archive` (to deal with `.7z`)
- `factoextra`
- `FactoMineR`
- `patchwork`
- `remotes` (to install [`sfReapportion`][sfReapportion] from GitHub)
- `sf`
- [`sfReapportion`][sfReapportion] (from GitHub)
- `tidyverse`

## Questions

Reach me at `f.briatte at gmail dot com` if need be :)
