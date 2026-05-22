---
livrable: "01 — Architecture technique"
scope: "01-architecture"
section: "MCD WMS-DB V4 officielle"
version: "4.0-final"
status: "valide"
owner: "Ianis"
reviewers: ["Blaise", "Zaid", "Ojvind"]
contributors: ["Ianis"]
ia_used: ["Claude Code", "GPT-5 Codex"]
created: "2026-05-20"
updated: "2026-05-21"
related:
  - "./wms-mcd.mcd"
  - "./wms-mcd.svg"
  - "./wms-mcd.png"
  - "./mcd-operationnel.md"
  - "./convergence/convergence-mcd-v2.md"
  - "./convergence/arbitrages-v4-ianis.md"
  - "./propositions/wms-mcd-v3-gpt.md"
  - "./ressources/sujet-mspr3.pdf"
---

# MCD WMS-DB — V4 officielle

> Version officielle après convergence Claude × GPT (V3) puis arbitrages Ianis sur 5 points d'attaque soutenance (V4). Elle remplace la V3 du 2026-05-21 matin. Historique complet dans [`convergence/arbitrages-v4-ianis.md`](convergence/arbitrages-v4-ianis.md).

## 1. Décisions intégrées

| Sujet | Décision finale |
|---|---|
| Périmètre | V1/V4 compacte à 8 entités : cœur WMS défendable en soutenance, FOURNISSEUR extrait. |
| `ARTICLE` | Identifiant composite classique `(CODE_CLIENT, REFERENCE)`. Syntaxe Mocodo sans underscore (notation entité faible écartée). |
| `STOCK` | **Entité réifiée dépendante** du couple `(ARTICLE, EMPLACEMENT)`. 2 associations binaires `stock_de` et `localise_dans` (ternaire `stockage` écartée pour lisibilité Merise). Unicité métier obligatoire au MLD : `UNIQUE(id_article, id_emplacement)`. |
| Mouvement article | Association renommée `concerne` au lieu de `deplace_par`. |
| Multi-tenant visible | Association directe `realise_pour CLIENT-MOUVEMENT` ajoutée pour rendre la séparation client visible au MCD (pas seulement dérivée via ARTICLE). |
| Fournisseur | Extrait en entité `FOURNISSEUR` (référentiel global NTL). Association `fournit, 0N FOURNISSEUR, 01 ARTICLE` (optionnel — un article peut être créé sans fournisseur connu). |
| Site des transactions | Pas d'association directe `SITE — MOUVEMENT` au MCD. Au MLD, `id_site` dénormalisé sur `mouvements` pour garantir TRANSFERT intra-site via FK composite déclarative. |
| Ajustement | Pas d'ajustement global de site : tout `AJUSTEMENT` cible exactement un emplacement. Contrainte XOR portée au DDL via `CHECK ck_mvt_src_dst` (non Merisable en cardinalités). |
| Transfert | `TRANSFERT` intra-site uniquement. Garantie déclarative via FK composite `(id_depart, id_site)` et `(id_arrivee, id_site)` vers `emplacements`. |
| Séparation client | Option D : FK composite déclarative `(id_article, id_client)` vers `articles(id_article, id_client)` au MLD/DDL. |

## 2. Entités (8)

| # | Entité | Rôle opérationnel | Identifiant Merise | Attributs métier |
|---|---|---|---|---|
| 1 | `CLIENT` | Donneur d'ordre B2B propriétaire du catalogue | `CODE_CLIENT` | raison_sociale, siret, contact_nom, contact_email, adresse, status |
| 2 | `ARTICLE` | Référence produit rattachée à un client | `(CODE_CLIENT, REFERENCE)` | libelle, poids, longueur, largeur, hauteur |
| 3 | `FOURNISSEUR` | Référentiel global NTL des fournisseurs | `CODE_FOURNISSEUR` | raison_sociale |
| 4 | `SITE` | Site physique NTL | `CODE_SITE` | nom, adresse |
| 5 | `EMPLACEMENT` | Localisation physique dans un site | `CODE` | zone, allee, etagere, niveau, type_emplacement |
| 6 | `STOCK` | État courant d'un article dans un emplacement (entité réifiée dépendante) | `ID_STOCK` (surrogate) | quantite, date_maj |
| 7 | `MOUVEMENT` | Journal horodaté des entrées, sorties, transferts et ajustements | `NUMERO_MVT` | type_mouvement, quantite, date_mouvement |
| 8 | `UTILISATEUR` | Opérateur ou administrateur WMS | `LOGIN` | nom, prenom, role |

