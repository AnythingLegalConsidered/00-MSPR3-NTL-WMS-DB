# Plan de Reprise d’Activité (PRA) – Base WMS NTL

## 1. Objectifs du PRA

Le Plan de Reprise d’Activité (PRA) vise à garantir la continuité du système de gestion d’entrepôt (WMS) en cas d’incident majeur affectant la base de données principale.

### Objectifs définis par la direction NTL

- **RTO (Recovery Time Objective) : 1 heure**
- **RPO (Recovery Point Objective) : 15 minutes**

Le PRA repose sur une architecture multi-sites :

- **BDD1 – Master (production)**
- **BDD2 – Slave HA (haute disponibilité locale)**
- **BDD3 – Slave PRA (site distant)**

---

## 2. Architecture PRA

```text
WMS-APP
   |
   v
HAProxy
   +---------+---------+
   |                   |
   v                   v
BDD1 (Master)      BDD2 (Slave HA)
   |
   v
BDD3 (Slave PRA)
```

### Description

- **BDD1** : base principale, reçoit toutes les écritures.
- **BDD2** : réplication locale, utilisée en cas de panne du master.
- **BDD3** : réplication distante, utilisée en cas de perte du site siège.

---

## 3. Scénarios de sinistre couverts

### 3.1. Panne du service MariaDB sur BDD1

- **Cause :** crash du service, corruption mineure, surcharge.
- **Impact :** WMS indisponible.
- **Solution :** bascule HAProxy vers **BDD2**.

### 3.2. Panne de la VM BDD1

- **Cause :** crash hyperviseur, perte disque, freeze.
- **Impact :** perte totale du master.
- **Solution :** bascule HAProxy vers **BDD2** avec promotion éventuelle.

### 3.3. Perte du site siège (Lille)

- **Cause :** coupure électrique, incendie, panne réseau majeure.
- **Impact :** BDD1 et BDD2 indisponibles.
- **Solution :** bascule vers **BDD3 (PRA)**.

### 3.4. Corruption logique de la base

- **Cause :** erreur humaine, bug applicatif, données incohérentes.
- **Solution :** restauration depuis sauvegarde puis relecture des binlogs.

---

## 4. Procédure de bascule HA (BDD1 → BDD2)

### 4.1. Conditions de déclenchement

- `Slave_IO_Running = Yes`
- `Slave_SQL_Running = Yes`
- `Seconds_Behind_Master = 0`

### 4.2. Étapes

#### 1. Vérifier l’état de BDD2

```sql
SHOW SLAVE STATUS\G;
```

#### 2. Modifier HAProxy pour pointer vers BDD2

- Commenter le backend BDD1
- Activer le backend BDD2

#### 3. Recharger HAProxy

```bash
systemctl reload haproxy
```

#### 4. Vérifier l’accès au WMS

- Test de connexion
- Test de lecture
- Test d’écriture

### 4.3. RTO estimé

**5 à 10 minutes**

---

## 5. Procédure de bascule PRA (BDD1/BDD2 → BDD3)

### 5.1. Conditions de déclenchement

- Perte totale du site siège
- BDD1 et BDD2 inaccessibles
- BDD3 en réplication fonctionnelle avant incident

### 5.2. Étapes

#### 1. Arrêter la réplication sur BDD3

```sql
STOP SLAVE;
RESET SLAVE ALL;
```

#### 2. Promouvoir BDD3 en master

```sql
SET GLOBAL read_only = OFF;
```

#### 3. Modifier HAProxy

- Activer le backend PRA (BDD3)
- Désactiver BDD1 et BDD2

#### 4. Recharger HAProxy

```bash
systemctl reload haproxy
```

#### 5. Effectuer les tests fonctionnels WMS

- Connexion utilisateur
- Création de mouvement
- Mise à jour de stock

### 5.3. RTO estimé

**20 à 40 minutes**

---

## 6. Retour à la normale (Post-sinistre)

### 6.1. Si BDD1 revient en ligne

1. Recréer une réplication propre depuis BDD3 vers BDD1.
2. Effectuer un dump de BDD3.
3. Importer le dump sur BDD1.
4. Reconfigurer la commande `CHANGE MASTER TO`.
5. Resynchroniser BDD2 depuis BDD1.
6. Rebasculer HAProxy vers BDD1.
7. Remettre BDD3 en mode slave.

### 6.2. RTO du retour à la normale

**1 à 3 heures** (hors reconstruction matérielle).

---

## 7. Sauvegardes et restauration

### 7.1. Sauvegardes utilisées dans le PRA

- Sauvegarde complète quotidienne (`mysqldump` ou `mariabackup`)
- Conservation des binlogs pendant 48 heures
- Sauvegarde de la configuration MariaDB
- Sauvegarde de la configuration HAProxy

### 7.2. Procédure de restauration

1. Restaurer le dump complet.
2. Relire les binlogs jusqu’au point de coupure.
3. Vérifier l’intégrité des données.
4. Reconnecter la réplication.

---

## 8. Tests PRA

### 8.1. Tests obligatoires

- Test de bascule HA (BDD1 → BDD2)
- Test de bascule PRA (BDD1/BDD2 → BDD3)
- Test de restauration depuis sauvegarde
- Test de relecture des binlogs

### 8.2. Fréquence

| Test | Fréquence |
|--------|-----------|
| Bascule HA | Trimestrielle |
| Bascule PRA | Semestrielle |
| Restauration | Mensuelle |

### 8.3. Indicateurs de succès

- RTO respecté
- RPO respecté
- Aucune perte de données non prévue
- WMS opérationnel après bascule

---

## 9. Responsabilités

| Rôle | Responsabilités |
|--------|----------------|
| Administrateur Systèmes | Bascule HAProxy, gestion des VM |
| DBA | Promotion des slaves, restauration, réplication |
| Responsable IT | Validation du déclenchement du PRA |
| Support WMS | Tests applicatifs |

---

## 10. Documentation associée

- Dossier d’architecture technique WMS
- Procédure d’exploitation MariaDB
- Documentation HAProxy
- Politique de sauvegarde NTL
- Documentation de supervision et monitoring

---

## 11. Conclusion

Le PRA mis en place pour NTL garantit :

- Une continuité de service du WMS.
- Un **RTO ≤ 1 heure**.
- Un **RPO ≤ 15 minutes**.
- Une architecture multi-sites robuste.
- Une capacité de retour à la normale maîtrisée.

Ce PRA est adapté aux contraintes opérationnelles fortes de NTL :

- Activité de 5h30 à 18h30.
- Forte dépendance au WMS.
- Équipe IT réduite.
