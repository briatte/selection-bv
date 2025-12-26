#
# Téléchargement de toutes les données requises par
#
#   2-preparation-donnees.r
#   3-selection-bureaux.r
#

# packages ----------------------------------------------------------------

pkgs <- c("factoextra", "FactoMineR", "patchwork", "sf", "tidyverse")
for (i in pkgs) {
  if (!require(i, character.only = TRUE))
    install.packages(i)
}

library(factoextra)
library(FactoMineR)
library(patchwork)
library(sf)
library(tidyverse)

# paramètres généraux -----------------------------------------------------

nom_fichier_base <- "Lille"
bureaux_a_exclure <- c("59350_0901") # bureau 901 Lille = prisonniers

# dossier-cible -----------------------------------------------------------

s <- "sorties"
stopifnot(fs::dir_exists(s))

# chargement des bases ----------------------------------------------------

# résultats électoraux
base_elec <- fs::path(s, str_c("Base-", nom_fichier_base, "-elec.rds")) %>%
  readr::read_rds() %>%
  dplyr::filter(!BV %in% bureaux_a_exclure) %>%
  as.data.frame() # requis pour que {FactoMineR} identifie les parangons
row.names(base_elec) <- base_elec$BV

# variables Insee (note : le bureau à supprimer est déjà exclu)
base_soc <- fs::path(s, str_c("Base-", nom_fichier_base, "-soc.rds")) %>%
  readr::read_rds() %>%
  as.data.frame() # requis pour que {FactoMineR} identifie les parangons
row.names(base_soc) <- base_soc$codeBureauVote

# base combinée
base <- fs::path(s, str_c("Base-", nom_fichier_base, "-finale.rds")) %>%
  readr::read_rds() %>%
  dplyr::filter(!BV %in% bureaux_a_exclure)

# ACP et classification à partir des variables socio-démographiques -------

# ACP
acpsd <- select(base_soc, -codeBureauVote, -Population) %>%
  FactoMineR::PCA(graph = FALSE)

# métriques
head(acpsd$eig)     # inertie décrite par chaque axe
head(acpsd$var$cor) # corrélation des variables aux axes

# représentation graphique
plot <- factoextra::fviz_pca_var(acpsd, repel = TRUE) +
  labs(title = "ACP : variables socio-démographiques") +
  theme_minimal()

# export
out_path <- fs::path(s, str_c("resultats-ACP-", nom_fichier_base, "-SD.pdf"))
message("Graphique ACP socio-démo. exporté vers ", out_path)
ggplot2::ggsave(out_path, plot, width = 10, height = 10)

# CAH
cahsd <- FactoMineR::HCPC(acpsd, metric = "euclidean", method = "ward",
                          graph = FALSE)

# extraction des clusters
cahsd_descr <- FactoMineR::catdes(cahsd$data.clust, num.var = 28)$quanti

# description de la CAH
lapply(cahsd_descr, round, 2) %>%
  lapply(function(x) head(x[, 1:4], 7))

# récupération de la variable de classe
base <- tibble(BV = base_soc$codeBureauVote,
       classe_sd = as.character(cahsd$data.clust[, 28])) %>%
  dplyr::full_join(base, by = "BV")

# pourcentages
dplyr::count(base, classe_sd) %>%
  dplyr::mutate(pct = 100 * n / sum(n))

# ACP et classification à partir des variables électorales ----------------

# ACP (excl. BV, Inscrits_e, Inscrits_p)
acpv <- select(base_elec, -BV, -starts_with("Inscrits")) %>%
  FactoMineR::PCA(graph = FALSE)

# métriques de l'ACP
head(acpv$eig)
head(acpv$var$coord)

# représentation graphique
plot <- factoextra::fviz_pca_var(acpv, repel = TRUE) +
  labs(title = "ACP : variables électorales") +
  theme_minimal()

# export
out_path <- fs::path(s, str_c("resultats-ACP-", nom_fichier_base, "-votes.pdf"))
message("Graphique ACP votes exporté vers ", out_path)
ggplot2::ggsave(out_path, plot, width = 10, height = 10)

# CAH
cahv <- FactoMineR::HCPC(acpv, metric = "euclidean", method = "ward",
                         graph = FALSE)

# extraction des clusters
cahv_descr <- FactoMineR::catdes(cahv$data.clust, num.var = 17)$quanti

# description de la CAH
lapply(cahv_descr, round, 2) %>%
  lapply(function(x) head(x[, 1:4], 7))

# récupération de la variable de classe
base <- tibble(BV = base_elec$BV,
               classe_v = as.character(cahv$data.clust[, 17])) %>%
  dplyr::full_join(base, by = "BV")

# pourcentages
dplyr::count(base, classe_sd) %>%
  dplyr::mutate(pct = 100 * n / sum(n))

