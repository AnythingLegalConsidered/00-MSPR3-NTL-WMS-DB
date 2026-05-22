# Note Comité de Direction — Sécurisation de la base WMS

**Émetteur** : DSI / Équipe projet WMS-DB

**Destinataires** : Comité de direction NordTransit Logistics

**Date** : 2026-05-22

**Objet** : Risques cyber sur la base de données WMS, impacts opérationnels, plan d'action proposé

---

## 1. Contexte

Le nouveau WMS pilote l'ensemble de nos opérations d'entrepôt sur les quatre sites (siège Lille, Lens, Valenciennes, Arras). Sa base de données concentre désormais **la totalité de notre activité logistique** : stocks, mouvements, ordres clients, traçabilité.

Concrètement, si cette base devient inaccessible ou est compromise :

- les quais ne peuvent plus enregistrer de réception ni d'expédition sur les quatre sites simultanément ;
- les engagements de délai pris auprès de nos clients sont rompus, avec activation des **clauses de pénalité contractuelles** ;
- la confiance commerciale est entamée, notamment sur les **comptes-clés multi-tenants** ;
- en cas de fuite, NTL est exposé à des **obligations RGPD** (notification 72 h) et à un risque réputationnel.

La présente note expose les cinq risques majeurs identifiés, leurs conséquences métier, et le plan d'action proposé à votre arbitrage.

## 2. Les cinq risques majeurs

| # | Risque | En clair | Probabilité | Gravité |
|---|---|---|---|---|
| 1 | **Arrêt prolongé de la base** | Une panne dépasse l'heure de reprise visée et bloque les quatre sites en pleine journée | Moyenne | Critique |
| 2 | **Vol d'un accès applicatif** | Un compte technique du WMS est compromis (mot de passe volé, hameçonnage) et donne lecture/écriture sur les données | Faible | Critique |
| 3 | **Ransomware avec sauvegardes inutilisables** | Un chiffreur frappe la base **et** les sauvegardes (parce qu'elles ne sont pas externalisées et jamais testées) | Moyenne | Critique |
| 4 | **Fuite croisée de données clients** | Un client voit accidentellement les stocks ou commandes d'un autre client (défaut d'étanchéité multi-tenant) | Faible | Élevée |
| 5 | **Perte de traçabilité réglementaire** | Les journaux d'audit sont absents ou effaçables, rendant impossible toute enquête après incident | Moyenne | Élevée |

## 3. Impact métier

> **Note méthodologique** : à ce stade du projet, aucune analyse d'impact métier (BIA — Business Impact Analysis) n'a été conduite avec la direction financière et les directions d'exploitation. Les niveaux d'impact ci-dessous sont donc **qualitatifs** (Modéré / Élevé / Critique). La quantification financière fera l'objet d'un travail dédié, sous le pilotage du contrôle de gestion, et constitue elle-même l'une des décisions demandées au CODIR (§6).

| Risque | Conséquence opérationnelle | Niveau d'impact |
|---|---|---|
| **1. Arrêt prolongé** | Quais bloqués sur les 4 sites, réception et expédition figées, escalade vers transporteurs et clients, perte de créneaux de livraison, activation des pénalités contractuelles | **Critique** |
| **2. Vol d'accès** | Modifications silencieuses des stocks, exfiltration possible des données clients, vols internes facilités, perte de confiance commerciale | **Critique** |
| **3. Ransomware** | Activité à l'arrêt plusieurs jours, pression d'une demande de rançon, reprise dégradée via procédures papier, communication de crise à gérer | **Critique** |
| **4. Fuite multi-tenant** | Un client constate qu'il voit (ou pourrait voir) les données d'un autre client : perte de confiance immédiate, résiliation possible, effet de contagion commerciale | **Élevé** |
| **5. Perte de traçabilité** | Impossibilité de prouver notre conformité lors d'un litige client, d'un contrôle ou d'un sinistre, refus possible de l'assureur cyber d'indemniser | **Élevé** |

## 4. Plan d'action proposé

Les mesures sont classées par priorité : **P1 = à engager immédiatement**, **P2 = dans les 3 mois**, **P3 = dans les 6 mois**.

### P1 — À engager immédiatement (couvre les risques 1, 2, 3)

- **Externaliser les sauvegardes** vers un site distinct et hors-ligne (règle 3-2-1) — *réponse au risque 3*
- **Tester mensuellement la restauration** sur un environnement isolé, avec chronométrage — *réponse au risque 1*
- **Mettre en service le cluster haute disponibilité** de la base (deux nœuds actifs minimum + arbitre) — *réponse au risque 1*
- **Activer le MFA sur tous les comptes administrateurs** de la base et de l'infrastructure — *réponse au risque 2*
- **Comptes techniques nominatifs et secrets en coffre-fort** (suppression des mots de passe partagés) — *réponse au risque 2*

### P2 — Dans les 3 mois (couvre les risques 2, 4, 5)

- **Cloisonnement strict des accès** : chaque application et chaque utilisateur n'a accès qu'aux données dont il a strictement besoin pour son rôle — comme un employé qui ne reçoit que les clés des armoires de son service. Si un compte est compromis, l'attaquant ne peut pas se déplacer librement dans le reste du système.
- **Audit log inviolable** : journalisation centralisée des accès et des modifications, en écriture seule (impossible à effacer même pour un administrateur), conservation 12 mois minimum.
- **Procédures incident formalisées** (RunBook) : qui appeler, dans quel ordre, en combien de temps, avec quels moyens de communication de repli.

### P3 — Dans les 6 mois (résilience long terme)

- **Exercice de crise grandeur nature** : simuler une perte totale du site principal
- **Souscription d'une assurance cyber** alignée sur le niveau de maturité atteint
- **Sensibilisation des équipes opérationnelles** (hameçonnage, gestion des accès, hygiène mots de passe)

## 5. Effort et délais

Le chiffrage financier des mesures n'est pas encore consolidé : il dépend d'arbitrages techniques en cours (topologie cluster, choix solution de sauvegarde externalisée, périmètre assurance) et de devis fournisseurs à instruire. La présente note s'en tient donc à l'**effort interne** et au **délai cible** pour chaque priorité.

| Priorité | Effort interne (équipe IT) | Délai cible |
|---|---|---|
| P1 | Mobilisation significative — chantier prioritaire | **6 semaines** |
| P2 | Effort modéré — en parallèle de l'exploitation courante | **3 mois** |
| P3 | Effort ponctuel — exercices et formation | **6 mois** |

Un chiffrage détaillé (CAPEX / OPEX, j.h consolidés, devis fournisseurs) sera présenté au CODIR suivant validation de principe du plan.

## 6. Décisions attendues du Comité

1. **Validation de principe du plan P1** (sauvegarde externalisée, HA, MFA admin) et mandat à la DSI pour instruire les devis fournisseurs en vue d'un arbitrage budgétaire chiffré au prochain CODIR.
2. **Lancement d'une analyse d'impact métier (BIA)** sous le pilotage du contrôle de gestion, avec les directions d'exploitation, afin de quantifier le coût des risques décrits au §3 et de calibrer les investissements.
3. **Désignation d'un sponsor exécutif** côté direction pour le suivi mensuel des indicateurs cyber.
4. **Validation du principe d'un exercice de crise annuel** impliquant la direction.

---

*Annexes disponibles sur demande : registre des risques détaillé, architecture technique cible, journal des décisions projet.*
