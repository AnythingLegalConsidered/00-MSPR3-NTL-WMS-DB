# FAQ Soutenance — modèle de données WMS (V2 grossiste)

> Réponses prêtes à défendre, alignées sur le modèle **réellement rendu** : MCD/MLD/DDL V2 grossiste (8 tables, 0 trigger, 0 FK composite).
> ⚠️ Cette FAQ remplace une version antérieure qui décrivait un modèle multi-tenant V4 **abandonné**. Ne défends que ce qui est ci-dessous — c'est ce qui est dans le `wms-schema.sql`.

## Le modèle en une phrase

NTL est un **grossiste** : 8 tables (`site`, `localisation`, `utilisateur`, `client`, `article`, `stock`, `mouvement`, `commande`), intégrité par **FK simples + CHECK + UNIQUE**, surrogate keys `id_*`, moteur InnoDB, `utf8mb4`. Aucun trigger. Cf. [`decisions/0003-postulats-cadrage-ntl.md`](decisions/0003-postulats-cadrage-ntl.md).

## Cadrage métier

### Pourquoi avoir modélisé NTL en grossiste et pas en 3PL ?
Le sujet est **ambigu** : « PME de logistique » + « séparation des données par client » peut se lire grossiste (stock propre) **ou** 3PL (stock des clients). Plutôt que de deviner, on a posé un **postulat explicite** — grossiste — et cadré la V1 dessus. C'est tracé dans [ADR 0003](decisions/0003-postulats-cadrage-ntl.md). → ne **jamais** dire « on n'a pas compris le sujet » : dire « on a tranché une ambiguïté par un postulat assumé ».

### Le sujet exige « séparation des données par client ». Où est-elle ?
Par **attribution** : chaque `commande` et chaque `mouvement` de sortie porte un `id_client`. On sait parfaitement *qui a commandé / reçu quoi*. L'**isolation forte** (un client ne voit jamais les données d'un autre) n'a de sens qu'en **3PL** ; sous le postulat grossiste, NTL possède son stock, donc l'attribution suffit. L'isolation multi-tenant est une **évolution V2** si NTL bascule vers le 3PL.

### Pourquoi 8 tables et pas un modèle plus complet ?
Périmètre V1 **volontairement resserré sur le cœur métier** (entreposage : sites, emplacements, articles, stock, mouvements, clients, commandes), conçu pour évoluer. Lots/DLC/FEFO, expéditions, transporteurs = couche fonctionnelle V2 assumée, pas un oubli. → cadre ça comme un **MVP**, pas un « brouillon ».

## MCD / MLD — choix structurants

### Pourquoi STOCK est une entité/table et pas une simple association ?
Un `stock` = **1 article × 1 emplacement × 1 quantité**. C'est une entité réifiée porteuse de la quantité. La contrainte `UNIQUE (id_article, id_localisation)` garantit qu'il n'y a **qu'une ligne** de stock par couple article/emplacement (50 palettes du même article au même endroit = 1 ligne `quantite=50`, pas 50 lignes).

### Pourquoi `mouvement.id_client` est nullable ?
Issu de l'association `CONCERNE` (MOUVEMENT 0,1 — CLIENT 0,N). Un mouvement **interne** (transfert intra-entrepôt, ajustement d'inventaire) n'a **pas de client** → NULL. Une sortie vers un client porte son `id_client`.

### Comment gérez-vous les 4 types de mouvement (entrée/sortie/ajustement/transfert) ?
Par l'attribut `mouvement.type` contraint par `CHECK (type IN ('entree','sortie','ajustement','transfert'))`, plus `quantite > 0` (le **sens** est porté par `type`, la quantité reste toujours positive). Un mouvement référence **un seul** `id_stock` (la ligne de stock impactée). → modèle simple, pas de colonnes départ/arrivée.

