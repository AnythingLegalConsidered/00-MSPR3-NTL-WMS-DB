# Supervision de la base WMS – NTL

Ce document décrit les indicateurs critiques à superviser pour garantir la disponibilité, la performance et la cohérence de la base de données WMS.

Il inclut :

* les 5 indicateurs obligatoires ;
* les seuils d’alerte ;
* les méthodes de collecte ;
* les procédures d’analyse en cas d’alerte.

La supervision repose sur **Prometheus + Grafana**, avec **mysqld_exporter** et **node_exporter**.

---

# 1. Indicateur 1 : Latence SQL

## Description

Mesure le temps moyen d’exécution des requêtes SQL.

Cet indicateur est critique pour le WMS (mouvements de stock, commandes, inventaires).

## Seuils

* **Normal :** < 50 ms
* **Alerte :** > 150 ms
* **Critique :** > 300 ms

## Collecte

* `mysqld_exporter`
* Métriques :

  * `mysql_global_status_queries`
  * `mysql_global_status_slow_queries`
* Slow Query Log activé

## Procédure d’analyse

### 1. Vérifier les requêtes lentes

```sql
SHOW GLOBAL STATUS LIKE 'Slow_queries';
```

### 2. Consulter le Slow Query Log

```bash
/var/log/mysql/slow.log
```

### 3. Identifier

* les requêtes non indexées ;
* les scans complets de tables ;
* les jointures coûteuses.

### 4. Vérifier les ressources système

* CPU
* RAM
* I/O disque

### 5. Corriger

* optimisation SQL ;
* ajout d’index ;
* optimisation du schéma.

---

# 2. Indicateur 2 : Connexions actives

## Description

Nombre de connexions simultanées au serveur MariaDB.

## Seuils

* **Normal :** < 50 connexions
* **Alerte :** > 100 connexions
* **Critique :** > 150 connexions

## Collecte

```text
mysql_global_status_threads_connected
```

## Procédure d’analyse

### 1. Lister les connexions

```sql
SHOW PROCESSLIST;
```

### 2. Identifier

* connexions bloquées ;
* transactions longues ;
* sessions zombies.

### 3. Vérifier l’application WMS

* boucles applicatives ;
* timeouts ;
* fuites de connexions.

### 4. Actions correctives

* fermeture des sessions bloquées ;
* redémarrage contrôlé des services concernés.

---

# 3. Indicateur 3 : État de la réplication

## Description

Surveillance de la réplication :

```text
BDD1 (Master)
      │
      ├──► BDD2 (Slave HA)
      │
      └──► BDD3 (Slave PRA)
```

## Seuils

* **Normal :** `Seconds_Behind_Master = 0 à 5 s`
* **Alerte :** > 15 s
* **Critique :** > 30 s

Au-delà de 30 secondes, le **RPO de 15 minutes** peut être compromis.

## Collecte

```text
mysql_slave_status_seconds_behind_master
```

## Procédure d’analyse

### 1. Vérifier la réplication

```sql
SHOW SLAVE STATUS\G;
```

### 2. Vérifier

* `Slave_IO_Running = Yes`
* `Slave_SQL_Running = Yes`

### 3. Causes possibles

* surcharge du master ;
* saturation réseau ;
* transaction volumineuse ;
* blocage disque.

### 4. Actions

* redémarrage de la réplication ;
* vérification des binlogs ;
* analyse de la charge système.

---

# 4. Indicateur 4 : Espace disque

## Description

Surveillance du stockage :

* données MariaDB ;
* binlogs ;
* sauvegardes ;
* fichiers temporaires.

## Seuils

* **Normal :** > 20 % libre
* **Alerte :** < 15 %
* **Critique :** < 10 %

Un espace insuffisant peut provoquer l’arrêt de MariaDB.

## Collecte

```text
node_filesystem_avail_bytes
```

## Procédure d’analyse

### 1. Vérifier l’espace disque

```bash
df -h
```

### 2. Identifier

* binlogs trop volumineux ;
* sauvegardes non purgées ;
* fichiers temporaires excessifs.

### 3. Actions

* rotation des binlogs ;
* suppression des anciennes sauvegardes ;
* extension du stockage.

---

# 5. Indicateur 5 : Succès des sauvegardes

## Description

Vérifie que les sauvegardes quotidiennes sont réalisées correctement.

## Seuils

* **Normal :** 100 % des sauvegardes réussies
* **Alerte :** 1 échec
* **Critique :** plus d’un échec consécutif

## Collecte

* journal du script de sauvegarde ;
* fichier d’état :

  * `backup_status=OK`
  * `backup_status=KO`
* contrôle de la taille du dump.

## Procédure d’analyse

### 1. Vérifier les logs

```bash
cat /var/log/wms_backup.log
```

### 2. Vérifier les fichiers générés

```bash
ls -lh /backups/
```

### 3. Vérifier l’intégrité du dump

```bash
mysql --dry-run < dump.sql
```

### 4. Causes possibles

* manque d’espace disque ;
* erreur mysqldump ;
* problème réseau ;
* indisponibilité du NAS.

### 5. Actions

* relancer la sauvegarde ;
* corriger la cause ;
* notifier le responsable IT.

---

# 6. Dashboard Grafana recommandé

## Panneaux à inclure

### Base de données

* Latence SQL (graphique)
* Connexions actives (gauge)
* Seconds Behind Master (graphique)
* Erreurs MariaDB

### Infrastructure

* Espace disque (barres)
* Charge CPU
* Utilisation RAM
* Activité disque

### Sauvegardes

* Statut sauvegarde (OK / KO)
* Taille du dernier dump
* Historique des sauvegardes

---

## Alertes Grafana

| Indicateur    | Warning  | Critical          |
| ------------- | -------- | ----------------- |
| Latence SQL   | > 150 ms | > 300 ms          |
| Réplication   | > 15 s   | > 30 s            |
| Espace disque | < 15 %   | < 10 %            |
| Sauvegarde    | KO       | Critique immédiat |

---

# 7. Conclusion

La supervision mise en place permet :

* d’anticiper les incidents ;
* de garantir le respect des objectifs RTO/RPO ;
* de surveiller la santé du cluster MariaDB ;
* de sécuriser les opérations critiques du WMS ;
* de faciliter la prise de décision lors d’un incident.

Elle constitue un pilier essentiel de l’exploitation courante et du Plan de Reprise d’Activité (PRA) de NTL.
