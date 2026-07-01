# MSPR3 — NTL WMS-DB

MSPR3 EPSI Nantes BAC+3 ASRBD 2025-2026 — **Conception, exploitation et protection d'une base de données via un SGBD relationnel**.

Client fictif : **NordTransit Logistics (NTL)**, PME logistique Hauts-de-France (siège Lille + WH1 Lens, WH2 Valenciennes, WH3 Arras + cross-dock saisonnier).

## Mission

Concevoir et industrialiser la base WMS qui pilote l'application de gestion d'entrepôt. Périmètre : modèle de données, HA/PRA, sécurité accès, supervision, exploitation, logs, pilotage projet.

Contraintes clés : **RTO 1h, RPO 15 min** · fenêtre de maintenance nocturne uniquement (5h30 → 18h30 ouvré) · équipe IT NTL réduite.

## Équipe

- Ianis Puichaud — lead, modèle de données (MCD/MLD/DDL), décisions
- Blaise Carel — modèle de données (MCD/MLD/DDL)
- Ojvind (_tequilla77_) — infrastructure / exploitation (PRA, supervision, runbook, optim, logs)
- Zaid Abouyaala — infrastructure / exploitation

19 h × 4 personnes.

## État

| Livrable | Statut |
|---|---|
| **Livrable 1** — Architecture technique ([`01-architecture-technique/`](01-architecture-technique/)) | 🟢 MCD/MLD/DDL V2 grossiste ✅ — DDL ⚠️ **pas encore exécuté** sur MariaDB (cf. `ddl/wms-ddl.md` §8) |
| **Livrable 2** — Plan de Reprise d'Activité ([`02-pra/`](02-pra/)) | 🟢 rédigé |
| **Livrable 3** — Guide de supervision ([`03-supervision/`](03-supervision/)) | 🟢 rédigé (5 indicateurs + seuils + procédures) |
| **Livrable 4** — Démarche d'optimisation BDD ([`04-optimisation/`](04-optimisation/)) | 🟢 rédigé |
| **Livrable 5** — RunBook d'exploitation ([`05-runbook/`](05-runbook/)) | 🟢 rédigé |
| **Livrable 6** — Analyse de logs ([`06-analyse-logs/`](06-analyse-logs/)) | 🟢 rédigé |
| **Livrable 7** — Gestion de projet ([`07-gestion-projet/`](07-gestion-projet/)) | 🟡 journal décisions (6) + registre risques (9) — reste planning/jalons + suivi tâches |
| **Livrable 8** — Note Comité de direction ([`08-note-direction/`](08-note-direction/)) | 🟢 rédigée |
| **Livrable 9** — Soutenance ([`09-soutenance/`](09-soutenance/)) | 🟡 plan défini, support à produire |

Détail par livrable dans le `README.md` de chaque dossier. Vue d'ensemble équipe : [`EQUIPE.md`](EQUIPE.md). FAQ soutenance : [`FAQ.md`](FAQ.md). Historique changements : [`CHANGELOG.md`](CHANGELOG.md). Décisions structurantes : [`07-gestion-projet/journal-decisions.md`](07-gestion-projet/journal-decisions.md) + détail dans [`decisions/`](decisions/).

## Décisions de cadrage

- **SGBD** : MariaDB 11.4 LTS — justification actée le 2026-05-22 ([`decisions/0002-sgbd-mariadb.md`](decisions/0002-sgbd-mariadb.md)).
- **Postulat métier : NTL = grossiste** (stock propre, pas 3PL) — pivot acté le 2026-05-22 ([`decisions/0003-postulats-cadrage-ntl.md`](decisions/0003-postulats-cadrage-ntl.md)). Le sujet étant ambigu (grossiste vs 3PL), on tranche par un postulat explicite.
- **MCD V2 grossiste à 7 entités** : SITE, LOCALISATION, ARTICLE, CLIENT, STOCK, MOUVEMENT, UTILISATEUR + 1 table associative `commande`. **8 tables** au total. Lots/FEFO, expéditions, transporteurs reportés V2.
- **Séparation par client = attribution** (pas isolation) : `mouvement.id_client` (nullable) + table `commande`. L'**isolation multi-tenant** (FK composite) est une évolution V2 conditionnée à une bascule 3PL.
- **Fournisseur** : attribut texte `article.fournisseur`. Gestion achats portée par l'ERP commercial NTL (hors périmètre V1).
- **Modèle sans triggers ni FK composites** : intégrité par FK simples + CHECK + UNIQUE. Cf. [`decisions/0001-bug-mariadb-check.md`](decisions/0001-bug-mariadb-check.md) (superseded — le bug ne s'applique plus).

## Ressources

- [`ressources/sujet-mspr3.pdf`](ressources/sujet-mspr3.pdf) — cahier des charges EPSI
- [`ressources/grille-evaluation.pdf`](ressources/grille-evaluation.pdf) — grille d'évaluation jury
