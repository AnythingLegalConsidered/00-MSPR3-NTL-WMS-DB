---
id: "0002"
titre: "Choix du SGBD : MariaDB 11.4 LTS"
statut: "VALIDÉ — 2026-05-22 (vote équipe)"
created: "2026-05-22"
updated: "2026-05-22"
owner: "Équipe MSPR3"
impact: "transverse — architecture (livrable 1), HA/PRA (livrable 2), sauvegardes, supervision (livrable 3), logs (livrable 6)"
related:
  - "../README.md"
  - "../01-architecture-technique/ddl/wms-schema.sql"
  - "../07-gestion-projet/journal-decisions.md"
  - "../ressources/sujet-mspr3.pdf"
---

# 0002 — Choix du SGBD : MariaDB 11.4 LTS

## Problème en 3 lignes

Le sujet MSPR3 (§II.3) exige de **justifier explicitement** le SGBD retenu pour le WMS NTL. L'existant NTL est sous MySQL (Annexe C, WMS-DB Ubuntu 20.04). Trois candidats sérieux sur le périmètre : MariaDB 11.4 LTS, MySQL 8.4 LTS, PostgreSQL 16.

## Contraintes structurantes (rappel sujet + annexes)

- **Existant** : MySQL en place chez NTL → migration ou continuité à arbitrer.
- **Équipe IT NTL** : 1 RSI + 1 admin sys itinérant + 1 tech + 1 alternant. **Pas de DBA**.
- **RTO 1h / RPO 15 min** → besoin d'une HA mûre et de hot backups physiques rapides.
- **Multi-tenant** déjà acté (séparation par client, FK composite — cf. D02).
- **Budget projet** : 19h × 4 personnes. Aucune marge pour reformer l'équipe NTL sur une stack inconnue.
- **Jury** : un examinateur regardera "pourquoi ce SGBD et pas un autre" — il faut un argumentaire chiffré et opposable.

## Options évaluées

### Option A — MariaDB 11.4 LTS ✅ RETENUE

**Pour**
- Drop-in replacement MySQL (wire-protocol compatible, datadir interchangeable depuis MySQL 5.7) → **migration WMS-DB sans douleur**, équipe IT NTL n'est pas reformée.
- **Galera Cluster natif** : multi-master synchrone, gratuit, mûr en production depuis 2012. C'est la HA SQL open-source la plus éprouvée du marché.
- `mariabackup` natif, gratuit, hot backup physique **incrémental** → tient le RPO 15 min combiné avec le binlog streaming.
- LTS communautaire jusqu'en 2029, **indépendance Oracle** (la Fondation MariaDB garantit la trajectoire open-source — argument résilience pour une PME).
- Compatible Zabbix (template officiel) → réutilise SUPER-01 existant (Annexe C).
- ProxySQL gratuit en façade pour routing read/write.

**Contre**
- Support commercial moins industriel qu'Oracle (mitigé : on parle d'une PME, pas d'un grand compte avec budget enterprise).
- MaxScale (load balancer MariaDB officiel) en licence BSL au-delà de 3 nœuds → contourné par ProxySQL gratuit.
- Bug parser confirmé sur les CHECK avec FK composites (cf. [0001](0001-bug-mariadb-check.md)) → contournement par triggers, sémantique préservée et testée.

### Option B — MySQL 8.4 LTS ❌ ÉCARTÉE

**Pour**
- Déjà en place chez NTL → **migration nulle**, continuité opérationnelle parfaite.
- Support Oracle disponible (mais payant).
- LTS jusqu'en 2032.

**Contre**
- Garder l'existant sans argumenter techniquement = **se faire taper en soutenance** ("vous avez juste gardé l'existant ?"). Le sujet exige une justification, pas une inertie.
- **Group Replication / InnoDB Cluster moins mature que Galera** : historique de split-brain et de comportements problématiques en partition réseau documenté.
- Double licence GPL/commerciale Oracle → risque trajectoire (précédent : fork MariaDB en 2009 suite au rachat Sun→Oracle).
- XtraBackup (équivalent mariabackup) maintenu par Percona, pas par Oracle → dépendance externe.

### Option C — PostgreSQL 16 ❌ ÉCARTÉE

**Pour**
- Techniquement supérieur sur le multi-tenant (**Row-Level Security natif**, alors que MariaDB/MySQL nécessitent vues + GRANT).
- Contraintes plus riches (CHECK robustes, EXCLUDE), MVCC plus propre.
- pgBackRest = référence backup PostgreSQL.

**Contre**
- **Rupture totale avec l'existant NTL** → migration WMS-APP requise (driver, syntaxe, types). Hors périmètre MSPR (sujet : concevoir la BDD, pas réécrire l'appli).
- **Équipe IT NTL = 0 compétence Postgres** → risque opérationnel inacceptable pour une infra critique avec RTO 1h.
- HA via Patroni + etcd = à assembler soi-même, charge cognitive supérieure pour une équipe IT réduite.
- 19h × 4 personnes : pas le budget pour migrer une application métier ET livrer les 9 livrables.

## Décision finale

**MariaDB 11.4 LTS** retenue à l'unanimité par l'équipe MSPR3 le 2026-05-22.

## Arguments pour la soutenance (à graver)

1. **Continuité opérationnelle** : drop-in MySQL → migration WMS-DB triviale, équipe IT NTL pas reformée.
2. **HA éprouvée et gratuite** : Galera Cluster est la solution multi-master sync la plus mûre du marché open-source (production-grade depuis 2012).
3. **Sauvegardes RPO 15 min** : `mariabackup` (hot, physique, incrémental) + binlog streaming = combo natif sans dépendance externe.
4. **Indépendance Oracle** : la Fondation MariaDB garantit la trajectoire open-source → mitigation du risque licence/fork pour une PME exposée aux décisions d'un éditeur unique.
5. **Cohérence avec les compétences PME** : pas de DBA chez NTL, équipe familière de l'écosystème MySQL → MariaDB s'inscrit dans la continuité sans rupture.

## Piège à éviter en soutenance

Ne **pas** dire "MariaDB est mieux que MySQL". C'est faux.
Dire : **"MariaDB est le meilleur compromis dans CE contexte (PME, équipe IT réduite, existant MySQL, HA exigée, indépendance éditeur souhaitée)"**.

## Conséquences en cascade (décisions ouvertes débloquées)

- D06 (topologie Galera) : 2 nœuds Lille + 1 arbitre, ou 3 nœuds full ? Trade-off avec Annexe B (1 seul hyperviseur).
- D07 (PRA off-site) : replica async Azure Landing Zone ou rester full on-prem ?
- D08 (sauvegarde) : mariabackup + binlog streaming → fréquences et rétention à arbitrer.
- D09 (reverse proxy SQL) : ProxySQL vs HAProxy.

## Mise à jour

- 2026-05-22 : décision actée en réunion d'équipe après revue comparative 3 candidats. Trace ADR formalisée.
