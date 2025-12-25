## Prise en main

Le code s'exécute dans une version récente de R, probablement R 3.3+, mais vu que tout a été testé sous R 4.5+, je préfère recommander cette version.

Le répertoire de travail à utiliser est évidemment `selection-bv`.

Les scripts sont à exécuter dans l'ordre. Les _packages_ requis seront installés si nécessaire. La liste intégrale des dépendances est mentionnée [à la fin du README][pkgs]. Le même document cite l'intégralité des sources.

## 1. Téléchargement des données

Le script `1-telechargement-donnees.r` va télécharger des fonds de carte, des données Insee, et des résultats électoraux. Il faut un peu d'espace-disque, mettons 2 Go (il y a un [fond de carte approximant les bureaux de vote de la France entière][contours-bv] à télécharger, sauf si vous avez vos propres contours de bureaux de vote à fournir aux scripts suivants ; voir en fin de document).

Les données seront compressées si possible.

## 2. Préparation des données

Les [lignes 25-26][script2] du script `2-preparation-donnees.r` sont à ajuster selon les besoins :

```r
code_insee_cible <- "59350"
nom_fichier_base <- "Lille"
```

Le script renverra un avertissement si les bureaux de vote de la commune diffèrent entre la présidentielle de 2022 et les européennes de 2024, mais vous laissera continuer quand même, à vos risques et périls, vu que cela créera des données manquantes dans l'ACP, et que la "solution" par défaut de [`FactoMineR`][factominer] (imputer des moyennes) vaut ce qu'elle vaut ; on peut peut-être faire mieux avec [`missMDA`][missmda], comme le suggère le _package_ dans son message d'avertissement, mais ça reste largement spéculatif.

## 3. Sélection des bureaux

Les [lignes 24-25][script3] du script `3-selection-bureaux.r` sont également à ajuster selon les besoins :

```r
nom_fichier_base <- "Lille"
bureaux_a_exclure <- c("59350_0901") # bureau 901 Lille = prisonniers
```

Le même script peut être modifié pour modifier le nombre de parangons, ou pour modifier la taille des cartes finales.

## Autres modifications possibles

Le code utilise _une partie_ des résultats des élections présidentielle de 2022 (premier tour) et européennes de 2024 : c'est modifiable si besoin, de même que toutes les opérations de "sélection" des bureaux, qui ne sélectionnent rien du tout dans les faits : la sélection finale des bureaux est à effectuer manuellement, après inspection des résultats, comparaison des localisations géographiques des bureaux, et prise en compte des contraintes pratiques.

La modification la plus évidente consiste à ne pas utiliser l'[approximation des contours des bureaux de vote][contours-bv], mais à passer un fichier `contours-Bordeaux-BV.rds`, par exemple, contenant les contours officiels des bureaux de vote. Le fichier est à placer dans le dossier `sorties` _avant_ d'exécuter les deux derniers scripts, et à nommer comme dans l'exemple. Le fichier doit contenir un fond de carte de classe `sf` avec deux variables `numeroBureauVote` et `codeBureauVote`, comme dans l'exemple détaillé dans le [README][readme].

## Auteurs

Tristan Haute a rédigé la vaste majorité des scripts 2 et 3 ; je me suis contenté de corriger deux ou trois trucs et de rajouter le reste, notamment les cartes finales.

[Contactez-moi](mailto:f.briatte@gmail.com) si vous trouvez une erreur flagrante, ou mieux, [signalez-le][issues] dans les _issues_ du répertoire GitHub [`briatte/selection-bv`][github].

--- François Briatte, décembre 2025

[contours-bv]: https://www.data.gouv.fr/datasets/proposition-de-contours-des-bureaux-de-vote/
[factominer]: https://cran.r-project.org/package=FactoMineR
[github]: https://github.com/briatte/selection-bv
[issues]: https://github.com/briatte/selection-bv/issues
[missmda]: https://cran.r-project.org/package=missMDA
[pkgs]: https://github.com/briatte/selection-bv/blob/main/README.md#package-dependencies
[readme]: https://github.com/briatte/selection-bv/blob/main/README.md
[script2]: https://github.com/briatte/selection-bv/blob/main/2-preparation-donnees.r#L25-L26
[script3]: https://github.com/briatte/selection-bv/blob/main/3-selection-bureaux.r#L24-L25