### Pourquoi `fournisseur` est un attribut texte et pas une entité ?
Choix de **périmètre** : la gestion achats/fournisseurs (contrats, contacts, références) est portée par l'**ERP commercial NTL**, hors périmètre WMS V1. En V1, `article.fournisseur VARCHAR(100)` suffit à tracer l'origine. Si la gestion fournisseur entre dans le WMS en V2 → extraction en entité `FOURNISSEUR` (intégrité référentielle, 3NF). On assume le compromis.

### Pourquoi des surrogate keys `id_*` partout ?
Standard industriel. `INT UNSIGNED` = 4 octets, FK légères, jointures rapides, `ALTER` simple si un code métier change. Les codes métier (`siret`, `code` localisation, `reference` mouvement) sont conservés en `UNIQUE NOT NULL` pour la traçabilité externe.

### Pourquoi `ON DELETE RESTRICT` partout ?
On ne veut **jamais** détruire un historique de mouvements/stocks en supprimant un client, un article ou un site. Une suppression métier passe par un statut applicatif (soft-delete). `RESTRICT` bloque toute suppression cassante au niveau moteur.

### Pourquoi une table `commande` séparée ?
Association N-N entre CLIENT et ARTICLE (un client commande plusieurs articles, un article est commandé par plusieurs clients), avec attributs propres `quantite_commandee` et `date_commande`. Règle de passage MCD→MLD classique : association N-N → table associative.

## Technique

### Pourquoi MariaDB 11.4 et pas MySQL / PostgreSQL ?
- **Drop-in replacement de MySQL** : NTL est déjà sous MySQL → migration quasi nulle, équipe IT pas reformée. (Argument n°1.)
- **LTS jusqu'en 2029**, **indépendance Oracle** (Fondation MariaDB).
- **Galera disponible nativement** : argument HA fort pour l'évolution vers une vraie haute dispo synchrone.
- **PostgreSQL écarté** : imposerait de réécrire le WMS-APP (driver, dialecte, types) — hors sujet — et l'équipe IT NTL n'a aucune compétence Postgres.
- → ne **pas** dire « MariaDB est mieux que MySQL ». Dire « meilleur compromis **dans ce contexte** ». Détail : [`decisions/0002-sgbd-mariadb.md`](decisions/0002-sgbd-mariadb.md).

### Pourquoi InnoDB ?
Seul moteur MariaDB transactionnel avec **FK + ACID**. MyISAM/Aria ne supportent pas les FK. Pas de débat.

### Pourquoi `utf8mb4` et pas `utf8` ?
`utf8` MariaDB = 3 octets max, ne couvre pas tout l'Unicode. `utf8mb4` = vrai UTF-8 (4 octets), standard depuis ~2015.

### Le DDL a-t-il été testé ?
**Honnêteté** : le script V2 n'a **pas encore** été exécuté sur une instance MariaDB 11.4 (cf. `01-architecture-technique/ddl/wms-ddl.md` §8). Le plan de tests est défini (4 CHECK, 10 FK, contrainte UNIQUE, ON DELETE RESTRICT). Si on te demande : ne prétends pas l'avoir testé.

## Périmètre et limites (à assumer)

| Hors V1 | Pourquoi | Évolution |
|---|---|---|
| Multi-tenant (isolation) | Postulat grossiste = stock propre | V2 si bascule 3PL → FK composite `(id_article, id_client)` |
| Lots / DLC / FEFO | Cœur WMS d'abord | V2 |
| Expéditions / transporteurs | Hors cœur entreposage | V2 |
| Gestion fournisseurs | Portée par l'ERP commercial | V2 si intégration WMS |
| Prix / facturation | Hors périmètre BDD WMS | ERP |

## Le piège n°1 à connaître

> « Le sujet demande la séparation des données par client, je ne la vois pas comme une isolation forte dans votre schéma. »

**Réponse** : « Sous notre postulat grossiste (stock propre NTL), la séparation pertinente est l'**attribution** — présente via `mouvement.id_client` et `commande`. L'isolation multi-tenant ne se justifie qu'en modèle 3PL, qu'on a explicitement réservé à une V2. C'est un arbitrage tracé ([ADR 0003](decisions/0003-postulats-cadrage-ntl.md)), pas un manque. »