# sélection des bureaux ---------------------------------------------------

# croisement des deux classifications
with(base, table(classe_sd, classe_v))

# examen des parangons de chaque classe
cahv$desc.ind$para
cahsd$desc.ind$para

# extraction des parangons de la CAH sur variables électorales
parangons_v <- as.vector(sapply(cahv$desc.ind$para, names))
# extraction des parangons de la CAH sur variables socio-démographiques
parangons_sd <- as.vector(sapply(cahsd$desc.ind$para, names))

# assemblage des résultats
bv_results <- dplyr::select(base, BV, classe_v, classe_sd) %>%
  dplyr::mutate(parangon_sd = as.integer(BV %in% parangons_sd),
                parangon_v  = as.integer(BV %in% parangons_v),
                score = parangon_sd + parangon_v) %>%
  dplyr::arrange(-score) %>%
  dplyr::left_join(dplyr::select(base, -classe_v, -classe_sd), by = "BV")

# examen des parangons (meilleurs bureaux en premier)
arrange(filter(bv_results, score > 0), -score)

# export
out_path <- fs::path(s, str_c("resultats-BV-", nom_fichier_base, ".tsv"))
message("Résultats exportés vers ", out_path)
readr::write_tsv(bv_results, out_path)

## À partir d'une liste des adresses des bureaux, on essaye de trouver :
#
# - des bureaux isolés
#   (éviter les doubles bureaux car on n'est pas sûr de pouvoir sélectionner
#    les répondant·es à la sortie)
#
# - des bureaux au croisement de classes bien représentées
#
# - des bureaux parangons d'une classe


# visualisation -----------------------------------------------------------

# mise en avant des 6 premières variables socio-démographiques
clusters_sd <- lapply(cahsd_descr, rownames) %>%
  lapply(head, 6) %>%
  sapply(str_c, collapse = ", ")

# mise en avant des 6 premiers résultats électoraux
clusters_v <- lapply(cahv_descr, rownames) %>%
  lapply(head, 6) %>%
  sapply(str_c, collapse = ", ")

bv_map <- fs::path(s, str_c("contours-", nom_fichier_base, "-BV.rds")) %>%
  readr::read_rds() %>%
  dplyr::left_join(bv_results, by = c("codeBureauVote" = "BV")) %>%
  dplyr::mutate(lbl_sd = str_c(classe_sd, " : ", clusters_sd[ classe_sd ]),
                lbl_v = str_c(classe_v, " : ", clusters_v[ classe_v ]),
                numeroBureauVote = str_remove(numeroBureauVote, "^0+"))

p1 <- ggplot(bv_map) +
  geom_sf(aes(fill = factor(lbl_sd), alpha = factor(parangon_sd))) +
  geom_sf_label(data = filter(bv_map, parangon_sd == 1),
                aes(label = numeroBureauVote, fill = factor(lbl_sd)),
                color = "white", show.legend = FALSE) +
  scale_fill_brewer("", palette = "Set1") +
  scale_alpha_manual("", values = c("0" = 0.5, "1" = 1)) +
  guides(alpha = "none") +
  theme_void(base_size = 12) +
  theme(legend.position = "bottom",
        legend.direction = "vertical",
        legend.key.spacing.y = unit(2, "mm"),
        legend.text = element_text(face = "bold", size = 12)) +
  labs(title = str_c("Classification des bureaux de ", nom_fichier_base,
                     " par leur composition socio-démographique"),
       subtitle = "Base : données infracommunales Insee 2019")

p2 <- ggplot(bv_map) +
  geom_sf(aes(fill = factor(lbl_v), alpha = factor(parangon_v))) +
  geom_sf_label(data = filter(bv_map, parangon_v == 1),
                aes(label = numeroBureauVote, fill = factor(lbl_v)),
                color = "white", show.legend = FALSE) +
  scale_fill_brewer("", palette = "Set2") +
  scale_alpha_manual("", values = c("0" = 0.5, "1" = 1)) +
  guides(alpha = "none") +
  theme_void(base_size = 12) +
  theme(legend.position = "bottom",
        legend.direction = "vertical",
        legend.key.spacing.y = unit(2, "mm"),
        legend.text = element_text(face = "bold", size = 12)) +
  labs(title = str_c("Classification des bureaux de ", nom_fichier_base,
                     " par leurs résultats électoraux"),
       subtitle = "Base : élections présidentielle 2022 T1 et européennes 2024")

# export
out_path <- fs::path(s, str_c("resultats-CAH-", nom_fichier_base, ".png"))
message("Carte des clusters CAH exportée vers ", out_path)
# Lille: height = 8, Grenoble: height = 11, Bordeaux / Marseille: height = 13.5
ggplot2::ggsave(out_path, p1 + p2, width = 16, height = 8)

# kthxbye
