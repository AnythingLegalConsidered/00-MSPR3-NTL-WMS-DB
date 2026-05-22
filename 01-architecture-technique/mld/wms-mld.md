---
livrable: "01 — Architecture technique"
scope: "01-architecture"
section: "MLD WMS — V2 (grossiste, 5 fixes appliqués)"
version: "2.0"
status: "valide"
owner: "Ianis"
created: "2026-05-22"
updated: "2026-05-22"
related:
  - "../mcd/wms-mcd.md"
  - "../ddl/wms-schema.sql"
---

# MLD WMS — V2

> Dérivé direct de [`mcd/wms-mcd.md`](../mcd/wms-mcd.md) V2. Conventions inchangées : `snake_case`, PK `id_*` auto-incrémentée `INT UNSIGNED`, attributs accentués normalisés en ASCII.

## 1. Changements vs V1

| # | Élément | V1 | V2 |
|---|---|---|---|
| 1 | `mouvement.id_stock` | `NULL`, FK avec `ON DELETE SET NULL` | **`NOT NULL`**, FK avec `ON DELETE RESTRICT` (cardinalité 1,1 côté MOUVEMENT) |
| 2 | `mouvement.quantite` | absente | **présente** `INT UNSIGNED NOT NULL CHECK (quantite > 0)` |
| 3 | `mouvement.id_client` | absente | **présente** `INT UNSIGNED NULL` FK → `client(id_client)` (association CONCERNE 0,1) |
| 4 | Table `article_stock` (N-N) | 9 tables au total | **supprimée** — remplacée par FK `id_article` directe dans `stock` (cardinalité 1,1 côté STOCK) |
| 5 | `stock.id_article` | inexistante | **présente** `INT UNSIGNED NOT NULL` FK → `article(id_article)` |

**Bilan : 8 tables au lieu de 9. 1 colonne en plus dans `mouvement`. 1 colonne en plus dans `stock`. 0 colonne supprimée.**

## 2. Règles de passage MCD → MLD

