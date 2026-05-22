---
livrable: "01 — Architecture technique"
scope: "01-architecture"
section: "DDL MariaDB 11.4 — V2"
version: "2.0"
status: "à tester"
owner: "Ianis"
created: "2026-05-22"
updated: "2026-05-22"
related:
  - "./wms-schema.sql"
  - "../mld/wms-mld.md"
  - "../mcd/wms-mcd.md"
---

# DDL WMS — V2 MariaDB 11.4

> Implémentation SQL du MLD V2 (5 fixes MCD appliqués). Script unique : [`wms-schema.sql`](wms-schema.sql).

## 1. Cible technique

| Élément | Valeur |
|---|---|
| SGBD | MariaDB 11.4 LTS |
| Moteur de stockage | InnoDB (FK + transactions ACID) |
| Charset | `utf8mb4` |
| Collation | `utf8mb4_unicode_ci` |
| Contraintes CHECK | Supportées nativement depuis MariaDB 10.2 |

## 2. Changements vs V1

| # | Élément | V1 | V2 |
|---|---|---|---|
| 1 | Nombre de tables | 9 (incl. `article_stock`) | **8** (`article_stock` supprimée) |
| 2 | FK `stock.id_article` | absente | **NOT NULL** (nouveau) |
| 3 | UNIQUE `stock(id_article, id_localisation)` | absent | **présent** (1 ligne de stock par couple article × emplacement) |
| 4 | `mouvement.id_stock` | NULL, ON DELETE SET NULL | **NOT NULL**, ON DELETE RESTRICT |
| 5 | `mouvement.quantite` | absente | **NOT NULL**, CHECK > 0 |
| 6 | `mouvement.id_client` | absente | **NULL**, ON DELETE RESTRICT |

## 3. Ordre de création

L'ordre est imposé par les dépendances FK :

1. `site` (racine, aucune FK)
2. `localisation` → FK `site`
3. `utilisateur` (racine)
4. `client` → FK `utilisateur`
5. `article` (racine)
6. `stock` → FK `article`, `localisation`
7. `mouvement` → FK `stock`, `utilisateur`, `client`
8. `commande` (associative) → FK `client`, `article`

## 4. Contraintes appliquées

### 4.1 Clés primaires
Toutes auto-incrémentées `INT UNSIGNED`.

### 4.2 Clés étrangères

| Table | Colonne | Référence | ON DELETE | Raison |
|---|---|---|---|---|
| `localisation` | `id_site` | `site(id_site)` | RESTRICT | Refus suppression site avec localisations |
| `client` | `id_utilisateur` | `utilisateur(id_utilisateur)` | RESTRICT | Gestionnaire ne peut être supprimé s'il a des clients |
| `stock` | `id_article` | `article(id_article)` | RESTRICT | Refus suppression article tant qu'il a du stock |
| `stock` | `id_localisation` | `localisation(id_localisation)` | RESTRICT | Pas de stock orphelin |
| `mouvement` | `id_stock` | `stock(id_stock)` | RESTRICT | Traçabilité — un stock avec mouvements ne peut être supprimé |
| `mouvement` | `id_utilisateur` | `utilisateur(id_utilisateur)` | RESTRICT | Traçabilité humaine obligatoire |
| `mouvement` | `id_client` | `client(id_client)` | RESTRICT | Si client supprimé, refus tant que mouvements existent |
| `commande` | `id_client`, `id_article` | client / article | RESTRICT | Protection métier |

### 4.3 Contraintes UNIQUE

| Table | Colonne(s) | Justification |
|---|---|---|
| `localisation` | `code` | Code physique unique d'emplacement |
| `client` | `siret` | Identifiant légal unique |
| `mouvement` | `reference` | Numéro de traçabilité métier |
| `stock` | `(id_article, id_localisation)` | **V2** : pas deux lignes de stock pour le même couple article × emplacement |

### 4.4 Contraintes CHECK

| Table | Nom | Règle |
|---|---|---|
| `article` | `ck_article_poids` | `poids > 0` |
| `commande` | `ck_commande_quantite` | `quantite_commandee > 0` |
| `mouvement` | `ck_mouvement_type` | `type IN ('entree','sortie','ajustement','transfert')` |
| `mouvement` | `ck_mouvement_quantite` | **V2** : `quantite > 0` |

## 5. Index secondaires

- `idx_localisation_site`
- `idx_client_utilisateur`
- `idx_stock_article` ★ V2
- `idx_stock_localisation`
- `idx_mouvement_date`
- `idx_mouvement_stock`
- `idx_mouvement_utilisateur`
- `idx_mouvement_client` ★ V2
- `idx_commande_client`
- `idx_commande_article`

## 6. Exécution

```bash
mysql -h <host> -u <user> -p

CREATE DATABASE wms CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE wms;

SOURCE 01-architecture-technique/ddl/wms-schema.sql;

SHOW TABLES;
-- Attendu : 8 tables (V2)
--   article, client, commande, localisation, mouvement, site, stock, utilisateur
```

## 7. Vérifications post-exécution

```sql
-- Compter les tables (attendu : 8)
SELECT COUNT(*) AS nb_tables
FROM information_schema.tables
WHERE table_schema = 'wms';

-- Vérifier les FK (attendu : 10 contraintes FK)
SELECT COUNT(*) AS nb_fk
FROM information_schema.referential_constraints
WHERE constraint_schema = 'wms';

-- Vérifier les CHECK (attendu : 4)
SELECT COUNT(*) AS nb_check
FROM information_schema.check_constraints
WHERE constraint_schema = 'wms';
```

## 8. Statut tests

À ce stade le script V2 n'a **pas encore** été exécuté sur MariaDB 11.4. À faire :

- [ ] Exécution sur instance MariaDB 11.4 locale
- [ ] Vérification des 4 CHECK (insérer poids=0, qté_cmd=0, type='foo', qté_mvt=0 → doit échouer)
- [ ] Vérification des 10 FK (insérer FK invalide → doit échouer)
- [ ] Test UNIQUE `stock(id_article, id_localisation)` (2 lignes même couple → doit échouer)
- [ ] Test ON DELETE RESTRICT sur `mouvement.id_stock` (supprimer stock avec mouvement → doit échouer)
- [ ] Test NULL autorisé sur `mouvement.id_client` (insertion mouvement de type 'transfert' sans client → doit passer)

## 9. Écarts V2 vs MCD strict

Aucun. Le MCD V2 et le DDL V2 sont alignés (la divergence V1 sur la cardinalité `EFFECTUER` n'a plus lieu d'être : le MCD a été corrigé en `(0,N)` côté STOCK).
