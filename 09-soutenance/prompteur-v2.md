# Prompteur — Soutenance MSPR3 NTL WMS (deck v2)

> **Miroir slide par slide du fichier `MSPR3-NTL-WMS-Soutenance-v2.pptx`.**
> Pour chaque slide : ce qui est à l'écran · le texte à dire (rédigé, lisible tel quel) · les réponses à garder sous la main si le jury creuse.

**Fil rouge à marteler** : *« On a tranché une ambiguïté du sujet par un postulat assumé et tracé. »* — jamais *« on n'a pas compris le sujet »*.

**Mode d'emploi** : 🖥️ = ce que le jury voit · 🎤 = ce que tu dis · 💡 = si on te pose la question. Le 🎤 se lit à voix haute presque tel quel ; adapte juste le débit.

| # | Slide | Orateur | Cible |
|---|---|---|---|
| 1 | Titre | Ianis | 0:30 |
| 2 | Contexte & enjeu | Ianis | 1:30 |
| 3 | Démarche & pilotage | Ianis | 1:30 |
| 4 | Modèle de données | Blaise (+ Ianis) | 2:00 |
| 5 | Optimisation | Blaise | 1:00 |
| 6 | Choix SGBD | Ojvind | 1:00 |
| 7 | Architecture HA | Ojvind | 1:30 |
| 8 | PRA & sauvegardes | Zaid | 2:00 |
| 9 | Sécurité des accès | Zaid | 1:00 |
| 10 | Note CODIR | Zaid | 1:30 |
| 11 | Supervision | Ojvind | 1:30 |
| 12 | RunBook & logs | Zaid | 1:30 |
| 13 | Difficultés → solutions | Ianis | 1:30 |
| 14 | Résultats & perspectives | Blaise | 1:30 |
| 15 | Conclusion | équipe | 0:30 |

**Total ≈ 20 min.** Objectif : garder ~30 s de marge. Si ça déborde, on coupe dans S5 et S9 (les plus compressibles).

---

## Slide 1 — Titre
**Ianis · 0:30**

🖥️ Titre du projet, l'équipe, un résumé en anglais.

🎤 « Bonjour. Nous sommes Ianis, Blaise, Ojvind et Zaid, et nous allons vous présenter notre travail sur l'industrialisation de la base de données du WMS de NordTransit Logistics — le système qui pilote leurs entrepôts. Je vais commencer par poser le contexte et notre démarche, puis mes collègues dérouleront la conception du modèle, l'architecture, la sécurité et l'exploitation. On terminera par les difficultés qu'on a rencontrées et nos perspectives. »

---

## Slide 2 — Contexte & enjeu
**Ianis · 1:30**

🖥️ NTL en bref, criticité du WMS, contraintes, existant fragile.

🎤 « NordTransit Logistics, c'est une PME logistique des Hauts-de-France : un siège à Lille, trois entrepôts — Lens, Valenciennes, Arras — et un cross-dock saisonnier. Leur cœur de métier, c'est le WMS, le système de gestion d'entrepôt. Concrètement : si cette base tombe, ce sont les quatre sites qui s'arrêtent — plus de réceptions, plus d'expéditions, sur toute la journée d'activité, de 5h30 à 18h30. Et aujourd'hui, l'existant est fragile : une base MySQL sur une seule machine, des sauvegardes sur un NAS qui ne sont jamais testées, et aucun objectif de reprise défini. On peut intervenir presque uniquement la nuit, avec une équipe IT réduite. C'est tout l'enjeu de notre mission : rendre cette base fiable, sûre et résiliente. »

💡 *Pourquoi si critique ?* → l'arrêt du WMS = quais bloqués = chiffre d'affaires à l'arrêt sur les 4 sites, en direct.

---

## Slide 3 — Démarche & pilotage projet
**Ianis · 1:30**

🖥️ Équipe et rôles, méthode, décisions tracées, registre des risques.

🎤 « Nous étions quatre, sur un budget de dix-neuf heures. Deux sur le modèle de données — Blaise et moi — et deux sur l'infrastructure et l'exploitation — Ojvind et Zaid. On a travaillé en quatre temps : cadrage, conception, industrialisation, puis documentation. Chaque décision structurante a été tracée dans un journal de décisions : on en a six, là où le sujet en demande au moins trois. On tient aussi un registre de neuf risques, avec impacts et mesures. Et dès le cadrage, on a heurté une ambiguïté de fond dans le sujet — j'y reviens à la fin, parce que c'est elle qui a structuré tout le reste de notre travail. »

