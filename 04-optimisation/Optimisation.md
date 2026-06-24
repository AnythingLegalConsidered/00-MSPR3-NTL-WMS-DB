# Optimisation de la base WMS – NTL

Ce document présente les optimisations appliquées à la base MariaDB du WMS NTL.

Elles visent à garantir :

* de bonnes performances ;
* une stabilité durable ;
* une cohérence des données ;
* une charge maîtrisée ;
* un fonctionnement optimal en production.

---

# 1. Objectifs de l’optimisation

* Réduire la latence SQL
* Améliorer les temps de réponse du WMS
* Optimiser les accès disque et mémoire
* Garantir la stabilité de la réplication
* Prévenir les goulots d’étranglement
* Réduire les requêtes lentes
* Améliorer la scalabilité

---

# 2. Optimisations au niveau du schéma

## 2.1. Indexation

### Index ajoutés (issus du MLD)

| Table        | Index                           | Objectif                                         |
| ------------ | ------------------------------- | ------------------------------------------------ |
| article      | `UNIQUE(nom)`                   | Recherche rapide par SKU / nom                   |
| stock        | `(id_article, id_localisation)` | Accès rapide au stock par article et emplacement |
| localisation | `(id_site, code)`               | Recherche rapide d’emplacements                  |
| commande     | `(id_client, date_commande)`    | Historique client performant                     |
| mouvement    | `(id_article, date)`            | Historique des mouvements performant             |
| mouvement    | `(type)`                        | Filtrage rapide des mouvements ENTRÉE / SORTIE   |

### Bénéfices

* Réduction des scans complets de tables
* Accélération des requêtes critiques du WMS
* Amélioration des performances en période de charge

---

# 3. Optimisations MariaDB (InnoDB)

## 3.1. Paramètres recommandés

### Buffer Pool

```ini id="m0e3fa"
innodb_buffer_pool_size = 60% de la RAM
```

**Objectif :**

Conserver en mémoire les données les plus fréquemment utilisées afin de limiter les accès disque.

---

### Taille des journaux InnoDB

```ini id="zhok6h"
innodb_log_file_size = 512M
```

**Objectif :**

Réduire les opérations de flush trop fréquentes et améliorer les performances d’écriture.

---

### Mode de flush

```ini id="8n7j9y"
innodb_flush_log_at_trx_commit = 2
```

**Objectif :**

Offrir un compromis acceptable entre performance et durabilité pour le contexte NTL.

---

### Binlogs

```ini id="rbdi2t"
sync_binlog = 1
expire_logs_days = 7
```

**Objectif :**

* garantir la cohérence de la réplication ;
* limiter automatiquement la croissance des binlogs.

---

### Slow Query Log

```ini id="xrd8ku"
slow_query_log = ON
long_query_time = 0.2
```

**Objectif :**

Détecter de manière proactive les requêtes lentes.

---

# 4. Optimisations système (OS)

## 4.1. Stockage

* Utilisation de disques SSD ou SAS 10K minimum
* Partition dédiée pour `/var/lib/mysql`
* Partition dédiée aux logs (optionnelle mais recommandée)

### Bénéfices

* Réduction des temps d’accès disque
* Meilleure isolation des performances

---

## 4.2. Mémoire

* Swap activé mais peu sollicité
* Buffer Pool configuré à environ 60 % de la RAM

### Bénéfices

* Réduction des accès disque
* Meilleure stabilité sous charge

---

## 4.3. CPU

* Minimum 2 vCPU
* Recommandé : 4 vCPU

### Bénéfices

* Gestion fluide des traitements SQL
* Réplication plus performante

---

## 4.4. Réseau

* Faible latence entre BDD1 et BDD2
* Bande passante suffisante pour la réplication vers BDD3

### Bénéfices

* Réduction du retard de réplication
* Respect des objectifs RPO

---

# 5. Optimisations applicatives (WMS)

## 5.1. Requêtes critiques optimisées

Les optimisations ciblent principalement :

* les consultations de stock ;
* les mouvements d’inventaire ;
* les commandes client ;
* la recherche d’articles.

---

## 5.2. Bonnes pratiques SQL

### Recommandées

* Utilisation de requêtes paramétrées
* Sélection explicite des colonnes nécessaires
* Utilisation appropriée des index
* Pagination sur les listes volumineuses

### À éviter

* `SELECT *`
* Jointures inutiles
* Sous-requêtes complexes non optimisées
* Transactions excessivement longues

---

# 6. Optimisations de la réplication

## 6.1. Mode de réplication

* Réplication **asynchrone MariaDB**
* Utilisation des binlogs pour garantir le RPO

### Avantages

* Faible impact sur le serveur maître
* Simplicité de mise en œuvre

---

## 6.2. Paramètres recommandés

```ini id="cvh2r0"
slave_parallel_workers = 4
slave_parallel_type = LOGICAL_CLOCK
```

---

## 6.3. Bénéfices

* Réplication plus rapide
* Réduction de `Seconds_Behind_Master`
* Meilleure absorption des pics de charge
* Résilience accrue

---

# 7. Optimisations de maintenance

## 7.1. Rotation des logs

Mise en place d’une rotation automatique :

* binlogs MariaDB ;
* logs MariaDB ;
* logs HAProxy ;
* logs de sauvegarde.

### Objectifs

* éviter la saturation disque ;
* conserver un historique exploitable.

---

## 7.2. Contrôles hebdomadaires

* Analyse des requêtes lentes
* Vérification de la fragmentation des index
* Contrôle de la croissance des tables
* Vérification du retard de réplication

---

## 7.3. Nettoyage régulier

* Purge des anciens binlogs
* Suppression des sauvegardes de plus de 14 jours
* Nettoyage des fichiers temporaires

### Bénéfices

* Réduction de la consommation disque
* Maintien des performances

---

# 8. Tests de performance

## 8.1. Tests réalisés

### Tests de charge

* INSERT
* UPDATE
* SELECT

### Tests de réplication

* Vérification du retard de réplication
* Validation du RPO

### Tests de latence

* Mesure du temps moyen de réponse SQL

---

## 8.2. Résultats obtenus

| Test                  | Résultat |
| --------------------- | -------- |
| Latence SQL moyenne   | < 50 ms  |
| Retard de réplication | < 5 s    |
| Disponibilité         | Conforme |
| Temps de réponse WMS  | Stable   |

### Conclusion des tests

* Temps de réponse stable
* Réplication fluide
* Aucun goulot d’étranglement identifié

---

# 9. Recommandations d’amélioration continue

* Revue trimestrielle des index
* Analyse mensuelle des slow queries
* Tests réguliers de montée en charge
* Réévaluation périodique des paramètres InnoDB
* Vérification régulière des KPI de supervision

---

# 10. Conclusion

Les optimisations mises en place permettent :

* une base WMS performante ;
* une réplication stable ;
* une latence faible ;
* une architecture scalable ;
* une maintenance facilitée ;
* une meilleure résilience.

Ce document constitue la référence pour l’optimisation continue de la base WMS de NTL et complète les documents de supervision, d’exploitation et de PRA.
