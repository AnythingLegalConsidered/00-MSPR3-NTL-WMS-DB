---
id: "0003"
titre: "Postulat de cadrage NTL : grossiste (pas 3PL) — modèle WMS V2"
statut: "VALIDÉ — 2026-05-22"
created: "2026-05-22"
updated: "2026-05-22"
owner: "Ianis + Blaise (modèle de données)"
impact: "structurant — MCD/MLD/DDL (livrable 1), note direction (livrable 8), périmètre multi-tenant"
related:
  - "../01-architecture-technique/mcd/wms-mcd.md"
  - "../01-architecture-technique/mld/wms-mld.md"
  - "../01-architecture-technique/ddl/wms-schema.sql"
  - "0001-bug-mariadb-check.md"
  - "../07-gestion-projet/journal-decisions.md"
---

# 0003 — Postulat de cadrage NTL : grossiste, et conséquences sur le modèle

## Problème en 3 lignes

Le sujet MSPR3 décrit NTL comme une « PME de **logistique** » et exige (§II.1) une « **séparation des données par client** ». Or il ne précise pas la **nature de l'activité** : NTL est-elle un **grossiste** (achète, stocke son propre stock, revend) ou un **prestataire logistique 3PL** (stocke et manipule le stock *appartenant à ses clients*) ? Cette ambiguïté change radicalement le modèle de données.

## Pourquoi ça change tout

| | Hypothèse **3PL** | Hypothèse **grossiste** (retenue) |
|---|---|---|
| Propriété du stock | les clients | NTL |
| « Séparation par client » | **isolation forte** (multi-tenant : un client ne doit jamais voir le stock d'un autre) | **attribution** (savoir quel client a commandé / reçu quoi) |
| Modèle | FK composite `(id_article, id_client)`, cloisonnement déclaratif | FK simple `mouvement.id_client` nullable + table `commande` |
| Complexité | élevée (intégrité multi-tenant vérifiée par le moteur) | maîtrisée |

## Options évaluées

### Option A — Postulat grossiste ✅ RETENUE

**Pour**
- Lecture cohérente d'une PME des Hauts-de-France qui possède 4 sites de stockage et revend : achat → stockage propre → revente.
- Modèle **simple, lisible, défendable** en V1 sur 19h × 4 personnes.
- La « séparation par client » exigée par le sujet est assurée par l'**attribution** : chaque `commande` et chaque `mouvement` de sortie porte un `id_client`. On sait parfaitement *qui a commandé / reçu quoi*.
- Réversible : si NTL pivote vers du 3PL, on réintroduit la FK composite `(id_article, id_client)` en V2.

**Contre**
- Lecture plus *littérale* du §II.1 (« séparation ») pencherait vers une isolation multi-tenant, qu'on n'implémente pas. **Assumé** : on tranche une ambiguïté, on ne l'ignore pas.

### Option B — Postulat 3PL / multi-tenant ❌ ÉCARTÉE en V1

**Pour**
- Lecture la plus stricte de « séparation des données par client ».
- Techniquement plus riche (FK composite, isolation vérifiée par InnoDB).

**Contre**
- Complexité nettement supérieure (intégrité multi-tenant, FK composites, contraintes croisées) pour un gain non justifié tant que la nature 3PL de NTL n'est pas confirmée par le client.
- Risque de **sur-ingénierie** d'un besoin non avéré, au détriment du reste des 9 livrables.

## Décision finale

**NTL est modélisée comme un grossiste** (stock propre). Le modèle WMS V2 en découle :

1. **Multi-tenant retiré** — pas de FK composite `(id_article, id_client)`. La séparation client = attribution via `mouvement.id_client` (nullable) et la table `commande`.
2. **FOURNISSEUR dé-entifié** — redevient un attribut texte `article.fournisseur`. La gestion achats/fournisseurs est hors périmètre V1 (portée par l'ERP commercial NTL).
3. **Table `commande`** ajoutée (associative CLIENT ↔ ARTICLE) pour porter la relation commerciale.
4. **Modèle final : 8 tables, 0 trigger, 0 FK composite.** Cf. `wms-schema.sql`.

## Conséquence : invalidation de décisions antérieures

Ce postulat **remplace** les décisions prises sous l'hypothèse multi-tenant initiale :

- **D02** (multi-tenant FK composite « option D ») → SUPERSEDED.
- **D03** (TRANSFERT intra-site garanti par FK composite `(id_depart, id_site)`) → SUPERSEDED. Le modèle grossiste n'a ni `id_depart`/`id_arrivee` ni `id_site` sur `mouvement` (un mouvement référence un seul `id_stock`).
- **D04** + **ADR [0001](0001-bug-mariadb-check.md)** (bug parser MariaDB sur CHECK + FK composites, contourné par triggers) → **sans objet** : sans FK composite sur `mouvement`, le bug ne se déclenche pas. Le DDL V2 n'a aucun trigger.

## Arguments pour la soutenance (à graver)

1. **On a identifié une ambiguïté** du cahier des charges (grossiste vs 3PL) au lieu de la subir.
2. **On a tranché par un postulat explicite** (grossiste), documenté ici, plutôt que de deviner.
3. **La séparation par client est assurée** par l'attribution (`commande`, `mouvement.id_client`).
4. **L'isolation multi-tenant est une évolution V2** conditionnée à une bascule métier vers le 3PL — pas un oubli, une décision de périmètre réversible.

## Piège à éviter en soutenance

Ne **pas** dire « on n'a pas compris le sujet » ni « le multi-tenant était trop dur ».
Dire : **« le sujet est ambigu sur la nature de NTL ; on a posé un postulat grossiste explicite et cadré la V1 dessus, l'isolation multi-tenant étant réservée à une éventuelle V2 3PL »**.

## Mise à jour

- 2026-05-22 : postulat grossiste acté, modèle V2 dérivé (MCD/MLD/DDL). ADR formalisé a posteriori pour tracer le pivot depuis l'hypothèse multi-tenant initiale.
