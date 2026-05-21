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
| MCD officiel ([`wms-mcd.md`](wms-mcd.md)) | ✅ v3.1-final — convergence matérialisée à la racine |
| MCD soutenance ([`mcd-operationnel.md`](mcd-operationnel.md)) | ✅ version courte V3 officielle |
| MLD | ⏳ à reprendre |
| DDL MariaDB 11.4 LTS | ⏳ à reprendre |
| Justification SGBD | ⏳ |
| HA/PRA (Galera) | ⏳ |
| Sécurité accès | ⏳ |
| Supervision (5 KPIs) | ⏳ |
| Logs | ⏳ |
| RunBook exploitation | ⏳ |
| Pilotage projet | ⏳ |
| Note CODIR | ⏳ |
| Soutenance | ⏳ |

## Décisions de cadrage

- **SGBD** : MariaDB 11.4 LTS (justification à formaliser).
- **MCD V3 officielle à 7 entités** : SITE, EMPLACEMENT, ARTICLE, STOCK, UTILISATEUR, MOUVEMENT, CLIENT. Modèle 14 entités (lots/FEFO, commandes, expéditions, transporteurs) repoussé en évolution fonctionnelle.
- **Multi-tenant** : verrouillé par l'identifiant composite `ARTICLE (CODE_CLIENT, REFERENCE)`, puis par FK composite `(id_article, id_client)` depuis `STOCK` et `MOUVEMENT` au MLD/DDL.
- **Rattachement site** : `STOCK` hérite du site via `EMPLACEMENT`; `MOUVEMENT` dérive son site via l'emplacement de départ ou d'arrivée.

## Ressources

- [`ressources/sujet-mspr3.pdf`](ressources/sujet-mspr3.pdf) — cahier des charges EPSI
- [`ressources/grille-evaluation.pdf`](ressources/grille-evaluation.pdf) — grille d'évaluation jury
