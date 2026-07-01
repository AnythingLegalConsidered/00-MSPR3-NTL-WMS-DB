# Registre des risques

> Sujet exige ≥5 risques avec impacts et mesures de mitigation. On en liste 8 (projet + technique + métier).

## Échelle

- **Probabilité** : Faible (F) / Moyenne (M) / Élevée (E)
- **Impact** : Faible (F) / Moyen (M) / Élevé (E) / Critique (C)
- **Criticité** = Probabilité × Impact, codée vert/jaune/orange/rouge

## Risques identifiés

| # | Catégorie | Risque | Prob. | Impact | Crit. | Mitigation | Owner |
|---|---|---|---|---|---|---|---|
| R01 | Projet | Charge sous-estimée — 19h × 4 = 76h vs périmètre 9 livrables | E | E | 🔴 | Périmètre MCD réduit à 8 entités (D01). Découpage clair par livrable. Livrables 4/6 (optim + logs) peuvent être traités allégés. | Ianis |
| R02 | Projet | Indisponibilité d'un membre équipe en période critique | M | E | 🟠 | RACI à formaliser, pair-programming sur livrables critiques (architecture, HA). Documentation systématique en mode « auto-portant » via le repo. | Ianis |
| R03 | Technique | **DDL V2 pas encore exécuté/testé sur MariaDB 11.4** (cf. `wms-ddl.md` §8) — un écart pourrait apparaître à l'exécution | M | M | 🟡 | Plan de tests défini (4 CHECK, 10 FK, UNIQUE, ON DELETE RESTRICT). À exécuter sur instance locale avant tout déploiement. | Ianis + Blaise |
| R04 | Technique | Cluster Galera ne tient pas RTO 1h / RPO 15 min en conditions réelles | M | C | 🔴 | Tests de bascule planifiés dans le livrable 2. Sauvegardes externalisées en backup. Procédures de restauration mesurées chronométriquement. | À définir (livrable 2) |
| R05 | Technique | Saturation des liens WAN entrepôts (200 Mbps) avec réplication + synchros M365 | M | E | 🟠 | Topologie à arbitrer (cf. D07). Possibilité : cluster concentré au siège + réplication asynchrone vers le réplica PRA. | À définir (livrable 1) |
| R06 | Sécurité | Compromission d'un compte applicatif WMS-APP → accès lecture/écriture base | F | C | 🟠 | Principe moindre privilège dans la politique d'accès (livrable 1). Comptes nominatifs, rotation secrets, MFA pour admins. Audit log activé. | À définir (livrable 1) |
| R07 | Métier | Indisponibilité WMS-DB en journée ouvrée (5h30-18h30) = arrêt des 4 sites | M | C | 🔴 | HA Galera (livrable 2). RunBook procédure incident (livrable 5). Astreinte formalisée. Supervision orientée service (livrable 3). | À définir (livrables 2/3/5) |
| R08 | Méthode | Décisions techniques perdues / non documentées → impossible à défendre en soutenance | M | E | 🟠 | Journal des décisions vivant ([`journal-decisions.md`](journal-decisions.md)). ADR systématique dans [`../decisions/`](../decisions/). CHANGELOG. | Ianis |
| R09 | Projet | Dérive du périmètre (ajouts non prévus en cours de route) | M | M | 🟡 | Périmètre verrouillé documenté ([`../EQUIPE.md`](../EQUIPE.md) « Décisions verrouillées »). Toute évolution = ADR avec justification. | Ianis |

## Convention

Toute nouvelle menace identifiée pendant le projet → ajouter une ligne ici (R10, R11…). Si réalisée → noter date + impact effectif + correctif appliqué.
