---
livrable: "01 — Architecture technique"
scope: "01-architecture"
section: "DDL WMS-DB — script MariaDB 11.4 LTS"
version: "1.0-draft"
status: "draft"
owner: "Ianis"
reviewers: ["Blaise", "Zaid", "Ojvind"]
contributors: ["Ianis"]
created: "2026-05-22"
updated: "2026-05-22"
related:
  - "./wms-mld.md"
  - "./wms-mcd.md"
  - "./ddl/wms-schema.sql"
---

# DDL WMS-DB — MariaDB 11.4 LTS

> Matérialisation exécutable du MLD V1. Script unique : [`ddl/wms-schema.sql`](ddl/wms-schema.sql). Ce document explique comment l'exécuter, le tester, et les choix techniques associés.

## 1. Conventions de nommage

| Préfixe | Type | Exemple |
|---|---|---|
| `pk_` | Primary key | `pk_clients` |
| `uk_` | Unique key | `uk_articles_client_ref` |
| `fk_` | Foreign key | `fk_mouvements_depart_site` |
| `ck_` | Check constraint | `ck_mvt_src_dst` |
| `ix_` | Index additionnel | `ix_mouvements_client_date` |

Toutes les contraintes sont **explicitement nommées** (pas de nom auto-généré InnoDB) pour faciliter l'identification dans les logs d'erreur et les futurs `ALTER`.

## 2. Ordre de création

L'ordre dans `ddl/wms-schema.sql` respecte les dépendances FK :

1. `clients` (indépendant)
2. `fournisseurs` (indépendant)
3. `sites` (indépendant)
4. `utilisateurs` (indépendant)
5. `articles` (FK → clients, fournisseurs)
6. `emplacements` (FK → sites)
7. `stocks` (FK composite → articles, FK → emplacements)
8. `mouvements` (FK composite → articles, FK → sites/utilisateurs, FK composites → emplacements)

## 3. Exécution

### Cible Docker (recommandé pour tests locaux)

```bash
docker run -d --name wms-mariadb \
  -e MARIADB_ROOT_PASSWORD=root \
  -p 3306:3306 \
  mariadb:11.4

docker exec -i wms-mariadb mariadb -uroot -proot < ddl/wms-schema.sql
```

### Cible client natif

```bash
mariadb -u root -p < ddl/wms-schema.sql
```

### Vérification post-exécution

```sql
USE wms;
SHOW TABLES;
-- Attendu : 8 tables (articles, clients, emplacements, fournisseurs,
--                    mouvements, sites, stocks, utilisateurs)

SELECT
  TABLE_NAME,
  CONSTRAINT_NAME,
  CONSTRAINT_TYPE
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = 'wms'
ORDER BY TABLE_NAME, CONSTRAINT_TYPE;
```

## 4. Tests de validation (à écrire dans un script séparé)

Le DDL est correct si les insertions suivantes se comportent comme attendu :

### Tests positifs (doivent réussir)

- Insertion d'un client `actif`, d'un article rattaché, d'un emplacement rack dans un site
- Création d'un stock `quantite = 50` sur ce couple article/emplacement
- Mouvement ENTREE (`id_depart` NULL, `id_arrivee` renseigné)
- Mouvement TRANSFERT entre 2 emplacements du même site

### Tests négatifs (doivent échouer)

| Cas | Erreur attendue |
|---|---|
| Client avec `status = 'inconnu'` | rejet ENUM |
| 2 articles avec même `(id_client, reference)` | violation `uk_articles_client_ref` |
| 2 stocks sur même `(id_article, id_emplacement)` | violation `uk_stocks_article_emplacement` |
| Stock avec `id_article` et `id_client` incohérents (article appartient à un autre client) | violation `fk_stocks_article_client` (option D) |
| Mouvement TRANSFERT entre 2 emplacements de sites différents | violation FK composite `fk_mouvements_depart_site` ou `fk_mouvements_arrivee_site` |
| Mouvement ENTREE avec `id_depart` renseigné | violation `ck_mvt_src_dst` |
| Mouvement TRANSFERT avec `id_depart = id_arrivee` | violation `ck_mvt_src_dst` |
| Mouvement AJUSTEMENT avec les 2 emplacements renseignés | violation `ck_mvt_src_dst` |
| Stock avec `quantite = -1` | violation `ck_stocks_quantite` |
| Suppression d'un client référencé par un article | violation `fk_articles_client` (ON DELETE RESTRICT) |

Ces tests seront formalisés dans `ddl/tests/` (livrable suivant).

## 5. Choix techniques