| Cas MCD | Règle appliquée |
|---|---|
| Entité | → Table avec PK `id_<entite>` auto-incrémentée |
| Association 1-N (cardinalité max 1 d'un côté) | → FK dans la table côté (1,1) ou (0,1) |
| Association N-N | → Table associative avec PK auto + FK individuelles + attributs métier |
| Attributs accentués / unicode | → Normalisation ASCII pour compat MariaDB / portabilité scripts |

## 3. Tables (8)

### 3.1 Tables issues d'entités (7)

#### `site`
| Colonne | Type | Contrainte |
|---|---|---|
| `id_site` | INT UNSIGNED | PK, AUTO_INCREMENT |
| `libelle` | VARCHAR(100) | NOT NULL |
| `adresse` | VARCHAR(255) | NOT NULL |

#### `localisation`
| Colonne | Type | Contrainte |
|---|---|---|
| `id_localisation` | INT UNSIGNED | PK, AUTO_INCREMENT |
| `code` | VARCHAR(30) | NOT NULL, UNIQUE |
| `zone` | VARCHAR(30) | NOT NULL |
| `allee` | VARCHAR(10) | NOT NULL |
| `etage` | VARCHAR(10) | NOT NULL |
| `place` | VARCHAR(10) | NOT NULL |
| `id_site` | INT UNSIGNED | NOT NULL, FK → `site(id_site)` |

> FK `id_site` issue de `CONTENIR_LS` (LOCALISATION 1,1 — SITE 1,N).

#### `utilisateur`
| Colonne | Type | Contrainte |
|---|---|---|
| `id_utilisateur` | INT UNSIGNED | PK, AUTO_INCREMENT |
| `nom` | VARCHAR(100) | NOT NULL |
| `role` | VARCHAR(30) | NOT NULL |

#### `client`
| Colonne | Type | Contrainte |
|---|---|---|
| `id_client` | INT UNSIGNED | PK, AUTO_INCREMENT |
| `nom` | VARCHAR(100) | NOT NULL |
| `siret` | CHAR(14) | NOT NULL, UNIQUE |
| `telephone` | VARCHAR(20) | NULL |
| `status` | VARCHAR(20) | NOT NULL, DEFAULT 'actif' |
| `id_utilisateur` | INT UNSIGNED | NOT NULL, FK → `utilisateur(id_utilisateur)` |

> FK `id_utilisateur` issue de `ECHANGER` (CLIENT 1,1 — UTILISATEUR 1,N).

#### `article`
| Colonne | Type | Contrainte |
|---|---|---|
| `id_article` | INT UNSIGNED | PK, AUTO_INCREMENT |
| `nom` | VARCHAR(150) | NOT NULL |
| `poids` | DECIMAL(10,3) | NOT NULL, CHECK (poids > 0) |
| `fournisseur` | VARCHAR(100) | NULL |
| `type` | VARCHAR(50) | NOT NULL |

#### `stock` ★ (modifié V2)
| Colonne | Type | Contrainte |
|---|---|---|
| `id_stock` | INT UNSIGNED | PK, AUTO_INCREMENT |
| `quantite` | INT UNSIGNED | NOT NULL, DEFAULT 0 |
| `id_article` | INT UNSIGNED | **NOT NULL**, FK → `article(id_article)` ★ |
| `id_localisation` | INT UNSIGNED | NOT NULL, FK → `localisation(id_localisation)` |

> FK `id_article` issue de `CONTENIR_AS` (STOCK 1,1 — ARTICLE 1,N) — **nouveau V2**.
> FK `id_localisation` issue de `CONTENIR_SL` (STOCK 1,1 — LOCALISATION 1,N).
> Contrainte d'unicité métier : `UNIQUE (id_article, id_localisation)` — pas deux lignes de stock pour le même couple article × emplacement.

#### `mouvement` ★ (modifié V2)
| Colonne | Type | Contrainte |
|---|---|---|
| `id_mouvement` | INT UNSIGNED | PK, AUTO_INCREMENT |
| `type` | VARCHAR(20) | NOT NULL, CHECK IN ('entree','sortie','ajustement','transfert') |
| `reference` | VARCHAR(50) | NOT NULL, UNIQUE |
| `date` | DATE | NOT NULL |
| `heure` | TIME | NOT NULL |
| `quantite` | INT UNSIGNED | **NOT NULL**, CHECK (quantite > 0) ★ |
| `id_stock` | INT UNSIGNED | **NOT NULL**, FK → `stock(id_stock)` ★ (passage NULL→NOT NULL) |
| `id_utilisateur` | INT UNSIGNED | NOT NULL, FK → `utilisateur(id_utilisateur)` |
| `id_client` | INT UNSIGNED | **NULL**, FK → `client(id_client)` ★ |

> FK `id_stock` issue de `EFFECTUER` (STOCK 0,N — MOUVEMENT 1,1) — **MCD V2 corrige le (0,1) qui rendait l'historique impossible**.
> FK `id_utilisateur` issue de `REALISER` (UTILISATEUR 0,N — MOUVEMENT 1,1).
> FK `id_client` issue de **`CONCERNE`** (MOUVEMENT 0,1 — CLIENT 0,N) — **nouveau V2**. NULL autorisé pour mouvements internes (transferts intra-site, ajustements inventaire).

### 3.2 Tables associatives (1)

#### `commande` (CLIENT ↔ ARTICLE)
| Colonne | Type | Contrainte |
|---|---|---|
| `id_commande` | INT UNSIGNED | PK, AUTO_INCREMENT |
| `id_client` | INT UNSIGNED | NOT NULL, FK → `client(id_client)` |
| `id_article` | INT UNSIGNED | NOT NULL, FK → `article(id_article)` |
| `quantite_commandee` | INT UNSIGNED | NOT NULL, CHECK > 0 |
| `date_commande` | DATETIME | NOT NULL, DEFAULT CURRENT_TIMESTAMP |

> Index combiné `(id_client, id_article)` pour requêtes type "qu'a commandé ce client".

> **V2 : table `article_stock` supprimée** — la cardinalité `CONTENIR_AS` est désormais 1-N (STOCK 1,1 — ARTICLE 1,N), portée par la FK `stock.id_article`.

## 4. Schéma relationnel textuel

```
site(id_site, libelle, adresse)
localisation(id_localisation, code, zone, allee, etage, place, #id_site)
utilisateur(id_utilisateur, nom, role)
client(id_client, nom, siret, telephone, status, #id_utilisateur)
article(id_article, nom, poids, fournisseur, type)
stock(id_stock, quantite, #id_article, #id_localisation)
mouvement(id_mouvement, type, reference, date, heure, quantite, #id_stock, #id_utilisateur, #id_client)
commande(id_commande, #id_client, #id_article, quantite_commandee, date_commande)
```

Convention : `#` préfixe une clé étrangère ; soulignement implicite pour la PK (premier champ).

## 5. Diagramme des dépendances FK

```
site ◄── localisation ◄── stock ──► article
                            ▲           ▲
                            │           │
                       mouvement ──► commande
                            │           │
                            ▼           ▼
                      utilisateur    client
                            ▲           ▲
                            │           │
                            └─── client ┘
```

## 6. Index recommandés (au-delà des PK/UK)

| Table | Index | Justification |
|---|---|---|
| `localisation` | `idx_localisation_site (id_site)` | Filtre fréquent localisations d'un site |
| `stock` | `idx_stock_article (id_article)` | Inventaire d'un article |
| `stock` | `idx_stock_localisation (id_localisation)` | Inventaire par emplacement |
| `mouvement` | `idx_mouvement_date (date)` | Reporting journalier |
| `mouvement` | `idx_mouvement_stock (id_stock)` | Historique d'un stock |
| `mouvement` | `idx_mouvement_client (id_client)` | Expéditions d'un client |
| `commande` | `idx_commande_client (id_client)` | Commandes d'un client |
| `client` | `idx_client_utilisateur (id_utilisateur)` | Portefeuille d'un gestionnaire |

## 7. Contraintes d'intégrité

- **CHECK** `article.poids > 0`
- **CHECK** `commande.quantite_commandee > 0`
- **CHECK** `mouvement.quantite > 0` ★ nouveau V2
- **CHECK** `mouvement.type IN ('entree','sortie','ajustement','transfert')`
- **UNIQUE** `client.siret` (un SIRET = un client)
- **UNIQUE** `mouvement.reference` (traçabilité métier)
- **UNIQUE** `localisation.code` (code physique unique)
- **UNIQUE** `stock(id_article, id_localisation)` ★ nouveau V2 — pas deux lignes de stock pour le même article × emplacement
- **ON DELETE RESTRICT** par défaut sur toutes les FK (refus suppression cascade — protection métier)