---

## Slide 4 — Modèle Conceptuel de Données (MCD)
**Blaise, avec Ianis · 2:00**

🖥️ Le diagramme MCD (7 entités, 8 associations) + un panneau « points clés ».

🎤 (Blaise) « Le modèle compte huit tables : sept entités et une table associative, `commande`. On y retrouve tout ce que demande le cahier des charges : les clients, les sites, les articles avec leurs dimensions et leur poids, les localisations, le stock actuel, et les mouvements horodatés. Le point de conception le plus important, c'est le stock : pour nous, une ligne de stock, c'est un article, à un emplacement, avec une quantité — pas plus. Cinquante palettes du même article au même endroit, c'est une seule ligne avec quantité cinquante. Côté intégrité, tout est porté par le schéma lui-même : des clés étrangères, des contraintes CHECK, des UNIQUE, et un `ON DELETE RESTRICT` partout pour ne jamais détruire l'historique des mouvements. On est en troisième forme normale, et sans aucun trigger : le modèle reste simple et lisible. »

💡 *Pourquoi `mouvement.id_client` peut être vide ?* → une sortie vers un client, on renseigne le client ; un mouvement interne — transfert, inventaire — n'a pas de client, donc c'est NULL.
💡 *Les types de mouvement ?* → quatre valeurs verrouillées par un CHECK : entrée, sortie, ajustement, transfert. La quantité reste toujours positive ; c'est le `type` qui porte le sens.
💡 *Pourquoi le fournisseur n'est pas une entité ?* → les achats sont gérés par l'ERP commercial de NTL, hors périmètre WMS. Un attribut texte suffit à tracer l'origine. Entité `FOURNISSEUR` en V2 si intégration.

---

## Slide 5 — Optimisation & performance
**Blaise · 1:00**

🖥️ Démarche par usages, requêtes types, index, choix physiques.

🎤 « Sur les performances, on est parti des usages réels plutôt que d'indexer au hasard. Les requêtes les plus fréquentes, ce sont le stock d'un article ou d'un site, les mouvements sur une période, et la recherche d'un article. On a donc posé des index ciblés là-dessus — notamment sur le couple site-article et sur la date des mouvements. Et on a choisi des types légers, des entiers non signés pour les clés étrangères, ce qui garde les jointures rapides. Bref : on optimise là où ça sert, en fonction de comment la base va vraiment être interrogée. »

---

## Slide 6 — Choix du SGBD
**Ojvind · 1:00**

🖥️ MariaDB 11.4 LTS, l'argument de continuité, PostgreSQL écarté.

🎤 « Pour le SGBD, on a retenu MariaDB 11.4 LTS, supportée jusqu'en 2029. L'argument numéro un, c'est la continuité : l'existant tourne déjà sous MySQL, et MariaDB en est un remplaçant direct. La migration est donc quasi nulle, et l'équipe IT n'a pas besoin d'être reformée. On a regardé PostgreSQL, mais il aurait fallu réécrire une partie de l'application — le pilote, le dialecte SQL, les types — et l'équipe n'a pas cette compétence. Notre position, ce n'est pas de dire "MariaDB est meilleur dans l'absolu" : c'est "c'est le meilleur compromis dans ce contexte précis". »

---

## Slide 7 — Architecture Haute Disponibilité
**Ojvind · 1:30**

🖥️ Schéma : WMS-APP → HAProxy → Master → 2 réplicas (HA local + PRA distant).

🎤 « Voici l'architecture de haute disponibilité. L'application passe par HAProxy, qui l'aiguille vers le serveur maître — celui qui reçoit toutes les écritures. Ce maître réplique en continu vers deux serveurs. Le premier est un réplica local : il couvre une panne de service ou de machine sur le site. Le second est un réplica distant : il couvre la perte complète du site de Lille. La réplication est asynchrone, avec les journaux binaires : c'est simple à exploiter et ça pèse peu sur le maître, ce qui est adapté à une petite équipe. La réplication synchrone, de type Galera, on la garde comme évolution possible en V2. »

---

## Slide 8 — PRA, sauvegardes & restauration
**Zaid · 2:00**