| Choix | Justification | Référence |
|---|---|---|
| `ENGINE=InnoDB` | seul moteur MariaDB transactionnel avec FK + ACID + Galera | `FAQ.md` |
| `CHARSET=utf8mb4` | vrai UTF-8 (emoji, idéogrammes) — pas `utf8` 3 octets historique | `FAQ.md` |
| `COLLATE=utf8mb4_unicode_ci` | tri Unicode correct, insensible à la casse | — |
| `INT UNSIGNED` pour les PK | 4 octets, plage 0–4.2 milliards suffisante pour V1 et V2 | `wms-mld.md` §1 |
| `TIMESTAMP` pour `date_*` | stockage UTC, conversion auto selon `time_zone` session | — |
| `DECIMAL` pour poids/dimensions | pas de perte de précision (≠ FLOAT) | `wms-mld.md` §2.3 |
| FK toutes en `ON DELETE RESTRICT` | protection de l'historique : suppression métier = soft-delete applicatif | `wms-mld.md` §4 |
| Exception `articles.id_fournisseur` en `SET NULL` | fournisseur supprimé ne doit pas bloquer un article (cardinalité `01`) | `wms-mld.md` §4 |
| Règle `ck_mvt_src_dst` portée par **triggers** au lieu de CHECK | bug parser MariaDB 11.4.10 : conflit entre FK composites `(id_depart, id_site)` / `(id_arrivee, id_site)` et tout CHECK référençant ces colonnes. FK composites prioritaires (verrouillent TRANSFERT intra-site), XOR XOR matérialisé par 2 triggers `BEFORE INSERT` + `BEFORE UPDATE` avec `SIGNAL SQLSTATE '45000'`. Sémantique identique. | §5.bis ci-dessous |

### 5.bis Bug parser MariaDB 11.4 — investigation

**Symptôme** : `ERROR 1901 (HY000): Function or expression 'id_depart' cannot be used in the CHECK clause of 'ck_mvt_src_dst'`.

**Reproduction** : sur MariaDB 11.4.10-MariaDB-ubu2404, déclarer un CHECK référençant `id_depart` ou `id_arrivee` sur la table `mouvements` qui possède les FK composites `(id_depart, id_site) → emplacements` et `(id_arrivee, id_site) → emplacements` est systématiquement rejeté — que ce soit inline dans le `CREATE TABLE` ou via `ALTER TABLE` après création. Le bug est insensible à l'ordre des contraintes, à la complexité du CHECK (même un CHECK trivial à 1 branche est rejeté), et persiste après `DROP CONSTRAINT` puis ré-ajout.

**Tests réalisés** :
- CHECK seul sur table simplifiée (sans FK composites) → OK
- CHECK + FK composites sur table simplifiée (sans timestamps) → OK
- CHECK + FK composites + timestamps sur table complète → KO
- Découpage en 4 CHECK par valeur d'ENUM → KO
- Drop FK composites → ajout CHECK → re-add FK composites → CHECK invalidé au re-add

**Arbitrage** : conserver les FK composites (décision V4 verrouillée, garantie déclarative TRANSFERT intra-site) et porter la règle XOR via triggers. Le coût est limité : 2 triggers symétriques BEFORE INSERT / BEFORE UPDATE, sémantique identique au CHECK initialement prévu (cf. `wms-mcd.md` §4 et `wms-mld.md` §6.1).

**Évolution V2** : retester sur futures versions MariaDB (11.5+, 12.x) ; si le bug est corrigé, revenir au CHECK déclaratif.

## 6. Limites connues

- **Pas de partitioning** sur `mouvements` : croissance linéaire, à reconsidérer au-delà de ~10M lignes (V2).
- **2 triggers sur `mouvements`** (forcés par bug parser MariaDB 11.4, cf. §5.bis) : `tg_mvt_src_dst_ins` et `tg_mvt_src_dst_upd`. Pas de trigger sur la dénormalisation `mouvements.id_site` (renseigné par l'application). Risque d'incohérence si update SQL manuel direct sans passer par l'app — trigger additionnel envisageable en V2.
- **ENUM rigide** : toute nouvelle valeur de statut/rôle/type nécessite `ALTER TABLE` (verrou court). Bascule vers tables de référence prévue V2 si volatilité prouvée.
- **Pas de seed data** : le script crée le schéma vide. Un script `ddl/seed.sql` avec données NTL fictives est à produire pour la démo soutenance.

## 7. Étapes suivantes

- [ ] Script `ddl/tests/test-positifs.sql` + `ddl/tests/test-negatifs.sql`
- [ ] Script `ddl/seed.sql` avec données NTL fictives (3 sites, ~5 clients, ~50 articles, ~200 emplacements, ~10 utilisateurs, ~500 mouvements)
- [ ] Conteneur `docker-compose.yml` pour environnement de dev reproductible
- [ ] Intégration au cluster Galera (livrable HA/PRA)
