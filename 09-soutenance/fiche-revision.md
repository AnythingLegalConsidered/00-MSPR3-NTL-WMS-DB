# Fiche de révision — Soutenance MSPR3 NTL WMS-DB

> À lire et relire avant la soutenance. Distillé de [`../FAQ.md`](../FAQ.md), du [journal des décisions](../07-gestion-projet/journal-decisions.md) et des livrables. Format : 20 min oral collectif + 30 min entretien jury (2 évaluateurs).

---

## 0. Le projet en 30 secondes (à savoir réciter)

> NTL est une **PME logistique** des Hauts-de-France (siège Lille + 3 entrepôts). On a conçu et industrialisé la **base de données de son WMS** : modèle de données, haute dispo / PRA, sécurité, supervision, exploitation. Le sujet étant **ambigu** sur la nature de NTL (grossiste ou 3PL), on a tranché par un **postulat explicite — grossiste** — et cadré la V1 dessus. Résultat : **8 tables, 3NF, 0 trigger**, une archi tenant **RTO 1 h / RPO 15 min**.

**Le fil rouge à marteler** : *« on a tranché une ambiguïté par un postulat assumé »* — JAMAIS *« on n'a pas compris le sujet »*.

---

## 1. Chiffres-clés à connaître par cœur

| Sujet | Valeur | Détail |
|---|---|---|
| **RTO** | **1 h** | Recovery Time Objective — délai max de reprise |
| **RPO** | **15 min** | Recovery Point Objective — perte de données max |
| Fenêtre maintenance | nuit uniquement | activité 5h30 → 18h30 ouvré |
| Budget | 19 h × 4 pers. | justifie le périmètre resserré |
| Modèle | **8 tables** | 7 entités + 1 table associative `commande` |
| Triggers / FK composites | **0 / 0** | intégrité par FK simples + CHECK + UNIQUE |
| Décisions tracées | **6 ADR** | sujet en exige ≥ 3 |
| SGBD | **MariaDB 11.4 LTS** | LTS jusqu'en 2029 |
| Serveurs BDD | **3** | BDD1 Master, BDD2 Slave HA, BDD3 Slave PRA |
| Indicateurs supervision | **5** | latence, connexions, réplication, disque, sauvegardes |
| RTO réel estimé | 5–10 min (HA) / 20–40 min (PRA) | tient largement dans la cible 1 h |

---

## 2. Le modèle de données (Ianis + Blaise)

**7 entités** : `SITE`, `LOCALISATION`, `ARTICLE`, `CLIENT`, `STOCK`, `MOUVEMENT`, `UTILISATEUR`
**+ 1 table associative** : `commande` (N-N entre CLIENT et ARTICLE)

### Les 5 réponses à blinder

| Question jury | Réponse |
|---|---|
| **Pourquoi STOCK est une entité ?** | `stock` = **1 article × 1 emplacement × 1 quantité**. Entité réifiée porteuse de la quantité. `UNIQUE(id_article, id_localisation)` → 50 palettes du même article = 1 ligne `quantite=50`. |
| **Pourquoi `mouvement.id_client` nullable ?** | Sortie client → `id_client` renseigné. Mouvement **interne** (transfert, inventaire) → **NULL** (pas de client). Issu de `CONCERNE` (0,1 — 0,N). |
| **Les 4 types de mouvement ?** | Attribut `type` + `CHECK (type IN ('entree','sortie','ajustement','transfert'))` + `quantite > 0`. La **quantité reste positive**, le **sens** est porté par `type`. Un mouvement référence **1 seul** `id_stock`. |
| **Pourquoi `fournisseur` en attribut texte ?** | Périmètre : gestion achats portée par l'**ERP commercial NTL**, hors WMS V1. `article.fournisseur VARCHAR(100)` suffit à tracer l'origine. V2 → entité `FOURNISSEUR` si intégration. |
| **Pourquoi surrogate keys `id_*` ?** | Standard industriel. `INT UNSIGNED` (4 octets) → FK légères, jointures rapides. Codes métier (`siret`, `code`, `reference`) conservés en `UNIQUE NOT NULL` pour la traçabilité externe. |

