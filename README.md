# MSPR3 — NTL WMS-DB

MSPR3 EPSI Nantes BAC+3 ASRBD 2025-2026 — **Conception, exploitation et protection d'une base de données via un SGBD relationnel**.

Client fictif : **NordTransit Logistics (NTL)**, PME logistique Hauts-de-France (siège Lille + WH1 Lens, WH2 Valenciennes, WH3 Arras + cross-dock saisonnier).

## Mission

Concevoir et industrialiser la base WMS qui pilote l'application de gestion d'entrepôt. Périmètre : modèle de données, HA/PRA, sécurité accès, supervision, exploitation, logs, pilotage projet.

Contraintes clés : **RTO 1h, RPO 15 min** · fenêtre de maintenance nocturne uniquement (5h30 → 18h30 ouvré) · équipe IT NTL réduite.

## Équipe

- Ianis Puichaud — lead, architecture, MCD/MLD/DDL
- Blaise Carel
- Zaid Abouyaala
- _tequilla77_

19 h × 4 personnes.

## État

| Livrable | Statut |
|---|---|
| **Livrable 1** — Architecture technique ([`01-architecture-technique/`](01-architecture-technique/)) | 🟡 en cours (MCD ✅, MLD ✅ draft, DDL ✅ testé, reste justif SGBD + politiques) |
| **Livrable 2** — Plan de Reprise d'Activité ([`02-pra/`](02-pra/)) | ⏳ |
| **Livrable 3** — Guide de supervision ([`03-supervision/`](03-supervision/)) | ⏳ |
| **Livrable 4** — Démarche d'optimisation BDD ([`04-optimisation/`](04-optimisation/)) | ⏳ |
| **Livrable 5** — RunBook d'exploitation ([`05-runbook/`](05-runbook/)) | ⏳ |
| **Livrable 6** — Analyse de logs ([`06-analyse-logs/`](06-analyse-logs/)) | ⏳ |
| **Livrable 7** — Gestion de projet ([`07-gestion-projet/`](07-gestion-projet/)) | 🟡 journal décisions + registre risques amorcés |
| **Livrable 8** — Note Comité de direction ([`08-note-direction/`](08-note-direction/)) | ⏳ |
| **Livrable 9** — Soutenance ([`09-soutenance/`](09-soutenance/)) | ⏳ |

Détail par livrable dans le `README.md` de chaque dossier. Vue d'ensemble équipe : [`EQUIPE.md`](EQUIPE.md). FAQ soutenance : [`FAQ.md`](FAQ.md). Historique changements : [`CHANGELOG.md`](CHANGELOG.md). Décisions structurantes : [`07-gestion-projet/journal-decisions.md`](07-gestion-projet/journal-decisions.md) + détail dans [`decisions/`](decisions/).

## Décisions de cadrage

- **SGBD** : MariaDB 11.4 LTS — justification actée le 2026-05-22 ([`decisions/0002-sgbd-mariadb.md`](decisions/0002-sgbd-mariadb.md)).
- **MCD V4 officielle à 8 entités** : SITE, EMPLACEMENT, ARTICLE, FOURNISSEUR, STOCK, UTILISATEUR, MOUVEMENT, CLIENT. Modèle 14 entités (lots/FEFO, commandes, expéditions, transporteurs) repoussé en évolution fonctionnelle.
- **Multi-tenant double verrou** : (a) association `realise_pour CLIENT-MOUVEMENT` au MCD pour visibilité ; (b) FK composite `(id_article, id_client)` depuis `STOCK` et `MOUVEMENT` vers `articles(id_article, id_client)` (option D) au MLD/DDL.
- **Rattachement site** : `STOCK` hérite du site via `EMPLACEMENT` ; `MOUVEMENT` porte un `id_site` dénormalisé garantissant TRANSFERT intra-site par FK composite déclarative `(id_depart, id_site) → emplacements(id_emplacement, id_site)`.
- **Fournisseur** : référentiel mutualisé NTL (entité `FOURNISSEUR`), association `fournit` optionnelle (`01 ARTICLE`).

## Ressources

- [`ressources/sujet-mspr3.pdf`](ressources/sujet-mspr3.pdf) — cahier des charges EPSI
- [`ressources/grille-evaluation.pdf`](ressources/grille-evaluation.pdf) — grille d'évaluation jury
