---
livrable: "01 — Architecture technique"
scope: "01-architecture"
section: "Arbitrages V4 Ianis — réponse aux 5 attaques soutenance"
version: "1.0-final"
status: "validé GPT + matérialisé V4"
owner: "Ianis"
arbitre: "Ianis"
created: "2026-05-21"
updated: "2026-05-21"
related:
  - "./convergence-mcd-v2.md"
  - "../wms-mcd.md"
  - "../propositions/wms-mcd-v3-gpt.md"
---

# Arbitrages V4 — réponse aux 5 attaques soutenance

> Round d'arbitrages après revue critique du MCD V3 officiel par Claude le 2026-05-21. 5 points d'attaque potentiels identifiés en soutenance + détails mineurs. Tranchés par Ianis pour produire une V4 « inattaquable » sur les points majeurs.

## Contexte

Le MCD V3 (matérialisé à la racine après convergence Claude × GPT) a été soumis à une revue critique « point de vue correcteur soutenance ». 5 attaques majeures identifiées + 3 détails mineurs. Ianis a tranché chaque point en privilégiant la défendabilité visuelle au MCD plutôt que la défense argumentée a posteriori.

## Décisions

### Point 1 — `stockage` ternaire → 2 binaires STOCK

**Décision** : remplacer l'association ternaire `stockage(ARTICLE, STOCK, EMPLACEMENT)` par STOCK en tant qu'**entité standalone** avec 2 associations binaires.

**Avant (V3)**
```
stockage, 0N ARTICLE, 11 STOCK, 0N EMPLACEMENT
```

**Après (V4)**
```
a_pour_stock,  0N ARTICLE, 11 STOCK
localise_dans, 0N EMPLACEMENT, 11 STOCK
STOCK: ID_STOCK, quantite, date_maj
```

**Justification** : la patte STOCK en `(1,1)` dans la ternaire rendait STOCK techniquement décomposable en binaires (règle Merise). La nouvelle modélisation traite STOCK comme **une chose qui existe** (entité reifiée) plutôt qu'une association renforcée. Lecture diagramme plus naturelle, MLD/DDL strictement identiques, élimine l'attaque « ternaire avec (1,1) ».

**Coût MLD/DDL** : zéro. Même table `stocks(id_stock, id_article, id_emplacement, quantite, date_maj)` avec `UNIQUE(id_article, id_emplacement)`.

---

### Point 2 — Syntaxe `_REFERENCE` Mocodo

**Décision** : retirer l'underscore. ARTICLE devient un identifiant composite classique sans notation entité faible.

**Avant (V3)**
```
ARTICLE: CODE_CLIENT, _REFERENCE, libelle, ...
```

**Après (V4)**
```
ARTICLE: CODE_CLIENT, REFERENCE, libelle, ...
```

**Justification** : `_attr` en Mocodo signale un identifiant relatif d'entité faible. La V3 utilisait cette syntaxe sans avoir d'association `_11` correspondante, créant une incohérence avec la description « identifiant composite classique » du §2. La V4 assume la PK composite simple. Défense soutenance : « MVP V1, PK composite classique ».

**Solution écartée** : déclarer ARTICLE comme vraie entité faible (`possede, _11 ARTICLE, 0N CLIENT`). Plus rigoureuse Merise mais plus complexe à expliquer. Choix « simplicité > orthodoxie ».

---

### Point 3 — Réintroduction `tracable_pour CLIENT-MOUVEMENT`

**Décision** : ajouter une association directe `CLIENT — MOUVEMENT` pour rendre la séparation multi-tenant **visible au MCD**, pas seulement dérivée via ARTICLE.

**Ajout V4**
```
tracable_pour, 0N CLIENT, 11 MOUVEMENT
```

**Justification** : la séparation client est l'exigence centrale du sujet NTL (PME logistique multi-clients). Sans cette association, la garantie multi-tenant n'est visible qu'au MLD via FK composite option D. Un correcteur lisant le MCD seul ne comprend pas la règle. Le cycle apparent CLIENT-ARTICLE-MOUVEMENT-CLIENT n'est pas une redondance fautive : c'est une **contrainte d'intégrité explicite** que la FK composite (option D) verrouille au DDL.

**Note** : ce lien existait en V0.7 et avait été retiré par la V3-GPT au motif de redondance Merise. La V4 le restaure en assumant le cycle comme volontaire.

