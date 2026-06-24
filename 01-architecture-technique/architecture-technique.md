# Document d’architecture technique – Base WMS NTL

## 1. Périmètre

Ce document complète le MCD déjà réalisé (fourni au format image dans le dépôt) et couvre :

- justification du SGBD,
- schémas d’architectures,
- hébergement et hardware,
- index et optimisations,
- politiques d’accès,
- politiques de sauvegardes.

Le MCD existant définit les entités principales : ARTICLE, STOCK, LOCALISATION, SITE, COMMANDE, CLIENT, MOUVEMENT, UTILISATEUR, ainsi que leurs relations (stock, mouvements, commandes, clients, utilisateurs).

---

## 2. Justification du SGBD

### 2.1 SGBD retenu

SGBD choisi : **MariaDB**

**Motivations principales :**

- Compatibilité avec l’existant (WMS actuel sous MySQL/MariaDB).
- Réplication native simple (binlogs, multi-slave).
- Haute disponibilité possible via HAProxy.
- Performances adaptées aux charges transactionnelles.
- Coût nul (open-source).
- Écosystème riche (mariabackup, exporters Prometheus, outils de monitoring).

**Alternatives écartées :**

- PostgreSQL : migration applicative lourde.
- MySQL Enterprise : coût de licence non adapté à une PME.

---

## 3. Schémas d’architecture

### 3.1 Architecture logique

L’architecture retenue repose sur une base principale (master) et deux bases répliquées (slaves) :

- **BDD1 – Master** : base de production principale (site siège).
- **BDD2 – Slave HA** : réplication locale pour la haute disponibilité.
- **BDD3 – Slave PRA** : réplication distante pour le Plan de Reprise d’Activité.
- **HAProxy** : point d’entrée unique pour l’application WMS, avec bascule possible entre BDD1, BDD2 et BDD3.

```text
          WMS-APP
             |
             v
          HAProxy
             |
   +---------+---------+
   |                   |
   v                   v
BDD1 (Master)      BDD2 (Slave HA)
   |
   v
BDD3 (Slave PRA)
### 3.2 Flux principaux

- **Flux applicatif :**  
  WMS-APP → HAProxy → BDD1 (lecture/écriture).

- **Réplication :**  
  BDD1 → BDD2 (HA locale)  
  BDD1 → BDD3 (PRA distante)

- **Sauvegardes :**  
  Sauvegardes réalisées depuis BDD1 (et/ou BDD3) vers NAS.

---

## 4. Hébergement et hardware

### 4.1 Contexte d’hébergement

- VMs Linux (Ubuntu Server) hébergées sur l’hyperviseur du siège.
- BDD3 hébergée sur une VM distincte (PRA).
- NAS utilisé pour les sauvegardes.

### 4.2 Spécifications minimales recommandées

**Pour chaque VM BDD :**

- CPU : 2–4 vCPU  
- RAM : 8–16 Go  
- Disque : SSD/SAS 10K, volumes séparés pour data/logs  
- Réseau : 1 Gbit/s minimum

**NAS :**

- Rétention 14 jours minimum  
- Accès restreint aux serveurs BDD

---

## 5. Index et optimisations

### 5.1 Index recommandés

- **ARTICLE**
  - Index unique sur `sku` ou `nom`.

- **STOCK**
  - Index composite `(id_article, id_localisation)`.

- **LOCALISATION**
  - Index `(id_site, code)`.

- **COMMANDE**
  - Index `date_commande`,
  - Index `(id_client, date_commande)`.

- **MOUVEMENT**
  - Index `date`,
  - Index `(id_article, date)`,
  - Index `type`.

### 5.2 Paramètres MariaDB

- `innodb_buffer_pool_size` ≈ 60 % RAM  
- `innodb_log_file_size` adapté à la volumétrie  
- `innodb_flush_log_at_trx_commit = 2`  
- `sync_binlog = 1`  
- `slow_query_log = ON` + seuil 200–500 ms  

---

## 6. Politiques d’accès

### 6.1 Comptes et rôles

- **appuser**  
  - SELECT, INSERT, UPDATE, DELETE sur schéma WMS  
  - Pas de DDL  
  - Limité par IP

- **replicator**  
  - REPLICATION SLAVE  
  - Utilisé par BDD2 et BDD3

- **dba**  
  - ALL PRIVILEGES sur WMS  
  - Accès restreint (SSH + MFA)

- **backup**  
  - SELECT, LOCK TABLES, RELOAD

### 6.2 Principes de sécurité

- Aucun `GRANT ALL ON *.*` pour les comptes applicatifs.  
- root MySQL limité à localhost.  
- SSH par clé uniquement.  
- Rotation régulière des mots de passe.  
- Journalisation des connexions.

---

## 7. Politiques de sauvegardes

### 7.1 Objectifs

- RPO : 15 minutes  
- RTO : 1 heure  
- Sauvegardes automatisées et testées

### 7.2 Types de sauvegardes

- **Complète** (quotidienne)  
  - mysqldump ou mariabackup  
  - Stockée sur NAS

- **Incrémentale / transactionnelle**  
  - Conservation des binlogs 24–48 h  
  - Permet un RPO fin

- **Sauvegarde de configuration**  
  - `/etc/mysql/`  
  - Configuration HAProxy

### 7.3 Automatisation

- Scripts bash/python pour :  
  - lancer la sauvegarde  
  - rotation  
  - vérification  
  - logs + notification

- Cron :  
  - sauvegarde complète → 02h00  
  - rotation → quotidienne  
  - test de restauration → mensuel

### 7.4 Rétention et externalisation

- Rétention locale : 14 jours  
- Externalisation vers autre site ou cloud

---

## 8. Conclusion

L’architecture proposée répond aux exigences de NTL :

- Haute disponibilité  
- PRA robuste  
- Sécurité  
- Performance  
- Supervision future  
- Exploitabilité et documentation

Elle est adaptée aux contraintes métier (horaires, criticité du WMS, équipe IT réduite) et scalable pour les évolutions futures.

