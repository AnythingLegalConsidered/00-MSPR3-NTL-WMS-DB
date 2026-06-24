# Plan de Migration de l’ancienne base WMS vers la nouvelle architecture – NTL

Ce document décrit la procédure complète permettant de migrer l’ancienne base WMS (serveur historique) vers la nouvelle architecture MariaDB haute disponibilité (**BDD1 → BDD2 → BDD3**).

Il garantit une migration sécurisée, reproductible et conforme aux exigences RTO/RPO de NTL.

---

# 1. Objectifs de la migration

* Remplacer l’ancienne base WMS par la nouvelle base normalisée (MCD / MLD / DDL).
* Assurer une migration **sans perte de données**.
* Minimiser l’interruption de service (**objectif : < 30 minutes**).
* Préparer la réplication vers BDD2 et BDD3.
* Garantir un rollback possible en cas d’incident.

---

# 2. Architecture cible

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

---

# 3. Pré-requis

## 3.1. Pré-requis techniques

* Nouvelle base créée via `ddl_wms.sql`
* Accès SSH aux serveurs
* Accès MariaDB administrateur sur l’ancienne et la nouvelle base
* Espace disque suffisant pour les exports
* HAProxy configuré mais pointant encore vers l’ancienne base

## 3.2. Pré-requis fonctionnels

* Fenêtre de maintenance validée par la direction
* Arrêt temporaire des opérations WMS si nécessaire
* Communication préalable aux équipes logistiques
* Validation du plan de retour arrière

---

# 4. Étapes de migration

## 4.1. Étape 1 — Analyse de l’ancienne base

### Objectifs

1. Identifier les tables existantes
2. Vérifier la cohérence des données
3. Vérifier les types, formats et contraintes
4. Réaliser le mapping vers le nouveau modèle

### Exemple de mapping

| Ancienne table | Nouvelle table |
| -------------- | -------------- |
| articles       | article        |
| stock          | stock          |
| emplacement    | localisation   |
| mouvements     | mouvement      |
| clients        | client         |
| commandes      | commande       |

### Livrable attendu

* Inventaire des tables
* Correspondance ancien ↔ nouveau modèle
* Liste des adaptations nécessaires

---

## 4.2. Étape 2 — Export de l’ancienne base

### Commande recommandée

```bash
mysqldump \
--single-transaction \
--routines \
--events \
--triggers \
-u root -p ancienne_base > ancienne_base_dump.sql
```

### Vérifications

* Taille du dump cohérente
* Absence d’erreurs durant l’export
* Encodage UTF-8
* Présence des procédures stockées et triggers

### Contrôle

```bash
ls -lh ancienne_base_dump.sql
```

---

## 4.3. Étape 3 — Transformation des données

Selon les différences entre l’ancien modèle et le nouveau :

* renommage de colonnes ;
* normalisation des types ;
* ajout des colonnes obligatoires ;
* suppression des données incohérentes ;
* harmonisation des formats de dates.

### Exemple

```sql
UPDATE mouvement
SET type = 'ENTREE'
WHERE type = 'IN';

UPDATE mouvement
SET type = 'SORTIE'
WHERE type = 'OUT';
```

### Contrôles

* vérification des contraintes métier ;
* vérification des clés étrangères ;
* vérification des doublons.

---

## 4.4. Étape 4 — Import dans la nouvelle base (BDD1)

### Commande

```bash
mysql -u root -p wms_ntl < ancienne_base_dump.sql
```

### Vérifications

* nombre de lignes par table ;
* intégrité référentielle ;
* absence d’erreurs dans les logs MariaDB.

### Contrôle des logs

```bash
tail -f /var/log/mysql/error.log
```

---

## 4.5. Étape 5 — Synchronisation finale (delta)

Juste avant la bascule :

1. Arrêter temporairement WMS-APP
2. Identifier les données modifiées depuis le dernier export
3. Exporter uniquement ces modifications
4. Importer le delta dans BDD1

### Exemple

```sql
SELECT *
FROM mouvements
WHERE date > NOW() - INTERVAL 1 DAY;
```

### Objectif

Limiter au maximum la perte potentielle de données pendant la migration.

---

## 4.6. Étape 6 — Activation de la réplication

### Configuration sur BDD2 et BDD3

```sql
CHANGE MASTER TO
MASTER_HOST='BDD1',
MASTER_USER='replicator',
MASTER_PASSWORD='xxx',
MASTER_LOG_FILE='binlog.000123',
MASTER_LOG_POS=456789;

START SLAVE;
```

### Vérification

```sql
SHOW SLAVE STATUS\G;
```

### Contrôles attendus

```text
Slave_IO_Running  : Yes
Slave_SQL_Running : Yes
Seconds_Behind_Master : 0
```

---

## 4.7. Étape 7 — Bascule de l’application WMS

### Actions

#### 1. Modifier HAProxy

Pointer le backend actif vers **BDD1**.

#### 2. Recharger HAProxy

```bash
systemctl reload haproxy
```

#### 3. Redémarrer WMS-APP

Selon la procédure d’exploitation.

#### 4. Réaliser les tests fonctionnels

* connexion utilisateur ;
* création d’un mouvement ;
* mise à jour du stock ;
* consultation des commandes ;
* recherche d’article.

---

# 5. Plan de rollback (retour arrière)

## Conditions de déclenchement

* erreurs critiques détectées ;
* incohérences de données ;
* réplication non fonctionnelle ;
* application WMS inutilisable.

## Procédure

### 1. Arrêter WMS-APP

### 2. Rebasculer HAProxy

Retour vers l’ancienne base.

### 3. Restaurer l’environnement historique

Si nécessaire.

### 4. Identifier la cause

* logs MariaDB ;
* logs applicatifs ;
* logs HAProxy.

### 5. Replanifier la migration

Après correction.

### Garantie

Le rollback reste possible tant que la bascule définitive n’a pas été validée.

---

# 6. Tests post-migration

## 6.1. Tests techniques

* [ ] Réplication BDD1 → BDD2 opérationnelle
* [ ] Réplication BDD1 → BDD3 opérationnelle
* [ ] Clés étrangères valides
* [ ] Index fonctionnels
* [ ] Logs sans erreur
* [ ] Sauvegardes opérationnelles

---

## 6.2. Tests fonctionnels

* [ ] Création de mouvement
* [ ] Mise à jour de stock
* [ ] Consultation des commandes
* [ ] Recherche d’article
* [ ] Connexion utilisateur
* [ ] Génération des rapports

---

# 7. Validation finale

La migration est considérée comme validée si :

* le WMS fonctionne normalement ;
* aucune perte de données n’est constatée ;
* la réplication est opérationnelle ;
* les sauvegardes sont fonctionnelles ;
* la supervision est active ;
* aucun incident critique n’est présent dans les logs.

---

# 8. Critères de succès

| Critère           | Résultat attendu |
| ----------------- | ---------------- |
| Disponibilité WMS | OK               |
| Données migrées   | 100 %            |
| Réplication       | Fonctionnelle    |
| Sauvegardes       | OK               |
| Monitoring        | Actif            |
| Rollback testé    | Oui              |

---

# 9. Conclusion

Ce plan de migration garantit :

* une transition sécurisée vers la nouvelle base WMS ;
* un risque minimal grâce à la procédure de rollback ;
* une architecture moderne, scalable et supervisée ;
* une continuité de service conforme aux exigences métier de NTL ;
* une préparation complète à la haute disponibilité et au PRA.

Il constitue la procédure officielle de migration utilisée par l’équipe IT pour le passage vers la nouvelle architecture MariaDB.
