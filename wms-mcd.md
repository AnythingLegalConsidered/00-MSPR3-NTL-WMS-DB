---
livrable: "01 — Architecture technique"
scope: "01-architecture"
section: "MCD WMS-DB V3 officielle"
version: "3.1-final"
status: "valide"
owner: "Ianis"
reviewers: ["Blaise", "Zaid", "Ojvind"]
contributors: ["Ianis"]
ia_used: ["GPT-5 Codex"]
created: "2026-05-20"
updated: "2026-05-21"
related:
  - "./wms-mcd.mcd"
  - "./wms-mcd.svg"
  - "./wms-mcd.png"
  - "./mcd-operationnel.md"
  - "./convergence/convergence-mcd-v2.md"
  - "./propositions/wms-mcd-v3-gpt.md"
  - "./ressources/sujet-mspr3.pdf"
---

# MCD WMS-DB — V3 officielle

> Version officielle après convergence Claude × GPT et arbitrages Ianis du 2026-05-21. Elle remplace l'ancien MCD racine v0.8.

## 1. Décisions intégrées

| Sujet | Décision finale |
|---|---|
| Périmètre | V1/V3 compacte à 7 entités : cœur WMS défendable en soutenance. |
| `ARTICLE` | Identifiant composite classique `(CODE_CLIENT, REFERENCE)`, rendu Mocodo par `ARTICLE: CODE_CLIENT, _REFERENCE`. |
| `STOCK` | Entité associative renforcée avec identifiant technique `ID_STOCK` et unicité métier obligatoire `(ARTICLE, EMPLACEMENT)`. |
| Stockage | Association ternaire `stockage(ARTICLE, STOCK, EMPLACEMENT)`. |
| Mouvement article | Association renommée `concerne` au lieu de `deplace_par`. |
| Site des transactions | Pas d'association directe `SITE — MOUVEMENT` : le site est dérivé via l'emplacement de départ ou d'arrivée. |
| Ajustement | Pas d'ajustement global de site : tout `AJUSTEMENT` cible un emplacement précis. |
| Transfert | `TRANSFERT` intra-site uniquement ; un inter-site se modélise par une sortie site A puis une entrée site B. |
| Séparation client | Option D validée : FK composite déclarative `(id_article, id_client)` vers `articles(id_article, id_client)` au MLD/DDL. |

## 2. Entités

| # | Entité | Rôle opérationnel | Identifiant Merise | Attributs métier |
|---|---|---|---|---|
| 1 | `CLIENT` | Donneur d'ordre B2B propriétaire du catalogue | `CODE_CLIENT` | raison_sociale, siret, contact_nom, contact_email, adresse, status |
| 2 | `ARTICLE` | Référence produit rattachée à un client | `(CODE_CLIENT, REFERENCE)` | libelle, poids, longueur, largeur, hauteur, fournisseur |
| 3 | `SITE` | Site physique NTL | `CODE_SITE` | nom, adresse |
| 4 | `EMPLACEMENT` | Localisation physique dans un site | `CODE` | zone, allee, etagere, niveau, type_emplacement |
| 5 | `STOCK` | État courant d'un article dans un emplacement | `ID_STOCK` | quantite, date_maj |
| 6 | `MOUVEMENT` | Journal horodaté des entrées, sorties, transferts et ajustements | `NUMERO_MVT` | type_mouvement, quantite, date_mouvement |
| 7 | `UTILISATEUR` | Opérateur ou administrateur WMS | `LOGIN` | nom, prenom, role |

`ARTICLE` pourrait être modélisé comme entité faible relative à `CLIENT` en Merise pur. La V3 garde l'identifiant composite classique car la règle `(CODE_CLIENT, REFERENCE)` reste directement lisible sur le diagramme.

`STOCK` garde `ID_STOCK` pour être référencé simplement par l'application. L'unicité métier reste le couple `(ARTICLE, EMPLACEMENT)` et doit être matérialisée au MLD/DDL par `UNIQUE(id_article, id_emplacement)`.

## 3. Associations et cardinalités

