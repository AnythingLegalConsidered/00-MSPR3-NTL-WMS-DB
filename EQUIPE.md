# Onboarding équipe — MSPR3 NTL WMS-DB

> Lecture rapide pour comprendre où on en est et où trouver quoi. Pour les questions de soutenance → [`FAQ.md`](FAQ.md).

## Le projet en 5 lignes

Concevoir la base de données du WMS (Warehouse Management System) de **NordTransit Logistics**, PME logistique fictive Hauts-de-France. Cible **MariaDB 11.4 LTS**. Périmètre : modèle de données + HA/PRA + sécurité + supervision + exploitation. Contraintes critiques : **RTO 1h, RPO 15 min**, équipe 4 × 19h.

## Qui fait quoi

| Membre | Rôle | Livrables principaux |
|---|---|---|
| Ianis | Lead, modèle de données | MCD, MLD, DDL, décisions, coordination |
| Blaise | Modèle de données | MCD, MLD, DDL |
| Ojvind (_tequilla77_) | Infrastructure / exploitation | PRA, supervision, runbook, optim, logs, migration |
| Zaid | Infrastructure / exploitation | PRA, supervision, runbook, optim, logs |

## Décisions verrouillées (ne pas rouvrir)

Ces décisions sont **tranchées**. Si tu penses qu'une est fausse, ouvre la discussion avant de modifier quoi que ce soit.

- **SGBD** : MariaDB 11.4 LTS
- **Postulat métier : NTL = grossiste** (stock propre, pas 3PL) — [`decisions/0003-postulats-cadrage-ntl.md`](decisions/0003-postulats-cadrage-ntl.md). Sujet ambigu → postulat explicite.
- **MCD V2 grossiste, 8 tables** : SITE, LOCALISATION, ARTICLE, CLIENT, STOCK, MOUVEMENT, UTILISATEUR + table associative `commande`. Lots/FEFO, expéditions, transporteurs reportés V2.
- **Séparation par client = attribution** : `mouvement.id_client` (nullable) + `commande`. **Pas** de multi-tenant (isolation) en V1 — évolution V2 si bascule 3PL.
- **Fournisseur** = attribut texte `article.fournisseur` (pas d'entité). Achats hors périmètre V1.
- **Surrogate keys** `id_*` partout au MLD, code métier conservé en `UNIQUE`.
- **Aucun trigger, aucune FK composite** : intégrité par FK simples + CHECK + UNIQUE. (L'ancien contournement par triggers d'un bug MariaDB ne s'applique plus depuis le pivot grossiste — [`decisions/0001-bug-mariadb-check.md`](decisions/0001-bug-mariadb-check.md) superseded.)

Détail et justifications → [`FAQ.md`](FAQ.md).

## Où trouver quoi

| Tu cherches… | Va dans |
|---|---|
| Le modèle conceptuel officiel | [`01-architecture-technique/mcd/wms-mcd.md`](01-architecture-technique/mcd/wms-mcd.md) |
| Le diagramme MCD visuel | [`01-architecture-technique/mcd/wms-mcd.png`](01-architecture-technique/mcd/wms-mcd.png) |
| Le modèle logique (tables, FK, contraintes) | [`01-architecture-technique/mld/wms-mld.md`](01-architecture-technique/mld/wms-mld.md) |
| Le DDL exécutable + sa doc | [`01-architecture-technique/ddl/`](01-architecture-technique/ddl/) |
| Le pourquoi d'une décision (synthèse) | [`07-gestion-projet/journal-decisions.md`](07-gestion-projet/journal-decisions.md) |
| Les ADR détaillés (problème, options, arbitrage) | [`decisions/`](decisions/) |
| Les risques projet | [`07-gestion-projet/registre-risques.md`](07-gestion-projet/registre-risques.md) |
| L'historique des changements | [`CHANGELOG.md`](CHANGELOG.md) |
| Les attaques jury anticipées + réponses | [`FAQ.md`](FAQ.md) |
| Interroger une IA sur le projet | [`brief-ia/`](brief-ia/) |
| Le sujet EPSI | [`ressources/sujet-mspr3.pdf`](ressources/sujet-mspr3.pdf) |
| La grille d'évaluation jury | [`ressources/grille-evaluation.pdf`](ressources/grille-evaluation.pdf) |
| L'état d'un livrable | `README.md` du dossier `0N-…/` correspondant |

## Livrables restants

Voir le `README.md` de chaque dossier `0N-…/` pour : statut détaillé, contenu attendu, point d'entrée pour démarrer, contraintes à respecter. Synthèse :

| # | Dossier | Statut |
|---|---|---|
| 1 | [`01-architecture-technique/`](01-architecture-technique/) | 🟢 MCD/MLD/DDL V2 grossiste ✅ — DDL ⚠️ pas encore exécuté |
| 2 | [`02-pra/`](02-pra/) | 🟢 rédigé |
| 3 | [`03-supervision/`](03-supervision/) | 🟢 rédigé |
| 4 | [`04-optimisation/`](04-optimisation/) | 🟢 rédigé |
| 5 | [`05-runbook/`](05-runbook/) | 🟢 rédigé |
| 6 | [`06-analyse-logs/`](06-analyse-logs/) | 🟢 rédigé |
| 7 | [`07-gestion-projet/`](07-gestion-projet/) | 🟡 journal (6) + risques (9) — reste planning + suivi tâches |
| 8 | [`08-note-direction/`](08-note-direction/) | 🟢 rédigée |
| 9 | [`09-soutenance/`](09-soutenance/) | 🟡 plan défini, support à produire |

## Workflow Git

- Branche : `main`
- Format commit : `<scope>(<version>): <description courte>` + corps explicatif si nécessaire
  - Exemples : `mcd(v4):`, `mld(v1):`, `ddl(v1):`, `ha(v1):`, `docs:`
- Pas de push sans validation Ianis (lead)
- Pas de force-push, pas de réécriture d'historique

## Outils

- **MCD** : Mocodo (`cd 01-architecture-technique/mcd && python -m mocodo --input wms-mcd.mcd --output_dir . --svg_to png --detect_overlaps`)
- **DDL** : à écrire à la main puis tester sur conteneur MariaDB 11.4 local
- **HA** : Galera (à provisionner sur VMs ou conteneurs)