🖥️ Scénarios de bascule + RTO, RPO via binlogs, scripts de sauvegarde, tests.

🎤 « La continuité, c'est le cœur du sujet : on nous demande un temps de reprise d'une heure et une perte de données maximale de quinze minutes. On les tient, avec de la marge. Une panne de service ou de machine, c'est une bascule HAProxy en cinq à dix minutes. La perte du site, c'est le passage sur le réplica distant en vingt à quarante minutes — donc bien sous l'heure. Les quinze minutes de perte maximale sont garanties par les journaux binaires. Côté sauvegardes, tout est automatisé et scripté : une sauvegarde complète chaque nuit avec mariabackup, l'archivage transactionnel en continu, la rotation et la rétention, la vérification, et la notification en cas d'échec. Et surtout, on planifie les tests de restauration — parce qu'une sauvegarde qu'on n'a jamais restaurée, ce n'est pas une sauvegarde. »

💡 *Sauvegarde incrémentale ?* → l'archivage des journaux binaires joue ce rôle : il capture chaque transaction entre deux complètes, ce qui donne le RPO de quinze minutes.

---

## Slide 9 — Sécurité des accès
**Zaid · 1:00**

🖥️ Moindre privilège, comptes séparés, MFA, secrets.

🎤 « Sur les accès, on applique le principe de moindre privilège. L'application se connecte avec un compte qui a uniquement le strict nécessaire sur les tables métier — jamais un compte administrateur. L'administration passe par un compte séparé, protégé par une double authentification. Les secrets sont dans un coffre, jamais en clair dans un fichier de configuration. Et les comptes sont nominatifs, pour qu'on puisse tracer qui fait quoi. »

---

## Slide 10 — Note Comité de direction (risques cyber)
**Zaid · 1:30**

🖥️ 5 risques en langage direction, plan priorisé, RGPD.

🎤 « Le sujet demandait une note destinée au comité de direction — donc un langage non technique, orienté métier. On a identifié cinq risques cyber majeurs : l'arrêt prolongé de la base, le vol d'un accès, un ransomware qui rendrait les sauvegardes inutilisables, l'exfiltration des données clients, et la perte de traçabilité réglementaire. Pour chacun, on parle impact business, pas jargon. Et on propose un plan d'action priorisé en trois vagues : l'immédiat sur six semaines, puis à trois mois, puis à six mois. On rappelle aussi l'obligation RGPD de notifier une fuite sous soixante-douze heures. L'idée, c'est de faire adhérer la direction en parlant son langage. »

---

## Slide 11 — Supervision
**Ojvind · 1:30**

🖥️ Stack Prometheus/Grafana, 5 indicateurs + seuils reliés à un objectif.

🎤 « Pour la supervision, on propose un tableau de bord de cinq indicateurs critiques, sous Prometheus et Grafana. Ces cinq indicateurs : la latence des requêtes, le nombre de connexions actives, le retard de réplication, l'espace disque libre, et le succès des sauvegardes. Le point important, c'est qu'on ne surveille pas pour surveiller : chaque seuil est relié à un objectif concret. Par exemple, si le retard de réplication dépasse trente secondes, c'est notre RPO de quinze minutes qui est menacé. Si le disque descend sous dix pour cent, MariaDB peut s'arrêter. Et chaque alerte a sa procédure d'analyse associée. »

---

## Slide 12 — Exploitation : RunBook & analyse de logs
**Zaid · 1:30**

🖥️ RunBook (start/stop, checklists, incident, escalade), 5 sources de logs.

🎤 « L'exploitation au quotidien, c'est le RunBook. Il couvre le démarrage et l'arrêt, les contrôles de santé, les checklists quotidiennes et hebdomadaires, la procédure d'incident de bout en bout — de la détection au retour à la normale — et une matrice d'escalade du niveau 1 au niveau 4, avec des délais cibles. Sur les logs, on a identifié cinq sources : les erreurs, les requêtes lentes, les journaux binaires, HAProxy et les sauvegardes. Et pour chacune, on a cartographié les patterns critiques et la façon de les corréler, pour diagnostiquer vite quand quelque chose ne va pas. »

---

## Slide 13 — Difficultés rencontrées → solutions
**Ianis · 1:30 — LE moment clé**

🖥️ Le pivot de cadrage : ambiguïté grossiste / 3PL → postulat assumé.

