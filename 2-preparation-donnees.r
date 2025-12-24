#
# Préparation de toutes les données requises par
#   3-selection-bureaux.r
#

# packages ----------------------------------------------------------------

pkgs <- c("remotes", "sf", "tidyverse")
for (i in pkgs) {
  if (!require(i, character.only = TRUE))
    install.packages(i)
}

library(sf)
library(tidyverse) # fs, dplyr, readr, stringr, etc.

if (!require(sfReapportion)) {
  remotes::install_github("briatte/sfReapportion")
}

library(sfReapportion)

# global settings ---------------------------------------------------------

code_insee_cible <- "59350"
nom_fichier_base <- "Lille"

# dossiers-cibles ---------------------------------------------------------

d <- "donnees"
stopifnot(fs::dir_exists(d))

# TODO: fs::path
s <- "sorties"
fs::dir_create(s)

# contours BV -------------------------------------------------------------

# GeoJSON paths (for reference)
# bv_fdc <- fs::path(d, "contours-france-entiere-latest-v2.geojson") %>%
#   sf::st_read() %>%
#   # Lille: subset from 68806 to 126 features
#   dplyr::filter(codeCommune %in% code_insee_cible)

# PMTiles (more compact)
bv_fdc <- fs::path(d, "reu-france-entiere-2022-06-01-v2.pmtiles") %>%
  sf::st_read() %>%
  # Lille: subset from 68806 to 126 features
  dplyr::filter(codeCommune %in% code_insee_cible)

# export
export_path <- fs::path(s, "Contours-", nom_fichier_base, "-BV-2025.rds")
message(str_c("Contours BV 2025 exportés vers ", export_path))
readr::write_rds(bv_fdc, export_path)

# contours IRIS 2019 ------------------------------------------------------

iris_fdc <- fs::path(d, "CONTOURS-IRIS_2-1__SHP__FRA_2019-01-01/",
                     "CONTOURS-IRIS/",
                     "1_DONNEES_LIVRAISON_2020-01-00139/",
                     "CONTOURS-IRIS_2-1_SHP_LAMB93_FXX-2019/",
                     "CONTOURS-IRIS.shp") %>%
  sf::st_read() %>%
  # Lille: subset from 48590 to 110 features
  dplyr::filter(INSEE_COM %in% code_insee_cible) %>%
  sf::st_transform(crs = "WGS84")

# export
export_path <- fs::path(s, "Contours-", nom_fichier_base, "-IRIS-2019.rds")
message(str_c("Contours IRIS 2019 exportés vers ", export_path))
readr::write_rds(iris_fdc, export_path)

# Insee : actifs 2019 -----------------------------------------------------

actifs <- fs::path(d, "/base-ic-activite-residents-2019_csv.zip") %>%
  readr::read_delim(delim = ";", locale = locale(decimal_mark = "."),
                    show_col_types = FALSE) %>%
  dplyr::select_at(c(1, 6:10, 14, 18:21, 30:33, 41, 43:60, 63, 66, 69, 72:86,
                     89, 92, 95, 96, 100:107, 114:120)) %>%
  dplyr::filter(str_sub(IRIS, 1, 5) %in% code_insee_cible)

# Insee : population 2019 -------------------------------------------------

population <- fs::path(d, "/base-ic-evol-struct-pop-2019_csv.zip") %>%
  readr::read_delim(delim = ";", locale = locale(decimal_mark = "."),
                    show_col_types = FALSE) %>%
  dplyr::select_at(c(1, 6:26, 36, 46:54, 73:75)) %>%
  dplyr::filter(str_sub(IRIS, 1, 5) %in% code_insee_cible)

# Insee : diplômes/formation 2019 -----------------------------------------

formation <- fs::path(d, "/base-ic-diplomes-formation-2019_csv.zip") %>%
  readr::read_delim(delim = ";", locale = locale(decimal_mark = "."),
                    show_col_types = FALSE) %>%
  dplyr::select_at(c(1, 6:27)) %>%
  dplyr::filter(str_sub(IRIS, 1, 5) %in% code_insee_cible)

# Insee : logement 2019 ---------------------------------------------------

logement <- fs::path(d, "/base-ic-logement-2019_csv.zip") %>%
  readr::read_delim(delim = ";", locale = locale(decimal_mark = "."),
                    show_col_types = FALSE) %>%
  dplyr::select_at(c(1, 6:7, 9, 12:16, 18, 20, 22:35, 55:59, 64:77)) %>%
  dplyr::filter(str_sub(IRIS, 1, 5) %in% code_insee_cible)

# Insee : ménages 2019 ----------------------------------------------------

