#
# Téléchargement de toutes les données requises par
#
#   2-preparation-donnees.r
#   3-selection-bureaux.r
#

# packages ----------------------------------------------------------------

pkgs <- c("factoextra", "FactoMineR", "questionr", "tidyverse")
for (i in pkgs) {
  if (!require(i, character.only = TRUE))
    install.packages(i)
}

library(factoextra)
library(FactoMineR)
library(questionr)
library(tidyverse)

# chargement des bases ----------------------------------------------------

# résultats électoraux
base_elec <- readr::read_rds("sorties/Base-Lille-elec.rds") %>%
  # suppression du bureau 901 (prisonniers)
  dplyr::filter(!BV %in% "59350_0901")
# row.names(base_elec)<-base_elec$BV

# variables Insee
base_soc <- readr::read_rds("sorties/Base-Lille-soc.rds") %>%
  # suppression du bureau 901 (prisonniers)
  dplyr::filter(!codeBureauVote %in% "59350_0901")
# row.names(base_soc)<-base_soc$codeBureauVote

# base combinée
base <- readr::read_rds("sorties/Base-Lille-finale.rds") %>%
  # suppression du bureau 901 (prisonniers)
  dplyr::filter(!BV %in% "59350_0901")

#### II. Tirage des bureaux de vote

### I.1 Classification des bureaux

## Recodages
# row.names(base)<-base$BV


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
FactoMineR::catdes(cahsd$data.clust, num.var = 28) %>%
  str()

FactoMineR::catdes(cahsd$data.clust, num.var = 28)$quanti %>%
  lapply(round, 2) %>%
  lapply(function(x) x[ x[, 1] > 5, 1:4])

# récupération de la variable de classe
base <- tibble(BV = base_soc$codeBureauVote,
       classe_sd = as.character(cahsd$data.clust[, 28])) %>%
  dplyr::full_join(base, by = "BV")

questionr::freq(base$classe_sd)

# ACP et classification à partir des variables électorales ----------------

# ACP (excl. BV, Inscrits_e, Inscrits_p)
acpv <- select(base_elec, -BV, -starts_with("Inscrits")) %>%
  FactoMineR::PCA(graph = FALSE)

# Métriques de l'ACP
head(acpv$eig)
head(acpv$var$coord)

# représentation graphique
factoextra::fviz_pca_var(acpv, repel = TRUE) +
  labs(title = "ACP : variables électorales") +
  theme_minimal()

ggsave("sorties/Exemple - ACP Votes Lille MINE.pdf", width = 10, height = 10)

# CAH
cahv<-FactoMineR::HCPC(acpv,metric="euclidean",method="ward",graph =F)
# Description de la CAH
catdes(cahv$data.clust, num.var = 17)$quanti %>%
  lapply(round, 2) %>%
  lapply(function(x) x[ x[, 1] > 5, 1:4])

# récupération de la variable de classe
base <- tibble(BV = base_elec$BV,
               classe_v = as.character(cahv$data.clust[, 17])) %>%
  dplyr::full_join(base, by = "BV")

questionr::freq(base$classe_v)

### I.2 Sélection des bureaux

## Croisement des deux classifications
table(base$classe_sd,base$classe_v)

## Examen des parangons de chaque classe
cahv$desc.ind$para
cahsd$desc.ind$para

## Examen des classes de chaque BV
base[,c("BV","classe_v","classe_sd")]

## À partir d'une liste des adresses des bureaux, on essaye de trouver :
# Des bureaux isolés (éviter les double bureaux car on n'est pas sûr de pouvoir sélectionner les répondant·es à la sortie)
# Des bureaux au croisement de classes bien représentées
# Des bureaux parangons d'une classe
