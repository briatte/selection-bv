#
# Téléchargement de toutes les données requises par
#
#   2-preparation-donnees.r
#   3-selection-bureaux.r
#

# packages ----------------------------------------------------------------

pkgs <- c("factoextra", "FactoMineR", "tidyverse")
for (i in pkgs) {
  if (!require(i, character.only = TRUE))
    install.packages(i)
}

library(factoextra)
library(FactoMineR)
library(tidyverse)

# chargement des bases ----------------------------------------------------

# résultats électoraux
base_elec <- readr::read_rds("sorties/Base-Lille-elec.rds") %>%
  # suppression du bureau 901 (prisonniers)
  dplyr::filter(!BV %in% "59350_0901") %>%
  # requis pour que {FactoMineR} identifie les parangons
  as.data.frame()
row.names(base_elec) <- base_elec$BV

# variables Insee
base_soc <- readr::read_rds("sorties/Base-Lille-soc.rds") %>%
  # suppression du bureau 901 (prisonniers)
  dplyr::filter(!codeBureauVote %in% "59350_0901") %>%
  # requis pour que {FactoMineR} identifie les parangons
  as.data.frame()
row.names(base_soc) <- base_soc$codeBureauVote

# base combinée
base <- readr::read_rds("sorties/Base-Lille-finale.rds") %>%
  # suppression du bureau 901 (prisonniers)
  dplyr::filter(!BV %in% "59350_0901")

# ACP et classification à partir des variables socioéconomiques -----------

# ACP
acpsd <- select(base_soc, -codeBureauVote, -Population) %>%
  FactoMineR::PCA(graph = FALSE)

# métriques
head(acpsd$eig)     # inertie décrite par chaque axe
head(acpsd$var$cor) # corrélation des variables aux axes

# représentation graphique
factoextra::fviz_pca_var(acpsd, repel = TRUE) +
  labs(title = "ACP : variables socio-démographiques") +
  theme_minimal()

ggsave("sorties/Exemple - ACP SD Lille MINE.pdf", width = 10, height = 10)

# CAH
cahsd <- FactoMineR::HCPC(acpsd, metric = "euclidean", method = "ward",
                          graph = FALSE)

# description de la CAH
FactoMineR::catdes(cahsd$data.clust, num.var = 28)$quanti %>%
  lapply(round, 2) %>%
  lapply(function(x) x[ 1:7, 1:4])

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
factoextra::fviz_pca_var(acpv, repel = TRUE) +
  labs(title = "ACP : variables électorales") +
  theme_minimal()

ggsave("sorties/Exemple - ACP Votes Lille MINE.pdf", width = 10, height = 10)

# CAH
cahv <- FactoMineR::HCPC(acpv, metric = "euclidean", method = "ward",
                         graph = FALSE)
# description de la CAH
FactoMineR::catdes(cahv$data.clust, num.var = 17)$quanti %>%
  lapply(round, 2) %>%
  lapply(function(x) x[ 1:7, 1:4])

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

# examen des parangons (meilleurs bureaux tout en haut)
dplyr::select(base, BV, classe_v, classe_sd) %>%
  mutate(parangon_sd = as.integer(BV %in% parangons_sd),
         parangon_v  = as.integer(BV %in% parangons_v),
         score = parangon_sd + parangon_v) %>%
  filter(score > 0) %>%
  arrange(-score) %>%
  print(n = Inf)

# examen des classes de chaque BV
dplyr::select(base, BV, classe_v, classe_sd) %>%
  print(n = Inf)

## À partir d'une liste des adresses des bureaux, on essaye de trouver :
#
# - des bureaux isolés
#   (éviter les doubles bureaux car on n'est pas sûr de pouvoir sélectionner
#    les répondant·es à la sortie)
#
# - des bureaux au croisement de classes bien représentées
#
# - des bureaux parangons d'une classe

# kthxbye