### Intégrité & technique
- **FK simples + CHECK + UNIQUE** (pas de triggers, pas de FK composites) → modèle simple, lisible.
- **`ON DELETE RESTRICT` partout** : jamais détruire l'historique mouvements/stocks. Suppression métier = soft-delete applicatif.
- **InnoDB** : seul moteur MariaDB transactionnel avec FK + ACID (MyISAM/Aria ne supportent pas les FK).
- **`utf8mb4`** : vrai UTF-8 (4 octets) ; `utf8` MariaDB = 3 octets, ne couvre pas tout l'Unicode.
- **3NF** respectée.

> ⚠️ **HONNÊTETÉ — le DDL n'a PAS encore été exécuté** sur une instance MariaDB 11.4. Plan de tests défini (4 CHECK, 10 FK, UNIQUE, RESTRICT). **Ne JAMAIS prétendre l'avoir testé** — dire « exécution = prochaine étape, c'est notre 1ʳᵉ perspective V2 ». Le jury valorise l'honnêteté.

---

## 3. Architecture HA / PRA (Ojvind + Zaid)

```
WMS-APP → HAProxy → BDD1 (Master) ─► BDD2 (Slave HA, local)
                                   └─► BDD3 (Slave PRA, distant)
```

- **BDD1** : reçoit toutes les écritures (production).
- **BDD2** : réplication locale → couvre panne service/VM du master.
- **BDD3** : réplication distante → couvre perte du site Lille.
- Réplication **asynchrone** + **binlogs** (faible impact master, simple à exploiter — adapté à l'équipe IT réduite). RPO 15 min garanti par les binlogs (PITR).

### Scénarios de bascule

| Scénario | Solution | RTO estimé |
|---|---|---|
| Panne service MariaDB BDD1 | bascule HAProxy → BDD2 | 5–10 min |
| Perte VM BDD1 | bascule → BDD2 + promotion | 5–10 min |
| Perte site Lille | bascule → BDD3 (PRA) | 20–40 min |
| Corruption logique | restauration dump + relecture binlogs | selon volume |

**Conditions de bascule HA** (à vérifier avant) : `Slave_IO_Running=Yes`, `Slave_SQL_Running=Yes`, `Seconds_Behind_Master=0`.
**Sauvegardes** : complète quotidienne (`mariabackup`) + binlogs 48 h + configs MariaDB/HAProxy.
**Tests planifiés** : bascule HA trimestrielle · bascule PRA semestrielle · restauration mensuelle.

---

## 4. Supervision (Ojvind) — 5 indicateurs

Stack : **Prometheus + Grafana** · `mysqld_exporter` + `node_exporter` · Slow Query Log.

| Indicateur | Normal | Alerte | Critique |
|---|---|---|---|
| Latence SQL | < 50 ms | > 150 ms | > 300 ms |
| Connexions actives | < 50 | > 100 | > 150 |
| Réplication (retard) | 0–5 s | > 15 s | > 30 s |
| Espace disque libre | > 20 % | < 15 % | < 10 % |
| Succès sauvegardes | 100 % | 1 échec | > 1 échec |

> Lier chaque seuil à un objectif : réplication **> 30 s → RPO 15 min menacé** ; disque **< 10 % → arrêt MariaDB possible**.

---

## 5. Sécurité — note CODIR (Zaid) — 5 risques + plan

| # | Risque | Gravité |
|---|---|---|
| 1 | Arrêt prolongé de la base (4 sites bloqués) | Critique |
| 2 | Vol d'un accès applicatif | Critique |
| 3 | Ransomware + sauvegardes inutilisables | Critique |
| 4 | Exfiltration des données clients | Élevée |
| 5 | Perte de traçabilité réglementaire | Élevée |

**Plan d'action priorisé** :
- **P1 (immédiat, 6 sem.)** : sauvegardes externalisées **3-2-1** · restauration testée mensuellement · cluster HA · **MFA admin** · secrets en coffre.
- **P2 (3 mois)** : cloisonnement des accès (**moindre privilège**) · **audit log inviolable** 12 mois · runbook incident.
- **P3 (6 mois)** : exercice de crise · assurance cyber · sensibilisation.

> Enjeu **RGPD** : notification sous **72 h** en cas de fuite. Impacts **qualitatifs** (BIA chiffrée demandée au CODIR — assumé, pas un manque).

---

## 6. Exploitation — RunBook & logs (Zaid)

- **RunBook** : Start/Stop, health checks, checklists quotidienne/hebdo, gestion incidents, **matrice d'escalade N1→N4** (15 min → 2 h), KPI.
- **Logs — 5 sources** : `error.log`, `slow.log`, binlogs, HAProxy, sauvegardes. Patterns critiques cartographiés (InnoDB corruption, `Slave_IO=No`, Too many connections, Backend DOWN, Backup failed) → chacun avec gravité + action.

---

## 7. LE PIÈGE N°1 (à connaître absolument)

> **Jury** : « Le sujet demande la séparation des données par client, je ne la vois pas comme une isolation forte dans votre schéma. »

> **Réponse** : « Sous notre postulat **grossiste** (stock propre NTL), la séparation pertinente est l'**attribution** — présente via `mouvement.id_client` et la table `commande` : on sait parfaitement qui a commandé/reçu quoi. L'**isolation multi-tenant** (un client ne voit jamais les données d'un autre) ne se justifie qu'en modèle **3PL**, qu'on a explicitement **réservé à une V2**. C'est un arbitrage **tracé (ADR 0003)**, pas un manque. »

---

## 8. Le pivot de cadrage (la difficulté à raconter — Ianis)

**Problème** : sujet ambigu → « PME logistique » + « séparation par client » se lit grossiste OU 3PL.
**Solution** : postulat explicite **grossiste** (ADR 0003, 22/05). Démarche d'**itération maîtrisée**, pas du tâtonnement.

**Conséquences** (décisions D02/D03/D04 → **SUPERSEDED** par D13) :
- Multi-tenant (FK composite) **retiré** → reporté V2 si bascule 3PL.
- Triggers **supprimés** (le bug MariaDB CHECK ne s'applique plus) → **0 trigger**.
- FOURNISSEUR **dé-entifié** (attribut texte) + table `commande` ajoutée → **8 tables**.

---

## 9. Choix techniques — justifications

| Choix | Pourquoi (1 phrase) |
|---|---|
| **MariaDB** vs MySQL | Drop-in replacement → migration quasi nulle, équipe IT pas reformée (argument n°1). LTS 2029, Galera natif, indépendance Oracle. |
| MariaDB vs **PostgreSQL** | Postgres imposerait de réécrire le WMS-APP (driver, dialecte, types) + équipe NTL sans compétence Postgres. |
| Formule clé | Ne PAS dire « MariaDB est mieux ». Dire **« meilleur compromis dans CE contexte »**. |
| Réplication **asynchrone** | Faible impact master + simplicité (équipe réduite). Galera synchrone = évolution V2. |

---

## 10. Périmètre V1 / perspectives V2 (tout est assumé, rien n'est oublié)

| Hors V1 | Pourquoi | V2 |
|---|---|---|
| Multi-tenant (isolation) | postulat grossiste = stock propre | si bascule 3PL → FK composite `(id_article, id_client)` |
| Lots / DLC / FEFO | cœur WMS d'abord | V2 |
| Expéditions / transporteurs | hors cœur entreposage | V2 |
| Gestion fournisseurs | portée par l'ERP commercial | V2 si intégration |
| Prix / facturation | hors périmètre BDD WMS | ERP |
| **Exécution du DDL** | manque de temps | **1ʳᵉ perspective** |

> Cadrer la V1 comme un **MVP**, pas un « brouillon ».

---

## 11. Répartition orateurs (chacun parle ≥ 1 fois)

| Slides | Sujet | Orateur(s) |
|---|---|---|
| 1–3 | Titre, contexte, démarche | **Ianis** |
| 4–6 | Modèle de données (MCD, choix, intégrité) | **Ianis + Blaise** |
| 7–8 | Architecture HA / PRA | **Ojvind + Zaid** |
| 9 | Sécurité (note CODIR) | **Zaid** |
| 10 | Supervision | **Ojvind** |
| 11 | RunBook & logs | **Zaid** |
| 12 | Pivot de cadrage (difficulté) | **Ianis** |
| 13 | Résultats & perspectives | **Blaise** |
| 14 | Conclusion + questions | **équipe** |

---

## 12. Réflexes pour l'entretien (30 min)

- **Honnêteté > bluff** : DDL non exécuté, BIA non chiffrée, impacts qualitatifs → tout est assumé et tracé.
- Toute limite = **arbitrage tracé** (renvoyer à l'ADR), jamais un oubli.
- Garder cette fiche + la [FAQ](../FAQ.md) en tête pour les questions hors-script.
- Rester calme sur le piège isolation/multi-tenant (§7) — c'est LA question attendue.