| Association | Type | Entités liées | Cardinalités Merise | Règle métier |
|---|---|---|---|---|
| `possede` | binaire | `CLIENT` - `ARTICLE` | `(0,N)` - `(1,1)` | un article appartient à un seul client |
| `contient` | binaire | `SITE` - `EMPLACEMENT` | `(1,N)` - `(1,1)` | chaque emplacement appartient à un seul site |
| `stockage` | ternaire | `ARTICLE` - `STOCK` - `EMPLACEMENT` | `(0,N)` - `(1,1)` - `(0,N)` | une ligne de stock concerne exactement un couple article/emplacement |
| `concerne` | binaire | `ARTICLE` - `MOUVEMENT` | `(0,N)` - `(1,1)` | chaque mouvement concerne un seul article |
| `effectue` | binaire | `UTILISATEUR` - `MOUVEMENT` | `(0,N)` - `(1,1)` | chaque mouvement est saisi par un utilisateur |
| `depart` | binaire | `EMPLACEMENT` - `MOUVEMENT` | `(0,N)` - `(0,1)` | emplacement source optionnel selon le type de mouvement |
| `arrivee` | binaire | `EMPLACEMENT` - `MOUVEMENT` | `(0,N)` - `(0,1)` | emplacement destination optionnel selon le type de mouvement |

## 4. Règles à descendre au MLD/DDL

- `articles` : `PRIMARY KEY(id_article)`, `UNIQUE(id_client, reference)` et `UNIQUE(id_article, id_client)`.
- `stocks` : `UNIQUE(id_article, id_emplacement)` pour garantir une seule ligne de stock courant par couple article/emplacement.
- `stocks` et `mouvements` : FK composite `(id_article, id_client) REFERENCES articles(id_article, id_client)` pour empêcher une incohérence client/article.
- `mouvements.type_mouvement` :
  - `ENTREE` : `depart` NULL, `arrivee` NOT NULL ;
  - `SORTIE` : `depart` NOT NULL, `arrivee` NULL ;
  - `TRANSFERT` : `depart` NOT NULL, `arrivee` NOT NULL, `depart <> arrivee`, même site ;
  - `AJUSTEMENT` : exactement un des deux emplacements est renseigné.
- Site d'une transaction : dérivé de `depart.site` ou `arrivee.site`. Si les deux emplacements sont renseignés, ils doivent appartenir au même site.

## 5. Source Mocodo

Source : [`wms-mcd.mcd`](wms-mcd.mcd)

```mocodo
CLIENT: CODE_CLIENT, raison_sociale, siret, contact_nom, contact_email, adresse, status
possede, 0N CLIENT, 11 ARTICLE
ARTICLE: CODE_CLIENT, _REFERENCE, libelle, poids, longueur, largeur, hauteur, fournisseur
concerne, 0N ARTICLE, 11 MOUVEMENT

stockage, 0N ARTICLE, 11 STOCK, 0N EMPLACEMENT
:
:
MOUVEMENT: NUMERO_MVT, type_mouvement, quantite, date_mouvement

:
STOCK: ID_STOCK, quantite, date_maj
depart, 0N EMPLACEMENT, 01 MOUVEMENT
effectue, 0N UTILISATEUR, 11 MOUVEMENT

:
EMPLACEMENT: CODE, zone, allee, etagere, niveau, type_emplacement
arrivee, 0N EMPLACEMENT, 01 MOUVEMENT
UTILISATEUR: LOGIN, nom, prenom, role

:
contient, 1N SITE, 11 EMPLACEMENT
:
:

:
SITE: CODE_SITE, nom, adresse
```

Rendus générés : [`wms-mcd.svg`](wms-mcd.svg) et [`wms-mcd.png`](wms-mcd.png).

Commande de régénération :

```powershell
python -m mocodo --input wms-mcd.mcd --output_dir . --svg_to png
```

## 6. Limites assumées

Cette V3 reste un cœur WMS compact. Hors périmètre : lots/DLC/FEFO, commandes, réceptions/expéditions détaillées, transporteurs, réservation de stock, destinataires finaux et référentiel fournisseurs dédié.

Ces objets restent des évolutions V2 fonctionnelles, pas des oublis du MCD de soutenance.
