# Note Comité de Direction — Sécurisation de la base WMS

**Émetteur** : DSI / Équipe projet WMS-DB
**Destinataires** : Comité de direction NordTransit Logistics
**Date** : 2026-05-22
**Objet** : Risques cyber sur la base de données WMS, impacts opérationnels, plan d'action proposé
**Format** : note de cadrage — 2 pages — décision attendue

---

## 1. Contexte

Le nouveau WMS pilote l'ensemble de nos opérations d'entrepôt sur les quatre sites (siège Lille, Lens, Valenciennes, Arras). Sa base de données concentre désormais **la totalité de notre activité logistique** : stocks, mouvements, ordres clients, traçabilité. Une indisponibilité ou une compromission de cette base arrête les quais et expose NTL à des pénalités contractuelles. La présente note expose les cinq risques majeurs identifiés, leurs conséquences métier, et le plan d'action proposé à votre arbitrage.

## 2. Les cinq risques majeurs

| # | Risque | En clair | Probabilité | Gravité |
|---|---|---|---|---|
| 1 | **Arrêt prolongé de la base** | Une panne dépasse l'heure de reprise visée et bloque les quatre sites en pleine journée | Moyenne | Critique |
| 2 | **Vol d'un accès applicatif** | Un compte technique du WMS est compromis (mot de passe volé, hameçonnage) et donne lecture/écriture sur les données | Faible | Critique |
| 3 | **Ransomware avec sauvegardes inutilisables** | Un chiffreur frappe la base **et** les sauvegardes (parce qu'elles ne sont pas externalisées et jamais testées) | Moyenne | Critique |
| 4 | **Fuite croisée de données clients** | Un client voit accidentellement les stocks ou commandes d'un autre client (défaut d'étanchéité multi-tenant) | Faible | Élevée |
| 5 | **Perte de traçabilité réglementaire** | Les journaux d'audit sont absents ou effaçables, rendant impossible toute enquête après incident | Moyenne | Élevée |

## 3. Impact métier

Hypothèses retenues pour le chiffrage indicatif (à valider avec le contrôle de gestion) : CA journalier des opérations entrepôt ≈ 80 k€, pénalités contractuelles type **2 % du CA mensuel concerné par retard** sur les comptes-clés.

| Risque | Conséquence opérationnelle | Coût d'occurrence estimé |
|---|---|---|
| **1. Arrêt prolongé** | Quais bloqués sur 4 sites · réception et expédition figées · escalade vers les transporteurs et les clients · perte de créneaux | **80-160 k€ par journée perdue** + pénalités · risque réputation |
| **2. Vol d'accès** | Modifications silencieuses des stocks, vols facilités, données clients exfiltrées | Stocks à recompter manuellement · CNIL (RGPD) si données personnelles · perte de clients |
| **3. Ransomware** | Activité à l'arrêt plusieurs jours · pression rançon · reprise depuis sauvegardes papier | **> 500 k€** sur 5 jours · risque de fermeture temporaire d'un site |
| **4. Fuite multi-tenant** | Perte de confiance d'un compte-clé · résiliation possible · effet boule de neige commercial | Perte d'un contrat = **plusieurs centaines de k€/an** |
| **5. Perte de traçabilité** | Impossible de prouver notre conformité en cas de litige ou contrôle · assurance cyber qui refuse de couvrir | Non quantifiable directement, mais bloquant en cas d'incident |

## 4. Plan d'action proposé

Les mesures sont classées par priorité : **P1 = à engager immédiatement**, **P2 = dans les 3 mois**, **P3 = dans les 6 mois**.

### P1 — À engager immédiatement (couvre les risques 1, 2, 3)

- **Externaliser les sauvegardes** vers un site distinct et hors-ligne (règle 3-2-1) — *réponse au risque 3*
- **Tester mensuellement la restauration** sur un environnement isolé, avec chronométrage — *réponse au risque 1*
- **Mettre en service le cluster haute disponibilité** de la base (deux nœuds actifs minimum + arbitre) — *réponse au risque 1*
- **Activer le MFA sur tous les comptes administrateurs** de la base et de l'infrastructure — *réponse au risque 2*
- **Comptes techniques nominatifs et secrets en coffre-fort** (suppression des mots de passe partagés) — *réponse au risque 2*

### P2 — Dans les 3 mois (couvre les risques 2, 4, 5)

- **Cloisonnement strict des accès** : chaque application accède uniquement à ce dont elle a besoin (principe du moindre privilège)
- **Audit log inviolable** : journalisation centralisée, écriture seule, conservation 12 mois minimum
- **Vérification du cloisonnement client** : revue indépendante de l'étanchéité multi-tenant avant ouverture à un cinquième client
- **Procédures incident formalisées** (RunBook) : qui appeler, dans quel ordre, en combien de temps

### P3 — Dans les 6 mois (résilience long terme)

- **Exercice de crise grandeur nature** : simuler une perte totale du site principal
- **Souscription d'une assurance cyber** alignée sur le niveau de maturité atteint
- **Sensibilisation des équipes opérationnelles** (hameçonnage, gestion des accès, hygiène mots de passe)

## 5. Budget indicatif et délais

| Priorité | Effort interne | Investissement externe | Délai cible |
|---|---|---|---|
| P1 | 15-20 j.h équipe IT | Sauvegarde externalisée : **5-10 k€/an** · MFA : déjà licencié M365 | **6 semaines** |
| P2 | 20-25 j.h | Journalisation centralisée : **3-5 k€/an** · audit externe multi-tenant : **5-8 k€** ponctuel | **3 mois** |
| P3 | 10-15 j.h | Assurance cyber : **8-15 k€/an** (selon couverture) · sensibilisation : **2-3 k€** | **6 mois** |

**Total ordre de grandeur : 25-45 k€ d'investissement année 1**, à mettre en regard d'**une seule journée d'arrêt évitée (80-160 k€)**.

## 6. Décisions attendues du Comité

1. **Validation du plan P1** et déblocage budgétaire associé (sauvegarde externalisée, HA, MFA admin).
2. **Désignation d'un sponsor exécutif** côté direction pour le suivi mensuel des indicateurs cyber.
3. **Arbitrage sur l'assurance cyber** (P3) : périmètre souhaité et plafond de couverture.
4. **Validation du principe d'un exercice de crise annuel** impliquant la direction.

---

*Annexes disponibles sur demande : registre des risques détaillé, architecture technique cible, journal des décisions projet.*
