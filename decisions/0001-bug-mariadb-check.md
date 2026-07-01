---
id: "0001"
titre: "Bug parser MariaDB 11.4 — CHECK rejeté en présence des FK composites"
statut: "SUPERSEDED — 2026-05-22 par ADR 0003 (pivot grossiste). Sans objet sur le modèle V2."
created: "2026-05-22"
updated: "2026-05-22"
owner: "Ianis"
impact: "DDL mouvements"
related:
  - "../01-architecture-technique/ddl/wms-ddl.md"
  - "../01-architecture-technique/mld/wms-mld.md"
  - "../01-architecture-technique/ddl/wms-schema.sql"
  - "../07-gestion-projet/journal-decisions.md"
---

# 0001 — Bug parser MariaDB 11.4 sur les CHECK de `mouvements`

> ⚠️ **SUPERSEDED par [ADR 0003](0003-postulats-cadrage-ntl.md).** Cet ADR documente une investigation menée sous l'**ancien modèle multi-tenant** (V4), où `mouvements` portait `id_depart`/`id_arrivee` et des FK composites `(id_depart, id_site)`. Le pivot grossiste (modèle V2) a **supprimé ces colonnes et ces FK composites** : `mouvement` ne référence plus qu'un seul `id_stock`. **Le bug ne se déclenche donc plus** et le DDL V2 (`wms-schema.sql`) ne contient **aucun trigger**. Conservé comme trace d'investigation technique.

## Problème en 3 lignes

MariaDB 11.4.10 refuse toute contrainte `CHECK` qui référence `id_depart` ou `id_arrivee` sur la table `mouvements`, dès lors que les FK composites `(id_depart, id_site)` et `(id_arrivee, id_site)` vers `emplacements` sont déclarées. Erreur retournée : `ERROR 1901 (HY000): Function or expression 'id_depart' cannot be used in the CHECK clause`.

## Contournement actuel (en production dans le DDL)

La règle XOR `ck_mvt_src_dst` (qui valide les combinaisons valides selon `type_mouvement` : ENTREE / SORTIE / TRANSFERT / AJUSTEMENT) est portée par **2 triggers** `BEFORE INSERT` et `BEFORE UPDATE` qui lèvent un `SIGNAL SQLSTATE '45000'` si la règle est violée. Sémantique identique au CHECK initialement prévu, validé par 8 tests fonctionnels.

Voir [`../01-architecture-technique/ddl/wms-schema.sql`](../01-architecture-technique/ddl/wms-schema.sql) section trigger et [`../01-architecture-technique/ddl/wms-ddl.md`](../01-architecture-technique/ddl/wms-ddl.md) §5.bis.

## Investigation réalisée

| Test | Résultat |
|---|---|
| CHECK seul sur table simplifiée (sans FK composites) | ✅ accepté |
| CHECK + FK composites sur table simplifiée (sans timestamps, sans UNIQUE numero_mvt) | ✅ accepté |
| CHECK + FK composites + colonnes timestamps + UNIQUE numero_mvt | ❌ rejeté |
| Découpage en 4 CHECK séparés (un par valeur d'ENUM) | ❌ rejeté |
| Inversion ordre des CHECK (complexe avant simple) | ❌ rejeté |
| Inversion position FK composite article_client (dernière au lieu de première) | ❌ rejeté |
| Drop FK composites → ajout CHECK → re-add FK composites | ❌ rejeté au re-add |
| ALTER TABLE ADD CHECK après création | ❌ rejeté |

Conclusion : bug confirmé du parser MariaDB 11.4.10, insensible à toutes les variations syntaxiques testées. Reproductible à 100% sur l'image officielle `mariadb:11.4`.

## Options de résolution

### Option A — Statu quo : garder les triggers
- **Pour** : déjà implémenté, testé, fonctionnel. Sémantique strictement équivalente au CHECK.
- **Contre** : viole le principe « triggers minimisés » qu'on avait posé. Risque de désynchronisation si la règle évolue (faut maintenir 2 triggers symétriques).
- **Effort** : zéro (rien à faire).

### Option B — Tester une version MariaDB plus récente
- **Pour** : si le bug est corrigé dans 11.4.11, 11.5 ou 11.6, on récupère le CHECK déclaratif sans changement de logique.
- **Contre** : pas garanti que le bug soit corrigé. 11.5 et 11.6 ne sont pas LTS (problème pour production).
- **Effort** : 30 min de test sur conteneur. À tenter en priorité.

### Option C — Bascule SGBD
- **Pour** : PostgreSQL n'a pas ce bug. CHECK + FK composites cohabitent sans souci.
- **Contre** : remet en cause la décision SGBD verrouillée. Coût énorme (refonte DDL, perte de l'argumentaire MariaDB+Galera, à refaire la justification SGBD pour la soutenance).
- **Effort** : élevé. À éviter sauf si on tombe sur d'autres limitations MariaDB bloquantes.

### Option D — Abandonner les FK composites, garder le CHECK
- **Pour** : retombe sur la garantie XOR déclarative.
- **Contre** : perd la garantie TRANSFERT intra-site déclarative (décision V4 verrouillée). Faudrait un trigger pour ça à la place. On change juste le point où le trigger se trouve.
- **Effort** : moyen (refonte DDL mouvements + nouveau trigger TRANSFERT).

### Option E — Reporter le bug à MariaDB
- **Pour** : citoyenneté logicielle. Si reconnu et corrigé, bénéficie à tout le monde.
- **Contre** : pas de délai garanti. Ne résout pas le problème immédiat.
- **Effort** : 1h pour rédiger un rapport reproductible sur https://jira.mariadb.org/.
- **Compatible** avec A, B, C, D — peut être fait en parallèle de la décision finale.

## Recommandation provisoire

**B + E en parallèle, fallback A si B échoue.**

1. Tester 11.4.11 (si dispo), 11.5, 11.6 → si le bug est corrigé sur une version LTS-compatible, basculer sur CHECK.
2. Rédiger le bug report MariaDB en parallèle.
3. Si aucune version récente ne corrige : rester sur l'option A (triggers) et l'assumer en soutenance comme un compromis technique documenté.

## Décision finale

⏳ **À prendre.** Owner : Ianis. Échéance suggérée : avant le démarrage du livrable HA/PRA (le DDL doit être stable avant de provisionner Galera).

## Mise à jour

- 2026-05-22 : bug découvert pendant tests DDL. Contournement A appliqué. Décision finale ouverte.
