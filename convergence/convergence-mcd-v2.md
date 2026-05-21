---
livrable: "01 — Architecture technique"
scope: "01-architecture"
section: "Convergence MCD V2 — synthèse"
version: "1.5-final"
status: "10/10 convergés — V3 matérialisée dans wms-mcd.md"
owner: "Ianis"
participants: ["Claude Code", "GPT-5 Codex"]
arbitre: "Ianis"
related:
  - "./convergence-mcd-v2-history.md"
  - "./review-v2-par-gpt.md"
  - "../propositions/wms-mcd-v2-claude.md"
  - "../propositions/wms-mcd-v2-gpt.md"
  - "../propositions/wms-mcd-v3-gpt.md"
  - "../wms-mcd.md"
created: "2026-05-21"
updated: "2026-05-21"
---

# Convergence MCD V2 — synthèse

> **But** : version épurée du débat Claude × GPT. Pour l'historique complet des 4 rounds (1.0 → 1.3) et les arguments détaillés, voir [`convergence-mcd-v2-history.md`](convergence-mcd-v2-history.md).

## Statut

**10/10 convergés.** Arbitrages Ianis tranchés le 2026-05-21 (points 9 et 10).

La proposition V3-GPT ([`../propositions/wms-mcd-v3-gpt.md`](../propositions/wms-mcd-v3-gpt.md)) a été promue dans le MCD officiel racine : [`../wms-mcd.md`](../wms-mcd.md).

## Décisions consensuelles (8)

| # | Sujet | Résolution finale | À appliquer en V3 |
|---|-------|-------------------|-------------------|
| 1 | Identifiant ARTICLE composite | Mocodo `ARTICLE: CODE_CLIENT, _REFERENCE` + note « forme entité faible `_11` écartée pour lisibilité » | Source `.mcd` |
| 4 | Identifiant STOCK | `ID_STOCK` surrogate + `UNIQUE (id_article, id_emplacement)` explicite au MCD | Tableau entités + note |
| 5 | Stock ↔ Article + Emplacement | Ternaire `stockage(ARTICLE, EMPLACEMENT, STOCK)` + paragraphe « STOCK = entité associative renforcée » | Source `.mcd` + §3.4 |
| 6 | Renommage `deplace_par` | → `concerne` (lecture active) | Source `.mcd` + tableau |
| 7 | TRANSFERT inter-site | Intra-site uniquement. Inter-site = 2 mouvements distincts | CHECK DDL `depart.site = arrivee.site` |
| 8 | Autonomie doc V3 | Recopier le tableau des 7 entités, pas de renvoi à wms-mcd.md | Tableau §3.1 complet |
| 2 | Rattachement MOUVEMENT-SITE | Pas d'association directe `rattache` par défaut. Site dérivé via `depart` ou `arrivee` | Règle documentée §3.4 |
| 9-bis | Liens cassés | Références absentes retirées du MCD officiel ; MLD/DDL restent listés comme livrables à reprendre | `wms-mcd.md` + README |

## Arbitrages Ianis (tranchés 2026-05-21)

### Point 9 — AJUSTEMENT global de site sans emplacement

**Décision** : **Non** — cas métier inexistant chez NTL. Tout AJUSTEMENT cible un emplacement précis.

**Conséquence modèle** : pas d'association directe `MOUVEMENT — SITE`. Règle métier appliquée : « AJUSTEMENT a exactement un emplacement non NULL (depart XOR arrivee selon le signe) ». Site dérivé via cet emplacement. *(Aligné avec reco Claude + GPT 1.3.)*

### Point 10 — Garantie séparation client au MLD/DDL

**Décision** : **Option D** — FK composite déclarative.

**Mécanisme** :
- Sur `articles` : `PRIMARY KEY (id_article)` + `UNIQUE (id_article, id_client)`
- Sur tables enfants (`mouvements`, etc.) : `FOREIGN KEY (id_article, id_client) REFERENCES articles(id_article, id_client)`
- → La BDD refuse physiquement `mouvement(id_client=A, id_article ∈ B)`. Garantie multi-tenant maximale, sans trigger applicatif.

Recos écartées : A (faible), B (triggers à maintenir), C (JOIN systématique pénalisant le reporting).

## Spec V3 finale matérialisée dans `wms-mcd.md`

### Entités (7)

| # | Entité | Identifiant | Attributs |
|---|--------|-------------|-----------|
| 1 | `CLIENT` | `CODE_CLIENT` | raison_sociale, siret, contact_nom, contact_email, adresse, status |
| 2 | `ARTICLE` | `(CODE_CLIENT, REFERENCE)` composite | libelle, poids, longueur, largeur, hauteur, fournisseur |
| 3 | `SITE` | `CODE_SITE` | nom, adresse |
| 4 | `EMPLACEMENT` | `CODE` | zone, allee, etagere, niveau, type_emplacement |
| 5 | `STOCK` | `ID_STOCK` (surrogate) | quantite, date_maj. **UNIQUE métier obligatoire : `(id_article, id_emplacement)`** |
| 6 | `MOUVEMENT` | `NUMERO_MVT` | type_mouvement, quantite, date_mouvement |
| 7 | `UTILISATEUR` | `LOGIN` | nom, prenom, role |

### Associations (7)

| Association | Type | Entités | Cardinalités |
|-------------|------|---------|--------------|
| `contient` | binaire | SITE — EMPLACEMENT | (1,N) — (1,1) |
| `possede` | binaire | CLIENT — ARTICLE | (0,N) — (1,1) |
| `stockage` | **ternaire** | ARTICLE — STOCK — EMPLACEMENT | (0,N) — (1,1) — (0,N) |
| `concerne` | binaire | ARTICLE — MOUVEMENT | (0,N) — (1,1) |
| `effectue` | binaire | UTILISATEUR — MOUVEMENT | (0,N) — (1,1) |
| `depart` | binaire | EMPLACEMENT — MOUVEMENT | (0,N) — (0,1) |
| `arrivee` | binaire | EMPLACEMENT — MOUVEMENT | (0,N) — (0,1) |

### Contraintes MLD/DDL clés

- `ARTICLE` : `UNIQUE(id_client, reference)` (multi-tenant article)
- `STOCK` : `UNIQUE(id_article, id_emplacement)` (1 ligne par couple)
- `MOUVEMENT` : `CHECK ck_mvt_src_dst` selon `type_mouvement` (ENTREE/SORTIE/TRANSFERT/AJUSTEMENT)
- `MOUVEMENT` : `CHECK ck_transfert_intra_site` pour TRANSFERT → `depart.site = arrivee.site`
- **Séparation client** : option D, FK composite `(id_article, id_client) REFERENCES articles(id_article, id_client)`

## Suites

1. Reprendre le MLD à partir de [`../wms-mcd.md`](../wms-mcd.md).
2. Reprendre le DDL MariaDB 11.4 LTS avec les contraintes option D.
3. Archiver les propositions V2 si l'équipe veut alléger le dossier de rendu.

## Historique complet

Voir [`convergence-mcd-v2-history.md`](convergence-mcd-v2-history.md) — débat round par round (1.0 → 1.3), arguments détaillés, citations sujet.
