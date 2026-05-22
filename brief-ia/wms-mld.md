---
livrable: "01 — Architecture technique"
scope: "01-architecture"
section: "MLD WMS-DB — passage MCD V4 → modèle relationnel MariaDB 11.4"
version: "1.0-draft"
status: "draft"
owner: "Ianis"
reviewers: ["Blaise", "Zaid", "Ojvind"]
contributors: ["Ianis"]
ia_used: ["Claude Code"]
created: "2026-05-22"
updated: "2026-05-22"
related:
  - "./wms-mcd.md"
  - "./convergence/arbitrages-v4-ianis.md"
  - "./README.md"
---

# MLD WMS-DB — passage MCD V4 → modèle relationnel

> Matérialisation du MCD V4 (8 entités, 10 associations) en schéma relationnel cible **MariaDB 11.4 LTS**. Pré-DDL : types SQL, clés, contraintes et index. Le DDL exécutable (`CREATE TABLE`, charset, moteur, ordre d'exécution) est produit dans un livrable séparé.

## 1. Méthodologie passage MCD → MLD

Règles Merise appliquées :

1. **Chaque entité MCD → 1 table** (8 entités → 8 tables).
2. **Identifiants surrogate** : chaque table reçoit une PK technique `id_<entite>` en `INT UNSIGNED AUTO_INCREMENT`. L'identifiant métier MCD (`CODE_CLIENT`, `CODE_SITE`, `LOGIN`, `NUMERO_MVT`, etc.) est conservé comme colonne avec contrainte `UNIQUE NOT NULL` pour traçabilité externe.
   - Justification : surrogate INT = FK plus légères (4 octets vs VARCHAR variable), jointures plus rapides, ALTER plus simple si le code métier change. Pratique industrielle standard.
   - Cas particulier `articles` : la PK composite MCD `(CODE_CLIENT, REFERENCE)` est reconstituée via `UNIQUE(id_client, reference)`. Une `UNIQUE(id_article, id_client)` additionnelle sert de cible aux FK composites option D.
3. **Association binaire (X,N)–(1,1)** → FK simple `NOT NULL` côté table (1,1).
4. **Association binaire (X,N)–(0,1)** → FK simple `NULL` côté table (0,1).
5. **Pas d'association ternaire ni N–N** dans le MCD V4 → aucune table de liaison.
6. **Contrainte XOR conditionnelle** (`ck_mvt_src_dst`) → `CHECK` SQL (non Merisable au MCD).
7. **Domaines de valeurs énumérés** → type `ENUM` MariaDB (équivalent fonctionnel à `VARCHAR + CHECK IN`, plus compact en stockage).
8. **Convention timestamps** : `created_at` / `updated_at` ajoutés à chaque table par convention, hors scope MCD conceptuel.
9. **Charset / collation** : `utf8mb4` / `utf8mb4_unicode_ci` par défaut sur l'ensemble du schéma (support emoji + tri Unicode correct).
10. **Moteur** : `InnoDB` (transactionnel, FK supportées, prérequis Galera HA — cf. livrable HA/PRA).

## 2. Tableau des 8 tables

### 2.1 `clients`

| Colonne | Type SQL | Nullable | Défaut | Note |
|---|---|---|---|---|
| `id_client` | `INT UNSIGNED AUTO_INCREMENT` | NO | — | PK |
| `code_client` | `VARCHAR(20)` | NO | — | identifiant métier MCD |
| `raison_sociale` | `VARCHAR(150)` | NO | — | |
| `siret` | `CHAR(14)` | NO | — | format SIRET français (14 chiffres) |
| `contact_nom` | `VARCHAR(100)` | YES | NULL | |
| `contact_email` | `VARCHAR(150)` | YES | NULL | |
| `adresse` | `VARCHAR(255)` | YES | NULL | |
| `status` | `ENUM('actif','suspendu','resilie')` | NO | `'actif'` | domaine §6 |
| `created_at` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP` | |
| `updated_at` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | |

### 2.2 `fournisseurs`

| Colonne | Type SQL | Nullable | Défaut | Note |
|---|---|---|---|---|
| `id_fournisseur` | `INT UNSIGNED AUTO_INCREMENT` | NO | — | PK |
| `code_fournisseur` | `VARCHAR(20)` | NO | — | identifiant métier MCD |
| `raison_sociale` | `VARCHAR(150)` | NO | — | |
| `created_at` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP` | |
| `updated_at` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | |

### 2.3 `articles`

| Colonne | Type SQL | Nullable | Défaut | Note |
|---|---|---|---|---|
| `id_article` | `INT UNSIGNED AUTO_INCREMENT` | NO | — | PK |
| `id_client` | `INT UNSIGNED` | NO | — | FK → `clients`, matérialise `possede` |
| `id_fournisseur` | `INT UNSIGNED` | YES | NULL | FK → `fournisseurs`, matérialise `fournit` (card. `01`) |
| `reference` | `VARCHAR(50)` | NO | — | référence client (identifiant MCD partiel) |
| `libelle` | `VARCHAR(200)` | NO | — | |
| `poids` | `DECIMAL(10,3)` | YES | NULL | kg, 3 décimales (gramme) |
| `longueur` | `DECIMAL(8,2)` | YES | NULL | cm |
| `largeur` | `DECIMAL(8,2)` | YES | NULL | cm |
| `hauteur` | `DECIMAL(8,2)` | YES | NULL | cm |
| `created_at` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP` | |
| `updated_at` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | |

### 2.4 `sites`

| Colonne | Type SQL | Nullable | Défaut | Note |
|---|---|---|---|---|
| `id_site` | `INT UNSIGNED AUTO_INCREMENT` | NO | — | PK |
| `code_site` | `VARCHAR(20)` | NO | — | identifiant métier MCD |
| `nom` | `VARCHAR(100)` | NO | — | ex. WH1 Lens |
| `adresse` | `VARCHAR(255)` | NO | — | |
| `created_at` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP` | |
| `updated_at` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | |

### 2.5 `emplacements`

| Colonne | Type SQL | Nullable | Défaut | Note |
|---|---|---|---|---|
| `id_emplacement` | `INT UNSIGNED AUTO_INCREMENT` | NO | — | PK |
| `id_site` | `INT UNSIGNED` | NO | — | FK → `sites`, matérialise `contient` |
| `code` | `VARCHAR(30)` | NO | — | identifiant métier MCD, unique au sein du site |
| `zone` | `VARCHAR(20)` | YES | NULL | |
| `allee` | `VARCHAR(20)` | YES | NULL | |
| `etagere` | `VARCHAR(20)` | YES | NULL | |
| `niveau` | `VARCHAR(20)` | YES | NULL | |
| `type_emplacement` | `ENUM('rack','picking','masse','quai')` | NO | — | domaine §6 |
| `created_at` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP` | |
| `updated_at` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | |

### 2.6 `stocks`

| Colonne | Type SQL | Nullable | Défaut | Note |
|---|---|---|---|---|
| `id_stock` | `INT UNSIGNED AUTO_INCREMENT` | NO | — | PK surrogate |
| `id_article` | `INT UNSIGNED` | NO | — | matérialise `stock_de`, participe FK composite option D |
| `id_client` | `INT UNSIGNED` | NO | — | participe FK composite option D (cohérence article/client) |
| `id_emplacement` | `INT UNSIGNED` | NO | — | FK → `emplacements`, matérialise `localise_dans` |
| `quantite` | `INT` | NO | `0` | `CHECK >= 0` |
| `date_maj` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP` | dernière mise à jour métier |
| `created_at` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP` | |
| `updated_at` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | |

### 2.7 `mouvements`

| Colonne | Type SQL | Nullable | Défaut | Note |
|---|---|---|---|---|
| `id_mouvement` | `INT UNSIGNED AUTO_INCREMENT` | NO | — | PK surrogate |
| `numero_mvt` | `VARCHAR(30)` | NO | — | identifiant métier MCD (`NUMERO_MVT`), UNIQUE |
| `type_mouvement` | `ENUM('ENTREE','SORTIE','TRANSFERT','AJUSTEMENT')` | NO | — | domaine §6 |
| `id_article` | `INT UNSIGNED` | NO | — | matérialise `concerne`, participe FK composite option D |
| `id_client` | `INT UNSIGNED` | NO | — | matérialise `realise_pour` ET FK composite option D (même colonne) |
| `id_site` | `INT UNSIGNED` | NO | — | **dénormalisé** : FK → `sites`, sert de discriminant FK composite TRANSFERT intra-site |
| `id_depart` | `INT UNSIGNED` | YES | NULL | matérialise `depart` |
| `id_arrivee` | `INT UNSIGNED` | YES | NULL | matérialise `arrivee` |
| `id_utilisateur` | `INT UNSIGNED` | NO | — | FK → `utilisateurs`, matérialise `effectue` |
| `quantite` | `INT` | NO | — | `CHECK > 0` |
| `date_mouvement` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP` | horodatage métier |
| `created_at` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP` | |
| `updated_at` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | |

### 2.8 `utilisateurs`

| Colonne | Type SQL | Nullable | Défaut | Note |
|---|---|---|---|---|
| `id_utilisateur` | `INT UNSIGNED AUTO_INCREMENT` | NO | — | PK |
| `login` | `VARCHAR(50)` | NO | — | identifiant métier MCD (`LOGIN`), UNIQUE |
| `nom` | `VARCHAR(100)` | NO | — | |
| `prenom` | `VARCHAR(100)` | NO | — | |
| `role` | `ENUM('operateur','cariste','admin')` | NO | — | domaine §6 |
| `created_at` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP` | |
| `updated_at` | `TIMESTAMP` | NO | `CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | |

## 3. Clés primaires et alternatives (UNIQUE)

| Table | PK | UNIQUE additionnelles | Justification |
|---|---|---|---|
| `clients` | `id_client` | `code_client`, `siret` | code métier traçable + unicité légale SIRET |
| `fournisseurs` | `id_fournisseur` | `code_fournisseur` | code métier traçable |
| `articles` | `id_article` | `(id_client, reference)`, `(id_article, id_client)` | (a) PK composite MCD reconstituée ; (b) cible FK composite option D |
| `sites` | `id_site` | `code_site` | code métier traçable |
| `emplacements` | `id_emplacement` | `(id_site, code)`, `(id_emplacement, id_site)` | (a) unicité code emplacement intra-site ; (b) cible FK composite TRANSFERT intra-site |
| `stocks` | `id_stock` | `(id_article, id_emplacement)` | **unicité métier obligatoire** : une seule ligne de stock courant par couple article/emplacement |
| `mouvements` | `id_mouvement` | `numero_mvt` | code métier traçable |
| `utilisateurs` | `id_utilisateur` | `login` | code métier traçable |

## 4. Clés étrangères simples

| Table source | Colonne | Table cible | Colonne cible | ON DELETE | ON UPDATE | Association MCD |
|---|---|---|---|---|---|---|
| `articles` | `id_client` | `clients` | `id_client` | RESTRICT | CASCADE | `possede` |
| `articles` | `id_fournisseur` | `fournisseurs` | `id_fournisseur` | SET NULL | CASCADE | `fournit` (optionnel) |
| `emplacements` | `id_site` | `sites` | `id_site` | RESTRICT | CASCADE | `contient` |
| `stocks` | `id_emplacement` | `emplacements` | `id_emplacement` | RESTRICT | CASCADE | `localise_dans` |
| `mouvements` | `id_utilisateur` | `utilisateurs` | `id_utilisateur` | RESTRICT | CASCADE | `effectue` |
| `mouvements` | `id_site` | `sites` | `id_site` | RESTRICT | CASCADE | dénormalisation TRANSFERT |

Politique par défaut : `ON DELETE RESTRICT` (refus de suppression si dépendances) + `ON UPDATE CASCADE`. Une suppression de client/site/article passe par soft-delete applicatif (statut, archivage) — pas par cascade physique qui détruirait l'historique des mouvements.

Exception : `articles.id_fournisseur` en `ON DELETE SET NULL` (un fournisseur supprimé ne doit pas bloquer un article ; la nullabilité est déjà autorisée par la cardinalité `01`).

## 5. Clés étrangères composites (option D + dénormalisation id_site)

| Table source | Colonnes | Table cible | Colonnes cibles | ON DELETE | Justification |
|---|---|---|---|---|---|
| `stocks` | `(id_article, id_client)` | `articles` | `(id_article, id_client)` | RESTRICT | **Option D multi-tenant** : empêche déclarativement une ligne de stock d'associer un article avec un client autre que son propriétaire |
| `mouvements` | `(id_article, id_client)` | `articles` | `(id_article, id_client)` | RESTRICT | **Option D multi-tenant** : même garantie sur les mouvements. `id_client` matérialise aussi `realise_pour` (une seule colonne, pas de duplication) |
| `mouvements` | `(id_depart, id_site)` | `emplacements` | `(id_emplacement, id_site)` | RESTRICT | **TRANSFERT intra-site déclaratif** : l'emplacement de départ DOIT appartenir au site du mouvement |
| `mouvements` | `(id_arrivee, id_site)` | `emplacements` | `(id_emplacement, id_site)` | RESTRICT | **TRANSFERT intra-site déclaratif** : l'emplacement d'arrivée DOIT appartenir au site du mouvement |

Les deux dernières FK composites rendent **inutile tout trigger** : même un AJUSTEMENT ou une SORTIE qui ne renseigne qu'un des deux emplacements ne peut pas pointer vers un emplacement d'un autre site que celui du mouvement. La garantie est déclarative, vérifiée par le moteur InnoDB.

## 6. Contraintes CHECK

### 6.1 `ck_mvt_src_dst` (XOR conditionnel sur `mouvements`)

```sql
CHECK (
     (type_mouvement = 'ENTREE'
        AND id_depart IS NULL AND id_arrivee IS NOT NULL)
  OR (type_mouvement = 'SORTIE'
        AND id_depart IS NOT NULL AND id_arrivee IS NULL)
  OR (type_mouvement = 'TRANSFERT'
        AND id_depart IS NOT NULL AND id_arrivee IS NOT NULL
        AND id_depart <> id_arrivee)
  OR (type_mouvement = 'AJUSTEMENT'
        AND ((id_depart IS NOT NULL AND id_arrivee IS NULL)
          OR (id_depart IS NULL     AND id_arrivee IS NOT NULL)))
)
```

Couvre toutes les combinaisons valides du §4 du MCD :
- ENTREE → arrivée seule
- SORTIE → départ seul
- TRANSFERT → les deux, différents (intra-site garanti par FK composite §5)
- AJUSTEMENT → XOR (exactement un des deux)

### 6.2 Domaines de valeurs

Matérialisés via `ENUM` natif MariaDB sur les 4 colonnes (cf. §2). Équivalent fonctionnel à `CHECK IN (...)` : insertion d'une valeur hors liste rejetée par le moteur.

| Colonne | Type | Valeurs |
|---|---|---|
| `clients.status` | `ENUM` | `'actif'`, `'suspendu'`, `'resilie'` |
| `utilisateurs.role` | `ENUM` | `'operateur'`, `'cariste'`, `'admin'` |
| `emplacements.type_emplacement` | `ENUM` | `'rack'`, `'picking'`, `'masse'`, `'quai'` |
| `mouvements.type_mouvement` | `ENUM` | `'ENTREE'`, `'SORTIE'`, `'TRANSFERT'`, `'AJUSTEMENT'` |

### 6.3 CHECK quantités

```sql
ALTER TABLE stocks     ADD CHECK (quantite >= 0);
ALTER TABLE mouvements ADD CHECK (quantite >  0);
```

Justification métier : un stock courant peut être à zéro (article référencé sans inventaire) mais jamais négatif. Un mouvement de quantité nulle ou négative n'a pas de sens (un AJUSTEMENT à la baisse reste une quantité positive avec un type qui exprime le sens).

## 7. Index recommandés

InnoDB crée automatiquement un index sur chaque PK et sur chaque FK. Les index ci-dessous sont **additionnels**, justifiés par des patterns d'accès prévisibles (reporting, audit, recherche utilisateur).

| Table | Index | Type | Justification |
|---|---|---|---|
| `articles` | `(id_client, libelle)` | btree | recherche article par client (UI catalogue) |
| `stocks` | `(id_client, id_emplacement)` | btree | reporting stock par client et site (via jointure emplacement→site) |
| `mouvements` | `(id_client, date_mouvement DESC)` | btree | historique mouvements par client, tri chronologique inverse |
| `mouvements` | `(id_site, date_mouvement DESC)` | btree | reporting opérationnel par site |
| `mouvements` | `(type_mouvement, date_mouvement DESC)` | btree | audit par type d'opération |
| `mouvements` | `(id_article, date_mouvement DESC)` | btree | traçabilité article (entrée/sortie/transfert) |
| `mouvements` | `(id_utilisateur, date_mouvement DESC)` | btree | audit utilisateur (qui a fait quoi) |

Les UNIQUE listés au §3 servent aussi d'index couvrants pour les FK composites — pas besoin de les redéclarer.

## 8. Mapping MCD → MLD

Vérification que chaque association du §3 du MCD V4 trouve sa matérialisation au MLD :

| Association MCD | Cardinalité | Matérialisation MLD | Section |
|---|---|---|---|
| `possede` (CLIENT–ARTICLE) | (0,N)–(1,1) | `articles.id_client` FK NOT NULL | §4 |
| `fournit` (FOURNISSEUR–ARTICLE) | (0,N)–(0,1) | `articles.id_fournisseur` FK NULL | §4 |
| `contient` (SITE–EMPLACEMENT) | (1,N)–(1,1) | `emplacements.id_site` FK NOT NULL | §4 |
| `stock_de` (ARTICLE–STOCK) | (0,N)–(1,1) | `stocks.id_article` + FK composite `(id_article, id_client)` | §4 + §5 |
| `localise_dans` (EMPLACEMENT–STOCK) | (0,N)–(1,1) | `stocks.id_emplacement` FK NOT NULL + `UNIQUE(id_article, id_emplacement)` | §4 + §3 |
| `concerne` (ARTICLE–MOUVEMENT) | (0,N)–(1,1) | `mouvements.id_article` + FK composite `(id_article, id_client)` | §4 + §5 |
| `realise_pour` (CLIENT–MOUVEMENT) | (0,N)–(1,1) | `mouvements.id_client` (même colonne que la FK composite, pas de duplication) | §5 |
| `effectue` (UTILISATEUR–MOUVEMENT) | (0,N)–(1,1) | `mouvements.id_utilisateur` FK NOT NULL | §4 |
| `depart` (EMPLACEMENT–MOUVEMENT) | (0,N)–(0,1) | `mouvements.id_depart` NULL + FK composite `(id_depart, id_site)` | §5 |
| `arrivee` (EMPLACEMENT–MOUVEMENT) | (0,N)–(0,1) | `mouvements.id_arrivee` NULL + FK composite `(id_arrivee, id_site)` | §5 |

Règles complémentaires du §4 MCD :
- `articles.UNIQUE(id_client, reference)` → §3 ✓
- `articles.UNIQUE(id_article, id_client)` → §3 ✓ (cible option D)
- `emplacements.UNIQUE(id_emplacement, id_site)` → §3 ✓ (cible FK composite TRANSFERT)
- `stocks.UNIQUE(id_article, id_emplacement)` → §3 ✓
- `mouvements.id_site` dénormalisé → §2.7 ✓
- `ck_mvt_src_dst` (XOR conditionnel) → §6.1 ✓
- Domaines de valeurs → §6.2 ✓
- Timestamps techniques → convention §1 + §2 ✓

**Couverture : 10/10 associations + 8/8 règles MLD reportées.**

## 9. Limites assumées et évolutions V2

| Limite V1 | Impact | Évolution V2 |
|---|---|---|
| Pas de versioning historique (prix, dimensions article) | une modification d'attribut écrase l'ancienne valeur | table `articles_history` avec `valid_from` / `valid_to` (SCD2) |
| Pas de soft-delete (`deleted_at`) | suppression = `DELETE` physique ou statut applicatif | colonne `deleted_at TIMESTAMP NULL` sur tables référentielles + vues filtrées |
| `fournisseurs` mono-attribut métier | impossible de stocker contact, téléphone, contrat | enrichissement attributs + association avec contrats fournisseur |
| Pas de partitioning sur `mouvements` | croissance linéaire, ralentissement requêtes historiques au-delà de ~10M lignes | partitioning par RANGE sur `date_mouvement` (mensuel ou annuel) |
| `ENUM` rigide | toute nouvelle valeur de statut/rôle/type requiert `ALTER TABLE` (verrou) | bascule vers tables de référence (`ref_status`, `ref_role`) si volatilité prouvée |
| Multi-tenant **logique** (FK composite) | isolation au niveau requête, pas au niveau schéma | schéma par client (multi-tenant physique) si exigence sécurité accrue — coût opérationnel x N clients |
| Pas de réservation de stock | la quantité affichée = quantité réelle, pas de notion de "réservé pour commande X" | colonne `quantite_reservee` + table `reservations` |
| `mouvements.id_site` dénormalisé | risque d'incohérence si update manuel sans passer par l'application | trigger BEFORE INSERT/UPDATE pour synchroniser depuis `id_depart` / `id_arrivee` (V2 si trigger autorisé) |
| Hors périmètre MCD (cf. §7 MCD) | pas de lots/DLC/FEFO, commandes, expéditions, transporteurs | refonte fonctionnelle V2 vers modèle 14 entités |
