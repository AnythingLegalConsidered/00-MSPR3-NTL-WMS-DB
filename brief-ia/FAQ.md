# FAQ Soutenance — MCD / MLD WMS-DB

> Réponses prêtes à défendre, droit au but. Si tu vas plus loin que la réponse écrite ici, tu improvises au-delà du périmètre tranché — risqué.

## MCD — choix structurants

### Pourquoi 8 entités et pas le modèle complet à 14 ?
V1 = cœur WMS défendable en soutenance. Lots/DLC/FEFO, commandes, expéditions, transporteurs reportés en évolution V2 fonctionnelle. C'est un choix de périmètre assumé, pas un oubli. → `wms-mcd.md` §7

### Pourquoi STOCK est une entité et pas une association ?
STOCK est une **entité réifiée dépendante** du couple (ARTICLE, EMPLACEMENT). On l'a sorti d'une ternaire `stockage(ARTICLE, STOCK, EMPLACEMENT)` parce qu'avec STOCK en cardinalité (1,1), la ternaire était décomposable en 2 binaires (règle Merise). Lecture du diagramme plus naturelle, MLD identique. → `convergence/arbitrages-v4-ianis.md` point 1

### Pourquoi FOURNISSEUR est extrait d'ARTICLE et pas juste un attribut texte ?
Un attribut `fournisseur` violerait la 3NF (redondance, typos, impossible d'enrichir). L'extraction en entité garantit l'intégrité référentielle via FK et permet d'ajouter des attributs en V2 (contact, contrat) sans refonte. Coût : +1 entité, +1 association. → `convergence/arbitrages-v4-ianis.md` point 4

### Pourquoi `realise_pour CLIENT-MOUVEMENT` alors qu'on peut dériver le client via l'ARTICLE ?
La séparation multi-tenant est **l'exigence centrale** du sujet NTL. Sans cette association, la garantie n'est visible qu'au MLD. Le cycle CLIENT-ARTICLE-MOUVEMENT-CLIENT n'est pas une redondance fautive, c'est une **contrainte d'intégrité explicite** verrouillée au DDL par la FK composite option D. → `convergence/arbitrages-v4-ianis.md` point 3

### Pourquoi `id_site` est dénormalisé sur `mouvements` ?
Pour garantir **déclarativement** la règle TRANSFERT intra-site sans trigger. La FK composite `(id_depart, id_site) → emplacements(id_emplacement, id_site)` empêche au niveau du moteur InnoDB de référencer un emplacement d'un autre site. → `wms-mcd.md` §4 + `wms-mld.md` §5

### Pourquoi pas d'association directe SITE-MOUVEMENT au MCD ?
Pour ne pas polluer le diagramme avec une redondance conceptuelle (le site est dérivable via EMPLACEMENT). La dénormalisation est une décision MLD/DDL, pas conceptuelle.

### C'est quoi le XOR sur AJUSTEMENT et pourquoi c'est pas dans le MCD ?
AJUSTEMENT cible exactement un emplacement (départ XOR arrivée). Cette contrainte conditionnelle par valeur n'est pas exprimable en Merise classique. Reportée au DDL via `CHECK ck_mvt_src_dst`. Limitation reconnue du formalisme. → `convergence/arbitrages-v4-ianis.md` point 5

## MLD — choix d'implémentation

### C'est quoi « l'option D » ?
C'est la solution retenue pour garantir au MLD/DDL qu'un stock ou un mouvement ne peut pas associer un article avec un autre client que son propriétaire. Concrètement : FK composite `(id_article, id_client)` depuis `stocks` et `mouvements` vers `articles(id_article, id_client)`. Vérifié déclarativement par InnoDB, pas de trigger. → `wms-mld.md` §5

### Pourquoi des surrogate `id_*` partout au MLD et pas les codes métier en PK ?
Standard industriel. INT UNSIGNED = 4 octets, FK plus légères, jointures plus rapides, ALTER plus simple si un code métier change. Le code métier MCD (`CODE_CLIENT`, `LOGIN`, etc.) est conservé en `UNIQUE NOT NULL` pour traçabilité externe. → `wms-mld.md` §1 règle 2

### Pourquoi ENUM et pas une table de référence ?
ENUM = compact, contrôlé par le moteur, équivalent fonctionnel à `CHECK IN (...)`. Pour les 4 domaines V1 (statut client, rôle utilisateur, type emplacement, type mouvement), les valeurs sont stables. Si une nouvelle valeur arrive, `ALTER TABLE` (verrou court). Si on prouve une volatilité forte → bascule vers table de référence en V2. → `wms-mld.md` §6.2 + §9

### Pourquoi pas de trigger pour TRANSFERT intra-site ?
Triggers = magie cachée, difficiles à auditer, alourdissent la maintenance. La FK composite `(id_depart, id_site)` + `(id_arrivee, id_site)` vers `emplacements(id_emplacement, id_site)` donne la même garantie déclarativement, vérifiée par le moteur. C'est plus propre et plus lisible. → `wms-mld.md` §5

### Mais il y a 2 triggers sur `mouvements`, pourquoi ?
Forcés par un **bug du parser MariaDB 11.4** identifié au moment de l'exécution du DDL : tout `CHECK` qui référence `id_depart` ou `id_arrivee` sur la table `mouvements` est rejeté avec `ERROR 1901` à cause de l'interaction avec les FK composites. Les FK composites étant prioritaires (verrouillent l'isolation TRANSFERT intra-site, décision V4 verrouillée), on a porté la règle XOR `ck_mvt_src_dst` via 2 triggers `BEFORE INSERT / BEFORE UPDATE` avec `SIGNAL SQLSTATE '45000'`. Sémantique identique au CHECK initial. → `wms-ddl.md` §5.bis

### Pourquoi `ON DELETE RESTRICT` partout au lieu de CASCADE ?
Parce qu'on ne veut **jamais** détruire un historique de mouvements en supprimant un client ou un article. Une suppression métier passe par soft-delete applicatif (statut, archivage). Exception : `articles.id_fournisseur` en `SET NULL` (un fournisseur supprimé ne doit pas bloquer un article). → `wms-mld.md` §4

### Pourquoi `UNIQUE(id_article, id_emplacement)` sur `stocks` ?
Règle métier non négociable : une seule ligne de stock courant par couple article/emplacement. Si on a 50 palettes du même article au même emplacement, c'est UNE ligne avec `quantite = 50`, pas 50 lignes. → `wms-mld.md` §3

## Périmètre et limites

### Pourquoi pas de lots / DLC / FEFO ?
Hors périmètre V1 assumé. Sujet : « cœur WMS défendable ». Lots = +1 entité minimum, refonte du STOCK (par lot), refonte des MOUVEMENTS (par lot), tracking DLC. Évolution V2. → `wms-mcd.md` §7

### Pourquoi pas de soft-delete (`deleted_at`) en V1 ?
Pas d'exigence dans le sujet, alourdit toutes les requêtes (filtre `WHERE deleted_at IS NULL` partout ou vues). Reporté V2 si besoin. La politique `ON DELETE RESTRICT` empêche de toute façon les suppressions cassantes. → `wms-mld.md` §9

### C'est quoi la différence multi-tenant logique vs physique ?
- **Logique (V1)** : un seul schéma, isolation par FK composite et filtres `WHERE id_client = ?` dans l'application.
- **Physique (V2 si exigé)** : un schéma par client, isolation au niveau base. Plus sécurisé, mais coût opérationnel × N clients (sauvegardes, migrations, monitoring).
→ `wms-mld.md` §9

## Technique

### Pourquoi MariaDB 11.4 et pas PostgreSQL / MySQL ?
- **LTS** : MariaDB 11.4 LTS = support jusqu'à 2029, stable pour production
- **Galera** : support HA cluster multi-maître natif (critère RTO/RPO)
- **Licence GPLv2** : pas d'incertitude juridique comme MySQL (Oracle)
- **Compatibilité** : drop-in MySQL si migration future
- Justification détaillée à formaliser dans le livrable « Justification SGBD » (cf. [`EQUIPE.md`](EQUIPE.md))

### Pourquoi InnoDB et pas un autre moteur ?
Seul moteur transactionnel MariaDB qui supporte FK + ACID + Galera. Aria et MyISAM ne supportent pas les FK. Pas de débat. → `wms-mld.md` §1 règle 10

### Pourquoi `utf8mb4` et pas `utf8` ?
`utf8` MySQL/MariaDB historique = max 3 octets par caractère, ne couvre pas tout l'Unicode (notamment emoji, certains idéogrammes). `utf8mb4` = 4 octets max, vrai UTF-8. Standard depuis ~2015. → `wms-mld.md` §1 règle 9

### Comment on garantit RTO 1h / RPO 15 min ?
- **RPO 15 min** : sauvegardes incrémentales `mariabackup` toutes les 15 min, ou réplication synchrone Galera (RPO ≈ 0 entre nœuds)
- **RTO 1h** : failover automatique Galera (basculement < 5 min) + procédure de restauration documentée dans le RunBook
- Détail à formaliser dans le livrable HA/PRA