couple <- fs::path(d, "/base-ic-couples-familles-menages-2019_csv.zip") %>%
  readr::read_delim(delim = ";", locale = locale(decimal_mark = "."),
                    show_col_types = FALSE) %>%
  dplyr::select_at(c(1, 6:23)) %>%
  dplyr::filter(str_sub(IRIS, 1, 5) %in% code_insee_cible)

# Préparation des données -------------------------------------------------

# sanity check
stopifnot(identical(population$IRIS, actifs$IRIS),
          identical(population$IRIS, formation$IRIS),
          identical(population$IRIS, logement$IRIS),
          identical(population$IRIS, couple$IRIS))

# fusion des bases infracommunales (en retirant quelques doublons accidentels)
iris_base <- select(actifs, -P19_POP5564) %>%
  dplyr::full_join(population, by = "IRIS") %>%
  select(-P19_POP0610, -P19_POP1824) %>%
  dplyr::full_join(formation, by = "IRIS") %>%
  dplyr::full_join(logement, by = "IRIS") %>%
  dplyr::full_join(couple, by = "IRIS") %>%
  dplyr::transmute(IRIS,
                   Age1824   = P19_POP1824,
                   Age2539   = P19_POP2539,
                   Age4054   = P19_POP4054,
                   Age5564   = P19_POP5564,
                   Age65plus = P19_POP65P,
                   Actifs         = C19_ACT1564,
                   Actifs_occupes = C19_ACTOCC1564,
                   GSP1 = C19_ACTOCC1564_CS1,
                   GSP2 = C19_ACTOCC1564_CS2,
                   GSP3 = C19_ACTOCC1564_CS3,
                   GSP4 = C19_ACTOCC1564_CS4,
                   GSP5 = C19_ACTOCC1564_CS5,
                   GSP6 = C19_ACTOCC1564_CS6,
                   Chomeurs           = P19_CHOM1564,
                   Inactifs           = P19_INACT1564,
                   Population         = P19_POP,
                   Etrangers          = P19_POP_ETR,
                   Immigres           = P19_POP_IMM,
                   Menages            = P19_PMEN,
                   La_10_ou_plus      = P19_PMEN_ANEM10P,
                   La_2_a_4           = P19_PMEN_ANEM0204,
                   La_5_a_9           = P19_PMEN_ANEM0509,
                   La_moins_de_2      = P19_PMEN_ANEM0002,
                   Residents          = P19_RP,
                   Locataires_hlm     = P19_RP_LOCHLMV,
                   Proprietaires      = P19_RP_PROP,
                   Retraites          = C19_POP15P_CS7,
                   Temps_partiel      = P19_SAL15P_TP,
                   Salaries_precaires = P19_SAL15P_CDD + P19_SAL15P_INTERIM +
                     P19_SAL15P_EMPAID + P19_SAL15P_APPR,
                   Baccalaureat      = P19_NSCOL15P_BAC,
                   CAP_BEP           = P19_NSCOL15P_CAPBEP,
                   Superieur         = P19_NSCOL15P_SUP2 + P19_NSCOL15P_SUP34 +
                     P19_NSCOL15P_SUP5,
                   Sans_diplome_BEPC = P19_NSCOL15P_DIPLMIN + P19_NSCOL15P_BEPC,
                   Population_18_ans_et_plus = P19_POP - P19_POP0002 -
                     P19_POP0305 - P19_POP0610 - P19_POP1117,
                   Non_scolarises = P19_NSCOL15P,
                   Population_15_ans_et_plus = C19_POP15P,
                   Population_15_64_ans = P19_POP1564,
                   Salaries = P19_SAL15P)

# iris_base<-iris_base[,c(1,189:226)]

# réapportion BV / IRIS ---------------------------------------------------

base_soc <- sfReapportion::sfReapportion(iris_fdc, bv_fdc, iris_base,
                                         "CODE_IRIS", "codeBureauVote", "IRIS")

