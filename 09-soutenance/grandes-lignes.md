# Grandes lignes — Soutenance MSPR3 NTL WMS

> Fiche de synthèse slide par slide. Mots-clés + explication basique pour avoir le fil rouge en tête.
> **14 slides** (slide Optimisation retirée) — ~19 min.

---

## Slide 1 — Titre
**Mots-clés** : WMS, NordTransit Logistics, industrialisation, équipe 4 personnes
**En bref** : Présentation du projet — concevoir une base de données fiable pour le système qui pilote les entrepôts de NTL.

---

## Slide 2 — Contexte & enjeu
**Mots-clés** : PME logistique, 4 sites, criticité maximale, existant fragile, MySQL mono-machine
**En bref** : Si la base tombe, les 4 entrepôts s'arrêtent. Aujourd'hui : pas de HA, sauvegardes non testées, aucun RTO/RPO défini.

---

## Slide 3 — Démarche & pilotage
**Mots-clés** : 4 rôles, 19h budget, journal de décisions (6 ADR), registre risques (9 risques)
**En bref** : Méthode en 4 temps (cadrage → conception → industrialisation → doc). Chaque décision tracée, chaque risque identifié.

---

## Slide 4 — MCD
**Mots-clés** : 8 tables, 3FN, CHECK/UNIQUE/FK RESTRICT, pas de trigger, stock = article + lieu + quantité
**En bref** : Modèle simple et lisible. Intégrité portée par le schéma. Postulat grossiste (pas 3PL) → pas d'isolation multi-tenant.

---

## Slide 5 — Choix SGBD
**Mots-clés** : MariaDB 11.4 LTS, continuité, migration quasi nulle, PostgreSQL écarté
**En bref** : MariaDB = remplaçant direct de MySQL. L'équipe connaît, l'appli aussi. PostgreSQL = trop de réécriture.

---

## Slide 6 — Architecture HA
**Mots-clés** : HAProxy, master + 2 réplicas, réplication asynchrone, binlogs
**En bref** : 1 maître (écritures) → 2 réplicas (1 local HA, 1 distant PRA). Simple, léger, adapté à une petite équipe.

---

## Slide 7 — PRA & sauvegardes
**Mots-clés** : RTO 1h, RPO 15min, mariabackup, binlogs archivés, tests de restauration
**En bref** : Bascule HA en 5-10 min, perte site en 20-40 min. Sauvegardes automatisées + vérifiées. Une sauvegarde non testée = pas une sauvegarde.

---

## Slide 8 — Sécurité accès
**Mots-clés** : Moindre privilège, comptes séparés, MFA, coffre à secrets
**En bref** : App = compte minimal. Admin = MFA. Secrets = jamais en clair. Comptes nominatifs = traçabilité.

---

## Slide 9 — Note CODIR
**Mots-clés** : 5 risques cyber, langage métier, plan 3 vagues, RGPD 72h
**En bref** : Note non-technique pour la direction. Impact business, pas jargon. Plan priorisé (6 semaines / 3 mois / 6 mois).

---

## Slide 10 — Supervision
**Mots-clés** : Prometheus/Grafana, 5 KPIs, seuils reliés à objectifs, latence/connexions/réplication/disque/backup
**En bref** : On surveille ce qui compte. Chaque seuil = un risque concret (ex : retard réplication > 30s = RPO menacé).

---

## Slide 11 — RunBook & logs
**Mots-clés** : RunBook complet, checklists, procédure incident, escalade N1→N4, 5 sources de logs
**En bref** : Guide d'exploitation quotidien. Logs cartographiés (erreurs, lentes, binlogs, HAProxy, backups) pour diagnostiquer vite.

---

## Slide 12 — Difficultés → solutions
**Mots-clés** : Ambiguïté grossiste/3PL, postulat assumé, ADR 3, transparence DDL non exécuté
**En bref** : Le sujet était flou. On a tranché (grossiste) et tracé. Limites = décisions, pas oublis. DDL pas encore testé = perspective V2.

---

## Slide 13 — Résultats & perspectives
**Mots-clés** : 8 livrables, 8 tables, RTO/RPO tenus, roadmap V2 (multi-tenant, lots, expéditions, Galera)
**En bref** : Cahier des charges couvert. Socle solide = MVP industrialisable. Perspectives claires = on sait où aller.

---

## Slide 14 — Conclusion
**Mots-clés** : Socle sûr/supervisé/résilient, postulat assumé, questions
**En bref** : Base WMS prête à industrialiser. Fil rouge : face à l'ambiguïté, on a tranché et tracé. Ouverture aux questions.

---

## Fil rouge à marteler
> « On a tranché une ambiguïté du sujet par un postulat assumé et tracé. » — jamais « on n'a pas compris le sujet ».