🎤 « Voici la difficulté que je vous annonçais. Le sujet est ambigu : "PME logistique" avec "séparation des données par client", ça peut se lire de deux façons. Soit NTL est un grossiste, qui gère son propre stock. Soit c'est un prestataire logistique, qui héberge le stock de ses clients — ce qu'on appelle du 3PL. Et ces deux lectures mènent à des modèles très différents. Plutôt que de rester dans le flou, on a tranché : on a posé un postulat explicite — grossiste — et on l'a tracé dans une décision, l'ADR numéro 3. C'est une démarche d'itération maîtrisée, pas du tâtonnement. Conséquence assumée : l'isolation multi-tenant est reportée en V2. Et je veux être transparent avec vous : le DDL n'a pas encore été exécuté sur une vraie instance — c'est notre première perspective, ce n'est pas quelque chose qu'on cache. »

💡 **LE piège attendu** — *« Où est la séparation par client ? Je ne vois pas d'isolation forte. »*
→ « Sous notre postulat grossiste, le stock appartient à NTL. La séparation pertinente, c'est donc l'**attribution** : on sait parfaitement qui a commandé et reçu quoi, grâce à `mouvement.id_client` et à la table `commande`. L'**isolation** forte — un client ne voit jamais les données d'un autre — ne se justifie qu'en modèle 3PL, qu'on a explicitement réservé à une V2. C'est un arbitrage tracé dans l'ADR 3, pas un oubli. »

---

## Slide 14 — Résultats & perspectives V2
**Blaise · 1:30**

🖥️ Ce qui est livré, les chiffres-clés, la roadmap V2.

🎤 « Pour les résultats : on livre huit livrables qui couvrent l'intégralité du cahier des charges. En chiffres : huit tables en troisième forme normale, une architecture qui tient le temps de reprise d'une heure et la perte maximale de quinze minutes, trois serveurs de base, cinq indicateurs de supervision, six décisions tracées. Et chaque limite qu'on a posée renvoie à une décision documentée — jamais à un oubli. Nos perspectives V2 sont claires : d'abord exécuter le DDL sur une instance, ensuite le multi-tenant si NTL bascule vers du 3PL, puis la gestion des lots et des dates de péremption, les expéditions, et la réplication synchrone. On a livré un socle solide — un MVP industrialisable, pas une maquette. »

---

## Slide 15 — Conclusion
**Toute l'équipe · 0:30**

🖥️ Synthèse + fil rouge + ouverture questions.

🎤 « Pour conclure : on a conçu une base WMS pensée pour être sûre, supervisée et résiliente — un socle industrialisable. Et s'il fallait retenir une seule chose de notre démarche : face à un sujet ambigu, on a tranché par un postulat assumé et tracé, plutôt que de rester dans le flou. Merci de votre attention — nous sommes à votre disposition pour vos questions. »

---

## Annexes (non présentées — à ouvrir en entretien)

Ces cinq slides ne sont **pas** dans les 20 minutes : on les garde en réserve pour l'entretien de 30 minutes.

- **A1 — DDL (extrait table `stock`)** : à montrer si on nous demande à voir le SQL réel (UNIQUE, CHECK, FK RESTRICT, InnoDB, utf8mb4).
- **A2 — MCD détaillé (entités & cardinalités)** : pour justifier les cardinalités, le `id_client` nullable, les 4 types de mouvement.
- **A3 — Scripts de sauvegarde** : complète, transactionnel, rotation, vérification, notification — répond à l'exigence explicite du sujet.
- **A4 — Registre des risques** : les 9 risques avec gravité et mitigation.
- **A5 — Glossaire FR / EN** : couvre l'exigence de documentation bilingue.

---

## Réflexes de dernière minute

- **Honnêteté > bluff** : DDL non exécuté, impacts CODIR qualitatifs → tout est assumé et tracé. Le jury valorise ça.
- **Toute limite = un ADR**, jamais un oubli. Si on hésite, on renvoie à la décision.
- **Transitions** : chaque orateur termine en annonçant le suivant (« Blaise va vous présenter le modèle… »). À répéter autant que le fond.
- **Le piège isolation/multi-tenant (slide 13)** : c'est LA question attendue. Rester calme, dérouler attribution vs isolation.
- **Chrono** : si on déborde, on compresse S5 (optim) et S9 (sécurité accès). On ne sacrifie jamais S13.
