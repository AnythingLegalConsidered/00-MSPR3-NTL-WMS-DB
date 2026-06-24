# Runbook d’exploitation – Base WMS NTL

Ce runbook décrit l’ensemble des procédures opérationnelles permettant d’exploiter, superviser et maintenir la base de données WMS de NTL en conditions normales et dégradées.

Il couvre :

* les procédures Start / Stop ;
* les contrôles de santé ;
* les checklists quotidiennes et hebdomadaires ;
* la gestion des incidents ;
* la matrice d’escalade ;
* les KPI de suivi.

---

# 1. Architecture opérationnelle

L’infrastructure repose sur trois serveurs MariaDB :

* **BDD1 – Master (production)**
* **BDD2 – Slave HA (haute disponibilité locale)**
* **BDD3 – Slave PRA (site distant)**

L’application WMS accède à la base via **HAProxy**, qui bascule automatiquement ou manuellement selon l’état des serveurs.

---

# 2. Procédures Start / Stop

## 2.1. Démarrage MariaDB

### Sur n’importe quel serveur (BDD1 / BDD2 / BDD3)

```bash
systemctl start mariadb
systemctl status mariadb
```

### Vérification

```bash
mysql -u root -p -e "SELECT NOW();"
```

---

## 2.2. Arrêt MariaDB

```bash
systemctl stop mariadb
systemctl status mariadb
```

---

## 2.3. Redémarrage MariaDB

```bash
systemctl restart mariadb
```

---

## 2.4. Démarrage / arrêt HAProxy

### Recharger HAProxy

```bash
systemctl reload haproxy
```

### Vérifier l’état

```bash
systemctl status haproxy
```

---

# 3. Contrôles de santé (Health Checks)

## 3.1. Vérification du service MariaDB

```bash
systemctl is-active mariadb
```

## 3.2. Vérification de la réplication (BDD2 / BDD3)

```sql
SHOW SLAVE STATUS\G;
```

### Points critiques

* `Slave_IO_Running = Yes`
* `Slave_SQL_Running = Yes`
* `Seconds_Behind_Master = 0`

## 3.3. Vérification de l’espace disque

```bash
df -h
```

## 3.4. Vérification des connexions actives

```sql
SHOW PROCESSLIST;
```

## 3.5. Vérification HAProxy

```bash
echo "show stat" | socat stdio /run/haproxy/admin.sock
```

---

# 4. Checklist quotidienne

## 4.1. Base de données

* [ ] MariaDB actif sur BDD1
* [ ] Réplication OK sur BDD2
* [ ] Réplication OK sur BDD3
* [ ] `Seconds_Behind_Master < 5`
* [ ] Pas d’erreurs dans `/var/log/mysql/error.log`

## 4.2. Système

* [ ] Espace disque > 20 %
* [ ] Charge CPU normale
* [ ] RAM disponible suffisante

## 4.3. Sauvegardes

* [ ] Sauvegarde de la nuit présente sur NAS
* [ ] Taille cohérente
* [ ] Log de sauvegarde = SUCCESS

## 4.4. HAProxy

* [ ] Backend actif = BDD1
* [ ] Aucun backend en erreur

---

# 5. Checklist hebdomadaire

* [ ] Test de connexion sur BDD2 et BDD3
* [ ] Vérification des index fragmentés
* [ ] Analyse des requêtes lentes (`slow_query_log`)
* [ ] Vérification de la croissance des binlogs
* [ ] Vérification de la rotation des sauvegardes
* [ ] Test de restauration sur base de test (mini-restore)

---

# 6. Procédure de gestion des incidents

## 6.1. Incident : MariaDB ne répond plus sur BDD1

### Étape 1 : Vérifier le service

```bash
systemctl status mariadb
```

### Étape 2 : Redémarrer le service

```bash
systemctl restart mariadb
```

### Étape 3 : Si échec

* Modifier HAProxy
* Basculer vers BDD2
* Recharger HAProxy

### Étape 4

Informer le responsable IT.

---

## 6.2. Incident : réplication cassée sur BDD2 ou BDD3

### Vérifier l’erreur

```sql
SHOW SLAVE STATUS\G;
```

### Tentative de correction

```sql
STOP SLAVE;
START SLAVE;
```

### Si toujours en erreur

* Générer un dump depuis BDD1
* Restaurer le dump
* Reconfigurer la réplication

---

## 6.3. Incident : perte totale de BDD1

### Vérifier BDD2

Si BDD2 est fonctionnelle :

* Basculer HAProxy vers BDD2

### Si BDD2 est également indisponible

Activer le PRA :

```sql
STOP SLAVE;
RESET SLAVE ALL;
SET GLOBAL read_only = OFF;
```

Puis :

* Configurer HAProxy vers BDD3
* Valider le fonctionnement du WMS

---

## 6.4. Incident : corruption de données

1. Isoler la base :

```sql
SET GLOBAL read_only = ON;
```

2. Restaurer la sauvegarde complète.
3. Rejouer les binlogs.
4. Vérifier l’intégrité.
5. Reconnecter la réplication.

---

# 7. Matrice d’escalade

| Niveau | Responsable             | Délai max | Actions                                    |
| ------ | ----------------------- | --------- | ------------------------------------------ |
| **N1** | Support WMS             | 15 min    | Vérifications simples, redémarrage service |
| **N2** | Administrateur Systèmes | 30 min    | HAProxy, VM, réseau                        |
| **N3** | DBA                     | 1 h       | Réplication, restauration, PRA             |
| **N4** | Responsable IT          | 2 h       | Décision PRA, communication direction      |

---

# 8. KPI (Indicateurs de performance)

| KPI                   | Objectif     | Seuil critique |
| --------------------- | ------------ | -------------- |
| Latence SQL           | < 50 ms      | > 200 ms       |
| Seconds_Behind_Master | 0 à 5 s      | > 30 s         |
| Succès sauvegardes    | 100 %        | 1 échec        |
| Espace disque         | > 20 % libre | < 10 %         |
| Erreurs MariaDB       | 0            | > 5 / jour     |

---

# 9. Documentation associée

* `architecture-technique.md`
* `mcd.png`
* `mld.md`
* `ddl_wms.sql`
* `pra.md`
* `supervision.md`
* `sauvegardes.md`

---

# 10. Conclusion

Ce runbook fournit l’ensemble des procédures nécessaires pour garantir :

* la disponibilité du WMS ;
* la stabilité de la base de données ;
* la maîtrise des incidents ;
* la conformité aux exigences RTO/RPO ;
* la capacité de bascule HA et PRA.

Il constitue la référence opérationnelle pour l’équipe IT de NTL.
