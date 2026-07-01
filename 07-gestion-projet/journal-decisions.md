# Journal des décisions majeures

> Synthèse des arbitrages structurants pour la soutenance. Format court : décision, rationale en 2 lignes, lien vers le détail. Le sujet exige ≥3 arbitrages, on en documente 6.
>
> ⚠️ **Note de lecture** : le projet a connu un **pivot de cadrage** le 2026-05-22 (décision **D13**, [ADR 0003](../decisions/0003-postulats-cadrage-ntl.md)) : passage d'une hypothèse **multi-tenant / 3PL** à un postulat **grossiste**. Les décisions **D02, D03, D04** ont été prises sous l'ancienne hypothèse et sont **SUPERSEDED** — conservées ici pour tracer l'itération. Le modèle réellement rendu (MCD/MLD/DDL V2) est le modèle grossiste.

| # | Date | Décision | Rationale (court) | Détail |
|---|---|---|---|---|
| D01 | 2026-05-20 | **Périmètre MCD compact à 8 entités** au lieu du modèle complet à 14 (lots/FEFO, commandes, expéditions, transporteurs reportés V2) | Tenir 19h × 4 personnes. Cœur WMS défendable en soutenance. Évolution V2 fonctionnelle, pas un oubli. | [`../01-architecture-technique/mcd/wms-mcd.md`](../01-architecture-technique/mcd/wms-mcd.md) §1 + §7 |
| ~~D02~~ | 2026-05-21 | ~~**Multi-tenant par FK composite « option D »**~~ — **SUPERSEDED par D13** | Pris sous l'hypothèse 3PL. Le postulat grossiste (D13) retire le multi-tenant : séparation client assurée par attribution (`mouvement.id_client`, `commande`). | [ADR 0003](../decisions/0003-postulats-cadrage-ntl.md) |
| ~~D03~~ | 2026-05-21 | ~~**TRANSFERT intra-site garanti par FK composites `(id_depart, id_site)`**~~ — **SUPERSEDED par D13** | Le modèle grossiste n'a ni `id_depart`/`id_arrivee` ni `id_site` sur `mouvement` : un mouvement référence un seul `id_stock`. | [ADR 0003](../decisions/0003-postulats-cadrage-ntl.md) |
| ~~D04~~ | 2026-05-22 | ~~**Règle XOR portée par triggers (bug MariaDB CHECK)**~~ — **SUPERSEDED par D13** | Sans FK composite sur `mouvement`, le bug ne se déclenche pas. Le DDL V2 n'a **aucun trigger**. | [ADR 0001](../decisions/0001-bug-mariadb-check.md) (superseded) |
| D05 | 2026-05-22 | **SGBD retenu : MariaDB 11.4 LTS** (vs MySQL 8.4 / PostgreSQL 16) | Drop-in MySQL existant NTL, Galera disponible nativement (argument HA), mariabackup pour RPO 15 min, indépendance Oracle. Décision actée à l'unanimité après revue comparative. | [`../decisions/0002-sgbd-mariadb.md`](../decisions/0002-sgbd-mariadb.md) |
| **D13** | 2026-05-22 | **Postulat de cadrage : NTL = grossiste** (stock propre, pas 3PL) → modèle V2 : multi-tenant retiré, FOURNISSEUR dé-entifié (attribut texte), table `commande` ajoutée. **8 tables, 0 trigger, 0 FK composite.** | Le sujet est ambigu sur la nature de NTL. On tranche par un postulat explicite plutôt que de deviner. Sépare les données client par attribution. Multi-tenant = évolution V2 si bascule 3PL. | [ADR 0003](../decisions/0003-postulats-cadrage-ntl.md) |

## Décisions à venir (en attente d'arbitrage)

- **D07** : topologie cluster Galera (3 nœuds tous au siège vs 2 nœuds + arbitre off-site vs autre) — dépend de Annexe B (1 seul hyperviseur Lille)
- **D08** : PRA off-site (replica async Azure Landing Zone vs full on-prem + backups externalisés)
- **D09** : stratégie de sauvegarde (mariabackup + binlog : fréquences, rétention, tests resto)
- **D10** : reverse proxy SQL (ProxySQL vs HAProxy vs MaxScale)
- **D11** : stack de supervision (extension Zabbix existant vs Prometheus + Grafana vs PMM)
- **D12** : stack de logs centralisée (Fluent Bit + Loki vs ELK vs Graylog)

## Convention

Chaque nouvelle décision majeure :
1. ADR détaillé créé dans [`../decisions/000N-titre.md`](../decisions/) (format : problème, options, recommandation, décision finale)
2. Ligne synthétique ajoutée à ce journal avec pointeur vers l'ADR