---

### Point 4 — Création entité FOURNISSEUR

**Décision** : extraire `fournisseur` du tableau d'attributs d'ARTICLE et créer une entité FOURNISSEUR dédiée.

**Avant (V3)**
```
ARTICLE: ..., fournisseur
```

**Après (V4)**
```
ARTICLE: CODE_CLIENT, REFERENCE, libelle, poids, longueur, largeur, hauteur
FOURNISSEUR: CODE_FOURNISSEUR, raison_sociale
fournit, 0N FOURNISSEUR, 11 ARTICLE
```

**Justification** : `fournisseur` attribut texte violait la 3NF (redondance, risque de typos, impossible de tracker des infos fournisseur additionnelles). L'extraction en entité dédiée :
- élimine la redondance
- garantit la cohérence référentielle via FK
- permet d'enrichir l'entité en V2 (téléphone, email, contrat) sans refonte
- coût minimal : 1 entité + 1 association

**Conséquence périmètre** : on passe de 7 à 8 entités. Le « cœur compact » reste défendable (8 = toujours sous le seuil 14 entités du modèle V0 complet).

---

### Point 5 — XOR AJUSTEMENT non Merisable

**Décision** : garder MOUVEMENT comme entité unique avec cardinalités `(0,1) + (0,1)` sur depart/arrivee. Pas de spécialisation en sous-types.

**Pas de modif MCD V4.**

**Justification** : la contrainte conditionnelle par valeur de `type_mouvement` n'est pas exprimable en Merise classique. La spécialisation MOUVEMENT en sous-types ENTREE/SORTIE/TRANSFERT/AJUSTEMENT serait formellement plus propre mais :
- multiplie les entités (4 sous-types + 1 abstrait) pour zéro gain métier en V1
- au MLD, retombe sur STI (table unique avec discriminant) ou multiplication de tables avec FK polymorphes
- formalisme avancé pas attendu au niveau MSPR3

**Défense soutenance** : « limitation reconnue du formalisme Merise, contrainte reportée au DDL via `CHECK ck_mvt_src_dst` ».

---

### Détails mineurs

**6a. Timestamps `created_at` / `updated_at`** — Décision **A** : convention DDL universelle, hors MCD. Défense : « ajouté par convention au DDL via `created_at TIMESTAMP DEFAULT NOW()` sur toutes les tables, sans pollution conceptuelle ».

**6b. Domaines de valeurs** — Décision **B** : ajouter section dédiée dans `wms-mcd.md` listant les valeurs autorisées pour `CLIENT.status`, `UTILISATEUR.role`, `EMPLACEMENT.type_emplacement`, `MOUVEMENT.type_mouvement`. Sera matérialisé au DDL via `CHECK IN (...)`.

**6c. Frontmatter `related:`** — Décision **A** : garder la référence vers `propositions/wms-mcd-v3-gpt.md` à titre historique (traçabilité convergence Claude × GPT).

---

## Spec V4 finale

### 8 entités

| # | Entité | Identifiant | Attributs |
|---|---|---|---|
| 1 | `CLIENT` | `CODE_CLIENT` | raison_sociale, siret, contact_nom, contact_email, adresse, status |
| 2 | `ARTICLE` | `(CODE_CLIENT, REFERENCE)` | libelle, poids, longueur, largeur, hauteur |
| 3 | `FOURNISSEUR` | `CODE_FOURNISSEUR` | raison_sociale |
| 4 | `SITE` | `CODE_SITE` | nom, adresse |
| 5 | `EMPLACEMENT` | `CODE` | zone, allee, etagere, niveau, type_emplacement |
| 6 | `STOCK` | `ID_STOCK` (surrogate) | quantite, date_maj |
| 7 | `MOUVEMENT` | `NUMERO_MVT` | type_mouvement, quantite, date_mouvement |
| 8 | `UTILISATEUR` | `LOGIN` | nom, prenom, role |

### 10 associations

