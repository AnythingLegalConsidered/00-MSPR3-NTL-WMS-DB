# AGENTS.md — instructions pour CLI IA (Claude Code, opencode, codex)

> Fichier de contexte pour assistants IA travaillant sur ce repo. Lisez-le avant toute action.

## Projet

MSPR3 EPSI Nantes — conception base de données WMS pour NordTransit Logistics (PME logistique fictive). Cible **MariaDB 11.4 LTS**. Contraintes : RTO 1h, RPO 15 min.

## Décisions verrouillées — NE PAS rouvrir

- **Postulat métier : NTL = grossiste** (stock propre, pas 3PL) — `decisions/0003-postulats-cadrage-ntl.md`
- **MCD V2 grossiste, 8 tables** (SITE, LOCALISATION, ARTICLE, CLIENT, STOCK, MOUVEMENT, UTILISATEUR + `commande`)
- **Pas de multi-tenant** : séparation client = attribution (`mouvement.id_client`, `commande`). Isolation = évolution V2 si 3PL.
- **Fournisseur** = attribut texte `article.fournisseur` (pas d'entité)
- Surrogate keys `id_*` au MLD, code métier en UNIQUE
- **Aucun trigger, aucune FK composite** : intégrité par FK simples + CHECK + UNIQUE
- ⚠️ L'ancien modèle V4 multi-tenant (FK composite option D, triggers, bug MariaDB) est **ABANDONNÉ** — ne pas le réintroduire. ADR 0001 superseded.

Si une décision semble incohérente : **propose un workaround MLD/DDL, ne rouvre pas le MCD**.

## Structure repo (1 dossier par livrable EPSI)

| Dossier | Livrable |
|---|---|
| `01-architecture-technique/` | MCD + MLD + DDL + justif SGBD + politiques |
| `02-pra/` | Plan de Reprise d'Activité |
| `03-supervision/` | Guide supervision + 5 KPIs |
| `04-optimisation/` | Démarche optimisation BDD |
| `05-runbook/` | RunBook exploitation |
| `06-analyse-logs/` | Analyse de journaux |
| `07-gestion-projet/` | Équipe + planning + risques + journal décisions |
| `08-note-direction/` | Note CODIR |
| `09-soutenance/` | Support soutenance |
| `decisions/` | ADR détaillés |
| `brief-ia/` | Kit d'amorçage IA pour camarades |
| `ressources/` | Sujet EPSI + grille évaluation |

## Fichiers à lire selon la question

| Question | Fichier |
|---|---|
| Modèle conceptuel, entités, associations | `01-architecture-technique/mcd/wms-mcd.md` |
| Modèle logique, tables, FK, contraintes | `01-architecture-technique/mld/wms-mld.md` |
| DDL exécutable + choix techniques | `01-architecture-technique/ddl/` |
| Pourquoi telle décision (synthèse) | `07-gestion-projet/journal-decisions.md` |
| ADR détaillé d'une décision | `decisions/000N-...md` |
| FAQ soutenance prête à défendre | `FAQ.md` |
| État projet, livrables restants | `README.md` + `EQUIPE.md` |
| Historique changements | `CHANGELOG.md` |
| Sujet officiel EPSI | `ressources/sujet-mspr3.pdf` |

## Style attendu

- **Langue** : français. Code et identifiants SQL en anglais (snake_case).
- **Concision** : pas de blabla, droit au but. Tableaux quand pertinent.
- **Surgical** : chaque modification trace à la demande, pas de refactor adjacent.
- **Anti-sycophancy** : si une demande est incohérente avec une décision verrouillée, le dire.

## Commits

Format : `<scope>(<version>): <description>` — exemples : `mcd(v4):`, `mld(v1):`, `ddl(v1):`, `docs:`.

**Pas de mention d'IA / co-auteur IA dans les messages de commit.**

Pas de push sans validation explicite du lead (Ianis).
