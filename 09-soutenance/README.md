# Livrable 9 — Soutenance

**Statut** : ⏳ à faire
**Exigence sujet** : §III.2 « support de présentation [...] synthétiser les principaux éléments du travail réalisé : démarche suivie, difficultés rencontrées, solutions mises en place, résultats obtenus et perspectives »
**Format imposé** : 20 min présentation orale collective + 30 min entretien avec jury = 50 min total. Jury = 2 évaluateurs externes.
**Owner** : Ianis (coordination)

## Contenu attendu

- [ ] Support slides (PowerPoint / Google Slides / Marp / Reveal.js)
- [ ] Plan de présentation (~20 min, donc ~10-15 slides) :
  1. Contexte NTL (1 slide)
  2. Démarche projet + équipe (1 slide)
  3. Modèle de données — MCD/MLD V2 grossiste (3 slides : diagramme + décisions structurantes) — **orateurs : Ianis + Blaise**
  4. Architecture HA/PRA — réplication MariaDB + sauvegardes (2 slides) — **orateurs : Ojvind + Zaid**
  5. Sécurité + supervision (2 slides)
  6. RunBook + analyse logs (1 slide)
  7. Difficultés rencontrées + solutions (2 slides) — **pivot de cadrage ici** : ambiguïté grossiste/3PL du sujet → postulat grossiste explicite (ADR 0003), simplification du modèle (multi-tenant reporté V2). Démarche d'itération maîtrisée, pas un tâtonnement.
  8. Résultats obtenus + perspectives V2 (1 slide)
  9. Conclusion + questions (1 slide)
- [ ] Répartition orateurs (chaque membre parle au moins une fois)
- [ ] Préparation entretien 30 min — anticiper les questions jury (cf. [`../FAQ.md`](../FAQ.md))
- [ ] Démo éventuelle (DDL qui s'exécute, requête sur la base seedée…)

## Décisions structurantes

À documenter dans `../decisions/`.

## Point d'entrée pour démarrer

1. Lire [`../FAQ.md`](../FAQ.md) en entier — c'est le brief défense
2. Lire [`../07-gestion-projet/journal-decisions.md`](../07-gestion-projet/journal-decisions.md) — les arbitrages à mettre en avant
3. Construire les slides à partir de ces 2 documents
4. Répétition orale planifiée 1 semaine avant
