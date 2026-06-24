# Analyse des logs – Base WMS NTL

Ce document décrit les sources de logs critiques, les patterns à surveiller, les méthodes d’analyse et les procédures d’intervention en cas d’anomalie.

Il constitue un livrable obligatoire pour la MSPR et un outil essentiel pour le diagnostic des incidents.

---

# 1. Sources de logs

Les logs à analyser se répartissent en cinq catégories :

| Composant            | Fichier / Source           | Contenu                                       |
| -------------------- | -------------------------- | --------------------------------------------- |
| MariaDB              | `/var/log/mysql/error.log` | Erreurs SQL, crashs, corruption               |
| MariaDB Slow Queries | `/var/log/mysql/slow.log`  | Requêtes lentes                               |
| Binlogs              | `/var/lib/mysql/binlog.*`  | Transactions pour réplication et restauration |
| HAProxy              | `/var/log/haproxy.log`     | Bascule backend, erreurs de connexion         |
| Sauvegardes          | `/var/log/wms_backup.log`  | Succès et échecs des sauvegardes              |

---

# 2. Analyse des logs MariaDB

## 2.1. error.log

### Commande d’accès

```bash
tail -n 200 /var/log/mysql/error.log
```

### Patterns critiques à surveiller

| Pattern                          | Signification           | Gravité  |
| -------------------------------- | ----------------------- | -------- |
| `InnoDB: corruption`             | Corruption de tables    | Critique |
| `InnoDB: page checksum mismatch` | Données incohérentes    | Critique |
| `Can't open file`                | Table inaccessible      | Élevée   |
| `Aborted connection`             | Connexions interrompues | Moyenne  |
| `Too many connections`           | Saturation du serveur   | Critique |
| `Slave I/O: error`               | Réplication cassée      | Critique |

### Procédure d’analyse

#### 1. Identifier l’erreur exacte

Analyser le message retourné dans le journal.

#### 2. Vérifier l’état du service

```bash
systemctl status mariadb
```

#### 3. Vérifier l’espace disque

```bash
df -h
```

#### 4. Vérifier la réplication (BDD2 / BDD3)

```sql
SHOW SLAVE STATUS\G;
```

#### 5. Si corruption détectée

* Isoler la base ;
* Passer en mode lecture seule ;
* Restaurer depuis sauvegarde.

---

## 2.2. slow.log

### Activation recommandée

```ini
slow_query_log = ON
long_query_time = 0.2
```

### Commande d’analyse

```bash
mysqldumpslow /var/log/mysql/slow.log | head
```

### Patterns à surveiller

* requêtes sans index ;
* jointures sur tables volumineuses ;
* scans complets (`FULL TABLE SCAN`) ;
* requêtes supérieures à 200 ms.

### Actions

* ajouter des index ;
* optimiser les requêtes SQL ;
* vérifier la charge CPU et RAM.

---

# 3. Analyse des binlogs

Les binlogs permettent :

* la réplication ;
* la restauration Point-In-Time Recovery (PITR) ;
* l’analyse détaillée des transactions.

### Lister les binlogs

```bash
mysql -e "SHOW BINARY LOGS;"
```

### Lire un binlog

```bash
mysqlbinlog /var/lib/mysql/binlog.000123 | less
```

### Patterns à surveiller

* transactions très volumineuses ;
* suppressions massives (`DELETE`) ;
* mises à jour sans clause `WHERE` ;
* transactions répétitives (boucle applicative).

### Actions

* vérifier l’application WMS ;
* contrôler la réplication ;
* restaurer si nécessaire.

---

# 4. Analyse des logs HAProxy

## Fichier surveillé

```text
/var/log/haproxy.log
```

### Patterns critiques

| Pattern                | Signification       |
| ---------------------- | ------------------- |
| `Server BDD1 DOWN`     | Master indisponible |
| `Server BDD2 DOWN`     | HA indisponible     |
| `Server BDD3 DOWN`     | PRA indisponible    |
| `Connection timed out` | Problème réseau     |
| `Retrying connection`  | Backend instable    |

### Commande utile

```bash
tail -f /var/log/haproxy.log
```

### Actions

* vérifier le backend MariaDB ;
* vérifier le réseau ;
* recharger HAProxy ;
* déclencher une bascule HA ou PRA si nécessaire.

---

# 5. Analyse des logs de sauvegarde

## Fichier surveillé

```text
/var/log/wms_backup.log
```

### Patterns critiques

* `ERROR`
* `Backup failed`
* `No space left on device`
* `mysqldump: Got error`

### Vérification de la sauvegarde

```bash
ls -lh /backups/
```

### Vérification de l’intégrité

```bash
mysql --dry-run < dump.sql
```

### Actions

* relancer la sauvegarde ;
* libérer de l’espace disque ;
* vérifier les droits sur le NAS ;
* notifier le responsable IT.

---

# 6. Procédures d’analyse en cas d’alerte

## 6.1. Alerte : réplication cassée

### Symptômes

* `Slave_IO_Running = No`
* `Slave_SQL_Running = No`
* augmentation de `Seconds_Behind_Master`

### Actions immédiates

```sql
STOP SLAVE;
START SLAVE;
```

### Si le problème persiste

* générer un nouveau dump depuis BDD1 ;
* restaurer le dump ;
* reconfigurer la réplication.

---

## 6.2. Alerte : latence SQL élevée

### Symptômes

* nombreuses slow queries ;
* CPU élevé ;
* requêtes bloquées.

### Actions

* analyser `slow.log` ;
* vérifier les index ;
* vérifier la charge système ;
* optimiser les requêtes concernées.

---

## 6.3. Alerte : espace disque faible

### Symptômes

* moins de 15 % d’espace libre ;
* binlogs volumineux ;
* sauvegardes non purgées.

### Actions

#### Purger les binlogs

```sql
RESET MASTER;
```

#### Puis

* supprimer les anciennes sauvegardes ;
* étendre le stockage si nécessaire.

---

## 6.4. Alerte : sauvegarde KO

### Actions

1. Lire le journal :

```bash
cat /var/log/wms_backup.log
```

2. Vérifier l’espace disque.
3. Vérifier les droits NAS.
4. Relancer la sauvegarde.
5. Contrôler l’intégrité du nouveau dump.

---

# 7. Tableau récapitulatif des patterns critiques

| Pattern              | Source      | Gravité  | Action                  |
| -------------------- | ----------- | -------- | ----------------------- |
| InnoDB corruption    | error.log   | Critique | Restauration            |
| Slave_IO_Running=No  | Réplication | Critique | Réparer la réplication  |
| Too many connections | error.log   | Critique | Analyse application WMS |
| Slow queries         | slow.log    | Élevée   | Optimisation SQL        |
| Backend DOWN         | HAProxy     | Critique | Bascule HA/PRA          |
| Backup failed        | backup.log  | Critique | Relancer et corriger    |

---

# 8. Conclusion

L’analyse des logs est essentielle pour :

* détecter les incidents avant qu’ils n’impactent le WMS ;
* diagnostiquer rapidement les pannes ;
* garantir la cohérence des données ;
* respecter les objectifs RTO/RPO ;
* sécuriser les opérations critiques de NTL.

Ce document constitue la référence opérationnelle pour toute investigation technique liée à la base de données WMS et complète les procédures décrites dans le Runbook, la Supervision et le PRA.
