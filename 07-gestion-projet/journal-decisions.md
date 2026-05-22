# Journal des décisions majeures

> Synthèse des arbitrages structurants pour la soutenance. Format court : décision, rationale en 2 lignes, lien vers le détail. Le sujet exige ≥3 arbitrages, on en a déjà 4 documentés.

| # | Date | Décision | Rationale (court) | Détail |
|---|---|---|---|---|
| D01 | 2026-05-20 | **Périmètre MCD compact à 8 entités** au lieu du modèle complet à 14 (lots/FEFO, commandes, expéditions, transporteurs reportés V2) | Tenir 19h × 4 personnes. Cœur WMS défendable en soutenance. Évolution V2 fonctionnelle, pas un oubli. | [`../01-architecture-technique/mcd/wms-mcd.md`](../01-architecture-technique/mcd/wms-mcd.md) §1 + §7 |
| D02 | 2026-05-21 | **Multi-tenant par FK composite « option D »** `(id_article, id_client) → articles` depuis stocks et mouvements, double-verrou avec association `realise_pour` au MCD | Sépare déclarativement les données client (exigence centrale du sujet §II.1 « séparation des données par client »). Vérifié par le moteur InnoDB, pas d'isolation applicative à risque. | [`../01-architecture-technique/mcd/arbitrages-v4-ianis.md`](../01-architecture-technique/mcd/arbitrages-v4-ianis.md) point 3 |
| D03 | 2026-05-21 | **TRANSFERT intra-site garanti déclarativement** par dénormalisation `mouvements.id_site` + FK composites `(id_depart, id_site)` et `(id_arrivee, id_site)` vers `emplacements` | Évite un trigger métier complexe. Garantie vérifiée par le moteur. | [`../01-architecture-technique/wms-mld.md`](../01-architecture-technique/mld/wms-mld.md) §5 |
| D04 | 2026-05-22 | **Règle XOR `ck_mvt_src_dst` portée par triggers** au lieu de CHECK, à cause d'un bug parser MariaDB 11.4 confirmé par investigation | Garder les FK composites (priorité D03) en gardant la sémantique XOR. 8 tests fonctionnels valident l'équivalence. | [`../decisions/0001-bug-mariadb-check.md`](../decisions/0001-bug-mariadb-check.md) |
| D05 | 2026-05-22 | **SGBD retenu : MariaDB 11.4 LTS** (vs MySQL 8.4 / PostgreSQL 16) | Drop-in MySQL existant NTL, Galera natif (HA mûre depuis 2012), mariabackup pour RPO 15 min, indépendance Oracle. Décision actée à l'unanimité après revue comparative. | [`../decisions/0002-sgbd-mariadb.md`](../decisions/0002-sgbd-mariadb.md) |

## Décisions à venir (en attente d'arbitrage)

- **D06** : résolution finale du bug MariaDB CHECK (statu quo triggers, vs test versions plus récentes, vs autre). Échéance : avant démarrage HA/PRA. → [`../decisions/0001-bug-mariadb-check.md`](../decisions/0001-bug-mariadb-check.md)
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
