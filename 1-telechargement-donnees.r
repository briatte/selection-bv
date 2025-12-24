#
# Téléchargement de toutes les données requises par
#
#   2-preparation-donnees.r
#   3-selection-bureaux.r
#

# packages ----------------------------------------------------------------

pkgs <- c("archive", "fs")
for (i in pkgs) {
  if (!require(i, character.only = TRUE))
    install.packages(i)
}

library(archive)
library(fs)

# dossier-cible -----------------------------------------------------------

d <- "donnees"
fs::dir_create(d)

# contours BV -------------------------------------------------------------
#
# https://www.data.gouv.fr/datasets/proposition-de-contours-des-bureaux-de-vote/

# GeoJSON paths (for reference)
# u <- fs::path("https://www.data.gouv.fr/api/1/datasets/r/",
#               "f98165a7-7c37-4705-a181-bcfc943edc73")
# f <- fs::path(d, "contours-france-entiere-latest-v2.geojson")
#
# if (!fs::file_exists(f)) {
#   download.file(u, f, mode = "wb", quiet = FALSE)
# }

# PMTiles (more compact)
u <- fs::path("https://www.data.gouv.fr/api/1/datasets/r/",
              "53b31b93-82bf-4859-ada9-d00b91952f95")
f <- fs::path(d, "reu-france-entiere-2022-06-01-v2.pmtiles")

if (!fs::file_exists(f)) {
  download.file(u, f, mode = "wb", quiet = FALSE)
}

# contours IRIS 2019 ------------------------------------------------------
#
# https://geoservices.ign.fr/contoursiris

u <- fs::path("https://data.geopf.fr/telechargement/download/",
              "CONTOURS-IRIS/CONTOURS-IRIS_2-1__SHP__FRA_2019-01-01/",
              "CONTOURS-IRIS_2-1__SHP__FRA_2019-01-01.7z")
f <- fs::path(d, "CONTOURS-IRIS_2-1__SHP__FRA_2019-01-01.7z")

if (!fs::file_exists(f)) {
  download.file(u, f, mode = "wb", quiet = FALSE)
}

# unzip everything (for simplicity's sake)
if (!fs::dir_exists(fs::path_ext_remove(f))) {
  archive::archive_extract(f, dir = d)
}

# Insee : actifs 2019 -----------------------------------------------------
#
# https://www.insee.fr/fr/statistiques/6543289

u <- fs::path("https://www.insee.fr/fr/statistiques/fichier/",
              "6543289/base-ic-activite-residents-2019_csv.zip")
f <- fs::path(d, fs::path_file(u))

if (!fs::file_exists(f)) {
  download.file(u, f, mode = "wb", quiet = FALSE)
}

# Insee : population 2019 -------------------------------------------------
#
# https://www.insee.fr/fr/statistiques/6543200

u <- fs::path("https://www.insee.fr/fr/statistiques/fichier/",
              "6543200/base-ic-evol-struct-pop-2019_csv.zip")
f <- fs::path(d, fs::path_file(u))

if (!fs::file_exists(f)) {
  download.file(u, f, mode = "wb", quiet = FALSE)
}

# Insee : diplômes/formation 2019 -----------------------------------------
#
# https://www.insee.fr/fr/statistiques/6543298

u <- fs::path("https://www.insee.fr/fr/statistiques/fichier/",
              "6543298/base-ic-diplomes-formation-2019_csv.zip")
f <- fs::path(d, fs::path_file(u))

if (!fs::file_exists(f)) {
  download.file(u, f, mode = "wb", quiet = FALSE)
}

# Insee : logement 2019 ---------------------------------------------------
#
# https://www.insee.fr/fr/statistiques/6543302

u <- fs::path("https://www.insee.fr/fr/statistiques/fichier/",
              "6543302/base-ic-logement-2019_csv.zip")
f <- fs::path(d, fs::path_file(u))

if (!fs::file_exists(f)) {
  download.file(u, f, mode = "wb", quiet = FALSE)
}

# Insee : ménages 2019 ----------------------------------------------------
#
# https://www.insee.fr/fr/statistiques/6543224

u <- fs::path("https://www.insee.fr/fr/statistiques/fichier/",
              "6543224/base-ic-couples-familles-menages-2019_csv.zip")
f <- fs::path(d, fs::path_file(u))

if (!fs::file_exists(f)) {
  download.file(u, f, mode = "wb", quiet = FALSE)
}

# Élections : européennes 2024 --------------------------------------------
#
# https://www.data.gouv.fr/datasets/resultats-des-elections-europeennes-du-9-juin-2024

u <- fs::path("https://www.data.gouv.fr/api/1/datasets/r/",
              "cc1883d9-1265-4365-b754-fb6aef22d82e")
f <- fs::path(d, "resultats-definitifs-par-bureau-de-vote.csv")

if (!fs::file_exists(f)) {
  download.file(u, f, mode = "wb", quiet = FALSE)
}

# zip it
utils::zip(str_c(f, ".zip"), f, flags = "-r9Xj") # junk the paths
fs::file_delete(f)

# Élections : présidentielle 2022 T1 --------------------------------------
#
# https://www.data.gouv.fr/datasets/election-presidentielle-des-10-et-24-avril-2022-resultats-definitifs-du-1er-tour

u <- fs::path("https://www.data.gouv.fr/api/1/datasets/r/",
              "79b5cac4-4957-486b-bbda-322d80868224")
f <- fs::path(d, "resultats-par-niveau-burvot-t1-france-entiere.txt")

if (!fs::file_exists(f)) {
  download.file(u, f, mode = "wb", quiet = FALSE)
}

# zip it
utils::zip(str_c(f, ".zip"), f, flags = "-r9Xj") # junk the paths
fs::file_delete(f)

# kthxbye