# mise en % des variables socioéconomiques
base_soc <- base_soc %>%
  dplyr::mutate(GSP12 = 100 * (GSP1 + GSP2) / Actifs_occupes,
                GSP3 = 100 * GSP3 / Actifs_occupes,
                GSP4 = 100 * GSP4 / Actifs_occupes,
                GSP5 = 100 * GSP5 / Actifs_occupes,
                GSP6 = 100 * GSP6 / Actifs_occupes,
                Salaries_precaires = 100 * Salaries_precaires / Salaries,
                Temps_partiel      = 100 * Temps_partiel / Salaries,
                Retraites = 100 * Retraites / Population_15_ans_et_plus,
                Inactifs =  100 * Inactifs  / Population_15_64_ans,
                Chomeurs =  100 * Chomeurs  / Actifs,
                Immigres =  100 * Immigres  / Population,
                Etrangers = 100 * Etrangers / Population,
                Locataires_HLM = 100 * Locataires_hlm / Residents,
                Proprietaires =  100 * Proprietaires  / Residents,
                # durée de résidence
                La_10_ou_plus = 100 * La_10_ou_plus / Menages,
                La_5_a_9      = 100 * La_5_a_9 / Menages,
                La_2_a_4      = 100 * La_2_a_4 / Menages,
                La_moins_de_2 = 100 * La_moins_de_2 / Menages,
                Baccalaureat      = 100 * Baccalaureat / Non_scolarises,
                Superieur         = 100 * Superieur / Non_scolarises,
                CAP_BEP           = 100 * CAP_BEP / Non_scolarises,
                Sans_diplome_BEPC = 100 * Sans_diplome_BEPC / Non_scolarises,
                Age1824   = 100 * Age1824   / Population_18_ans_et_plus,
                Age2539   = 100 * Age2539   / Population_18_ans_et_plus,
                Age4054   = 100 * Age4054   / Population_18_ans_et_plus,
                Age5564   = 100 * Age5564   / Population_18_ans_et_plus,
                Age65plus = 100 * Age65plus / Population_18_ans_et_plus) %>%
  # keep Tristan's column order/selection, just in case
  select_at(c(1, 17, 2:6, 40, 11:16, 18:19, 21:24, 27, 41, 28:34))

# export
export_path <- fs::path(s, "/Base-", nom_fichier_base, "-soc.rds")
message("Base Insee exportée vers ", export_path)
readr::write_rds(base_soc, export_path)

# Élections : européennes 2024 --------------------------------------------

eur <- fs::path(d, "/resultats-definitifs-par-bureau-de-vote.csv.zip") %>%
  readr::read_csv2(show_col_types = FALSE) %>%
  dplyr::filter(`Code commune` %in% code_insee_cible) %>%
  dplyr::transmute(BV = str_c(`Code commune`, `Code BV`, sep = "_"),
                   Abstention_e = 100 - 100 * Votants / Inscrits,
                   RN   = 100 * `Voix 5`  / Inscrits,
                   ENS  = 100 * `Voix 11` / Inscrits,
                   PS   = 100 * `Voix 27` / Inscrits,
                   LFI  = 100 * `Voix 4`  / Inscrits,
                   LR   = 100 * `Voix 18` / Inscrits,
                   EELV = 100 * `Voix 6`  / Inscrits,
                   REC  = 100 * `Voix 3`  / Inscrits,
                   PCF  = 100 * `Voix 33` / Inscrits,
                   Inscrits_e = Inscrits)

# Elections : présidentielle 2022 (tour 1) --------------------------------

# we need to hack the column names to fill in the missing ones
n <- fs::path(d, "/resultats-par-niveau-burvot-t1-france-entiere.txt.zip") %>%
  readr::read_csv2(n_max = 0, locale = locale(encoding = "latin1"),
                   show_col_types = FALSE) %>%
  names()

# produce the repeated column names (will get 'repaired' just below)
n <- c(n[ 1:21 ], rep(n[ 22:28 ], 12))

prt1 <- fs::path(d, "/resultats-par-niveau-burvot-t1-france-entiere.txt.zip") %>%
  readr::read_csv2(col_names = n, skip = 1,
                   locale = locale(decimal_mark = ",", encoding = "latin1"),
                   name_repair = "unique_quiet",
                   show_col_types = FALSE) %>%
  dplyr::mutate(insee = str_c(`Code du département`, `Code de la commune`)) %>%
  dplyr::filter(insee %in% code_insee_cible) %>%
  dplyr::transmute(BV = str_c(insee, `Code du b.vote`, sep = "_"),
                   Abstention_p = 100 - 100 * Votants / Inscrits,
                   Melenchon = 100 * `Voix...68` / Inscrits, # Voix.6
                   Macron    = 100 * `Voix...40` / Inscrits, # Voix.2
                   LePen     = 100 * `Voix...54` / Inscrits, # Voix.4
                   Zemmour   = 100 * `Voix...61` / Inscrits, # Voix.5
                   Jadot     = 100 * `Voix...82` / Inscrits, # Voix.8
                   Pecresse  = 100 * `Voix...89` / Inscrits, # Voix.9
                   Inscrits_p = Inscrits)

# sanity check
stopifnot(identical(sort(eur$BV), sort(prt1$BV)))

# fusion des bases électorales
base_elec <- dplyr::full_join(eur, prt1, by = "BV")

# export
export_path <- fs::path(s, "/Base-", nom_fichier_base, "-elec.rds")
message("Base électorale exportée vers ", export_path)
readr::write_rds(base_elec, export_path)

# base combinée
base <- dplyr::full_join(base_elec, base_soc, by = c("BV" = "codeBureauVote"))

# export
export_path <- fs::path(s, "s/Base-", nom_fichier_base, "-finale.rds")
message("Base combinée exportée vers ", export_path)
readr::write_rds(base, export_path)

# kthxbye