| Association | Type | Entités | Cardinalités |
|---|---|---|---|
| `possede` | binaire | CLIENT — ARTICLE | (0,N) — (1,1) |
| `fournit` | binaire | FOURNISSEUR — ARTICLE | (0,N) — (0,1) |
| `contient` | binaire | SITE — EMPLACEMENT | (1,N) — (1,1) |
| `stock_de` | binaire | ARTICLE — STOCK | (0,N) — (1,1) |
| `localise_dans` | binaire | EMPLACEMENT — STOCK | (0,N) — (1,1) |
| `concerne` | binaire | ARTICLE — MOUVEMENT | (0,N) — (1,1) |
| `realise_pour` | binaire | CLIENT — MOUVEMENT | (0,N) — (1,1) |
| `effectue` | binaire | UTILISATEUR — MOUVEMENT | (0,N) — (1,1) |
| `depart` | binaire | EMPLACEMENT — MOUVEMENT | (0,N) — (0,1) |
| `arrivee` | binaire | EMPLACEMENT — MOUVEMENT | (0,N) — (0,1) |

### Domaines de valeurs (nouveau §6 dans wms-mcd.md)

| Attribut | Valeurs autorisées |
|---|---|
| `CLIENT.status` | `actif`, `suspendu`, `resilie` |
| `UTILISATEUR.role` | `operateur`, `cariste`, `admin` |
| `EMPLACEMENT.type_emplacement` | `rack`, `picking`, `masse`, `quai` |
| `MOUVEMENT.type_mouvement` | `ENTREE`, `SORTIE`, `TRANSFERT`, `AJUSTEMENT` |

### Règles MLD/DDL inchangées + ajouts

- `articles` : `PRIMARY KEY (id_article)` + `UNIQUE (id_client, reference)` + `UNIQUE (id_article, id_client)` (option D)
- `stocks` : `UNIQUE (id_article, id_emplacement)`
- `stocks` et `mouvements` : FK composite `(id_article, id_client) REFERENCES articles(id_article, id_client)` (option D)
- `mouvements.type_mouvement` : `CHECK ck_mvt_src_dst` selon le type
- `mouvements` TRANSFERT : `CHECK ck_transfert_intra_site` (depart.site = arrivee.site)
- **Nouveau** `articles.id_fournisseur` : FK simple vers `fournisseurs(id_fournisseur)`
- **Nouveau** `mouvements.id_client` : FK composite déjà couvre la traçabilité (l'association `tracable_pour` se matérialise par la même colonne `id_client` que celle utilisée par la FK composite vers `articles`)

---

## Source Mocodo V4 finale

Layout final validé sans chevauchement (`--detect_overlaps`) après revue GPT. Voir [`../wms-mcd.mcd`](../wms-mcd.mcd) pour la source canonique. Les nommages finaux (`stock_de`, `realise_pour`, cardinalité `01` sur `fournit`) ont été appliqués après les arbitrages détaillés en section *Statut*.

> Note : les sections « Décisions » ci-dessus reflètent l'état du draft avant revue GPT (avec `a_pour_stock`, `tracable_pour`, cardinalité `11` sur `fournit`, wording « entité standalone »). Le tableau « Spec V4 finale » et la source [`../wms-mcd.mcd`](../wms-mcd.mcd) reflètent l'état final post-revue.

---

## Statut

- **Validé** : Ianis (2026-05-21)
- **Revue GPT-5 Codex** (2026-05-21) : V3 V4 validée avec 4 ajustements appliqués :
  - Wording STOCK : « entité standalone » → **« entité réifiée dépendante du couple (ARTICLE, EMPLACEMENT) »**
  - Renommage `tracable_pour` → **`realise_pour`** (arbitrage Ianis sur les 3 propositions GPT)
  - Renommage `a_pour_stock` → **`stock_de`**
  - Cardinalité `fournit` : **`01 ARTICLE`** (optionnel, article créable sans fournisseur connu)
  - FOURNISSEUR : **référentiel global NTL** assumé (pas scoped client en V1)
  - TRANSFERT intra-site : **dénormalisation `id_site` sur `mouvements`** (FK composite déclarative, pas trigger)
  - Layout Mocodo : adopté la version GPT (sans chevauchement `--detect_overlaps`)
- **Matérialisé** : commit V4 dans [`../wms-mcd.md`](../wms-mcd.md), [`../wms-mcd.mcd`](../wms-mcd.mcd), [`../mcd-operationnel.md`](../mcd-operationnel.md), [`../README.md`](../README.md). PNG/SVG/_geo.json régénérés depuis source V4.