`ARTICLE` aurait pu être modélisé comme entité faible relative à `CLIENT` en Merise pur. La V4 garde l'identifiant composite classique car la règle `(CODE_CLIENT, REFERENCE)` reste directement lisible sur le diagramme et plus simple à défendre comme « PK composite » qu'« entité faible avec association `_11` ».

`STOCK` est une **entité réifiée dépendante** du couple `(ARTICLE, EMPLACEMENT)` : ce n'est pas une entité indépendante (un STOCK n'existe pas sans un article ni sans un emplacement), mais on lui donne un identifiant technique `ID_STOCK` pour qu'elle soit référençable simplement par l'application. L'unicité métier `(ARTICLE, EMPLACEMENT)` reste obligatoire et matérialisée au MLD par `UNIQUE(id_article, id_emplacement)`.

`FOURNISSEUR` est un **référentiel mutualisé** au niveau NTL : tous les clients piochent dans la même liste de fournisseurs. Choix opérationnel assumé (simplicité de gestion référentielle) ; un modèle scoped par client serait plus rigoureux multi-tenant mais inutilement complexe pour le périmètre V1.

## 3. Associations (10)

| Association | Type | Entités liées | Cardinalités Merise | Règle métier |
|---|---|---|---|---|
| `possede` | binaire | `CLIENT` — `ARTICLE` | `(0,N)` — `(1,1)` | un article appartient à un seul client |
| `fournit` | binaire | `FOURNISSEUR` — `ARTICLE` | `(0,N)` — `(0,1)` | un article peut être fourni par 0 ou 1 fournisseur (optionnel) |
| `contient` | binaire | `SITE` — `EMPLACEMENT` | `(1,N)` — `(1,1)` | chaque emplacement appartient à un seul site |
| `stock_de` | binaire | `ARTICLE` — `STOCK` | `(0,N)` — `(1,1)` | chaque ligne de stock concerne exactement un article |
| `localise_dans` | binaire | `EMPLACEMENT` — `STOCK` | `(0,N)` — `(1,1)` | chaque ligne de stock est dans exactement un emplacement |
| `concerne` | binaire | `ARTICLE` — `MOUVEMENT` | `(0,N)` — `(1,1)` | chaque mouvement concerne un seul article |
| `realise_pour` | binaire | `CLIENT` — `MOUVEMENT` | `(0,N)` — `(1,1)` | chaque mouvement est réalisé pour le compte d'un client (traçabilité multi-tenant explicite) |
| `effectue` | binaire | `UTILISATEUR` — `MOUVEMENT` | `(0,N)` — `(1,1)` | chaque mouvement est saisi par un utilisateur |
| `depart` | binaire | `EMPLACEMENT` — `MOUVEMENT` | `(0,N)` — `(0,1)` | emplacement source optionnel selon le type de mouvement |
| `arrivee` | binaire | `EMPLACEMENT` — `MOUVEMENT` | `(0,N)` — `(0,1)` | emplacement destination optionnel selon le type de mouvement |

Le cycle apparent `CLIENT — possede — ARTICLE — concerne — MOUVEMENT — realise_pour — CLIENT` est **assumé volontairement** : `realise_pour` n'est pas une redondance dérivable, c'est une contrainte de traçabilité explicite. La cohérence entre les deux chemins (via ARTICLE et via `realise_pour`) est verrouillée au MLD par la FK composite option D (`mouvements(id_article, id_client) → articles(id_article, id_client)`).

## 4. Règles à descendre au MLD/DDL

- `articles` : `PRIMARY KEY(id_article)`, `UNIQUE(id_client, reference)`, `UNIQUE(id_article, id_client)` (pour la FK composite option D).
- `articles.id_fournisseur` : FK simple vers `fournisseurs(id_fournisseur)`, nullable (cardinalité `01`).
- `stocks` : `UNIQUE(id_article, id_emplacement)` pour garantir une seule ligne de stock courant par couple article/emplacement.
- `stocks` et `mouvements` : FK composite `(id_article, id_client) REFERENCES articles(id_article, id_client)` pour empêcher une incohérence client/article (option D).
- `mouvements.id_client` : matérialise l'association `realise_pour` et participe à la FK composite ci-dessus. Une seule colonne, pas de duplication.
- `mouvements.id_site` : **colonne dénormalisée** portant le site dérivé de l'emplacement. Garantit la règle TRANSFERT intra-site via FK composite déclarative.
- `emplacements` : `UNIQUE(id_emplacement, id_site)` pour permettre les FK composites depuis `mouvements`.
- `mouvements` FK composites :
  - `(id_depart, id_site) REFERENCES emplacements(id_emplacement, id_site)` si depart non NULL ;
  - `(id_arrivee, id_site) REFERENCES emplacements(id_emplacement, id_site)` si arrivee non NULL ;
  - → garantit déclarativement que tout emplacement renseigné appartient au site du mouvement, donc TRANSFERT intra-site.
- `mouvements.type_mouvement` :
  - `ENTREE` : `depart` NULL, `arrivee` NOT NULL ;
  - `SORTIE` : `depart` NOT NULL, `arrivee` NULL ;
  - `TRANSFERT` : `depart` NOT NULL, `arrivee` NOT NULL, `depart <> arrivee` (intra-site garanti par les FK composites) ;
  - `AJUSTEMENT` : exactement un des deux emplacements est renseigné (XOR).
- Contrainte conditionnelle XOR pour AJUSTEMENT et combinaisons type/depart/arrivee : portée par `CHECK ck_mvt_src_dst` (non Merisable en cardinalités classiques).

## 5. Source Mocodo

Source : [`wms-mcd.mcd`](wms-mcd.mcd)

```mocodo
FOURNISSEUR: CODE_FOURNISSEUR, raison_sociale
fournit, 0N FOURNISSEUR, 01 ARTICLE
:
:
:
:

possede, 0N CLIENT, 11 ARTICLE
ARTICLE: CODE_CLIENT, REFERENCE, libelle, poids, longueur, largeur, hauteur
stock_de, 0N ARTICLE, 11 STOCK
STOCK: ID_STOCK, quantite, date_maj
:
:

CLIENT: CODE_CLIENT, raison_sociale, siret, contact_nom, contact_email, adresse, status
concerne, 0N ARTICLE, 11 MOUVEMENT
:
localise_dans, 0N EMPLACEMENT, 11 STOCK
:
:

realise_pour, 0N CLIENT, 11 MOUVEMENT
MOUVEMENT: NUMERO_MVT, type_mouvement, quantite, date_mouvement
arrivee, 0N EMPLACEMENT, 01 MOUVEMENT
EMPLACEMENT: CODE, zone, allee, etagere, niveau, type_emplacement
contient, 1N SITE, 11 EMPLACEMENT
SITE: CODE_SITE, nom, adresse

UTILISATEUR: LOGIN, nom, prenom, role
effectue, 0N UTILISATEUR, 11 MOUVEMENT
depart, 0N EMPLACEMENT, 01 MOUVEMENT
:
:
:
```

Rendus générés : [`wms-mcd.svg`](wms-mcd.svg) et [`wms-mcd.png`](wms-mcd.png). Layout testé sans chevauchement avec `--detect_overlaps`.

Commande de régénération :

```powershell
python -m mocodo --input wms-mcd.mcd --output_dir . --svg_to png --detect_overlaps
```

## 6. Domaines de valeurs

Les attributs typés ci-dessous sont contraints au DDL via `CHECK IN (...)` (non Merisables au MCD).

| Attribut | Valeurs autorisées |
|---|---|
| `CLIENT.status` | `actif`, `suspendu`, `resilie` |
| `UTILISATEUR.role` | `operateur`, `cariste`, `admin` |
| `EMPLACEMENT.type_emplacement` | `rack`, `picking`, `masse`, `quai` |
| `MOUVEMENT.type_mouvement` | `ENTREE`, `SORTIE`, `TRANSFERT`, `AJUSTEMENT` |

Les timestamps techniques (`created_at`, `updated_at`) sont ajoutés au DDL par convention universelle sur toutes les tables, hors scope MCD conceptuel.

## 7. Limites assumées

Cette V4 reste un cœur WMS compact (8 entités). Hors périmètre : lots/DLC/FEFO, commandes, réceptions/expéditions détaillées, transporteurs, réservation de stock, destinataires finaux.

Ces objets sont des évolutions V2 fonctionnelles, pas des oublis du MCD de soutenance.

## 8. Historique versions

| Version | Date | Changements clés |
|---|---|---|
| 0.7 | 2026-05-20 | Complétion MCD avec `tracable_pour` et `porte_pour` (verrou MLD redondant) |
| 3.0-gpt | 2026-05-21 | Convergence Claude × GPT, 8 points consensuels, 2 arbitrages Ianis ouverts |
| 3.1-final | 2026-05-21 | V3 matérialisée à la racine, arbitrages points 9 et 10 tranchés |
| **4.0-final** | **2026-05-21** | **Revue critique 5 attaques soutenance + arbitrages Ianis : STOCK 2 binaires, FOURNISSEUR extrait, `realise_pour` réintroduit, `id_site` dénormalisé pour TRANSFERT intra-site déclaratif** |
