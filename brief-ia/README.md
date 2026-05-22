# brief-ia — interroger une IA sur le projet

**Objectif** : permettre à n'importe qui de l'équipe de demander à une IA externe (Claude Desktop, ChatGPT, Gemini, etc.) *pourquoi tel choix a été fait*, *qu'est-ce que telle décision implique*, ou *comment défendre telle position en soutenance*.

## Mode d'emploi (2 min)

1. **Ouvre une nouvelle conversation** dans ton IA (Claude Desktop, ChatGPT…).
2. **Sélectionne tous les fichiers de ce dossier sauf ce `README.md`** et glisse-les dans la conversation comme pièces jointes (drag-and-drop).
3. **Copie-colle le bloc « Prompt » ci-dessous** comme premier message.
4. Envoie. L'IA a maintenant tout le contexte. Pose tes questions.

## Prompt à coller en premier message

```
Tu vas m'aider à comprendre et défendre les décisions techniques d'un projet
de fin d'année EPSI Nantes (MSPR3 BAC+3 ASRBD, 2025-2026). Le sujet :
concevoir et industrialiser une base de données WMS (Warehouse Management
System) pour un client fictif, NordTransit Logistics (NTL), PME logistique
des Hauts-de-France.

Le SGBD cible est MariaDB 11.4 LTS. Contraintes critiques : RTO 1h, RPO 15 min.
Équipe de 4 personnes, 19h chacun.

OBJECTIF DE LA CONVERSATION
Je veux comprendre POURQUOI telle décision a été prise, pas juste QUOI a
été décidé. Quand je te pose une question, ta réponse doit :
- s'appuyer sur les fichiers joints (cite-les avec leur nom)
- expliquer le raisonnement, pas seulement la conclusion
- signaler les compromis (ce qu'on gagne, ce qu'on perd)
- répondre comme si tu briefais quelqu'un qui doit défendre le choix devant
  un jury de soutenance

ÉTAT D'AVANCEMENT
- MCD V4 officiel à 8 entités : validé, verrouillé
- MLD V1 : draft validé conceptuellement
- DDL V1 : exécuté avec succès sur MariaDB 11.4.10, 8 tests fonctionnels OK
- Reste à faire : justification SGBD, HA/PRA Galera, sécurité, supervision,
  logs, RunBook exploitation, pilotage projet, note CODIR, soutenance

DÉCISIONS VERROUILLÉES (ne reviens pas dessus, propose des workarounds
au niveau MLD/DDL si tu vois une incohérence, mais ne rouvre pas le MCD)
1. Périmètre : 8 entités (CLIENT, ARTICLE, FOURNISSEUR, SITE, EMPLACEMENT,
   STOCK, MOUVEMENT, UTILISATEUR). Modèle complet 14 entités (lots, FEFO,
   commandes, expéditions, transporteurs) reporté en V2.
2. Multi-tenant : option D — FK composite (id_article, id_client) depuis
   stocks et mouvements vers articles. Association `realise_pour` aussi
   au MCD pour rendre la séparation explicite.
3. TRANSFERT intra-site : garanti déclarativement par dénormalisation
   mouvements.id_site + FK composites vers emplacements.
4. Surrogate keys id_* partout au MLD, code métier MCD conservé en UNIQUE.
5. ENUM natif MariaDB pour les 4 domaines (status, role, type_emplacement,
   type_mouvement). Tables de référence reportées V2.
6. Triggers minimisés. EXCEPTION : ck_mvt_src_dst (règle XOR sur mouvements)
   porté par 2 triggers BEFORE INSERT/UPDATE car bug parser MariaDB 11.4
   rejette tout CHECK référençant id_depart/id_arrivee en présence des FK
   composites (voir wms-ddl.md §5.bis).
7. FK toutes en ON DELETE RESTRICT. Exception articles.id_fournisseur en
   SET NULL.

STYLE ATTENDU
- Réponses en français, code et identifiants SQL en anglais.
- Concision, droit au but, tableaux quand pertinent.
- Pas de flatterie, pas d'agreement gratuit. Si tu n'es pas sûr, dis-le.
- Cite les fichiers joints quand tu réponds (ex: « cf. wms-mcd.md §4 »).

FICHIERS JOINTS
- sujet-mspr3.pdf : cahier des charges EPSI
- wms-mcd.md : MCD V4 officiel (8 entités, 10 associations, règles, domaines)
- wms-mcd.png : diagramme MCD visuel
- wms-mld.md : MLD V1 (tables, FK simples et composites, contraintes, index)
- wms-ddl.md : choix techniques DDL + investigation bug parser MariaDB
- wms-schema.sql : DDL exécutable (8 CREATE TABLE + 2 triggers + index)
- arbitrages-v4-ianis.md : historique des 5 arbitrages structurants V4
  (POURQUOI tel choix a été tranché)
- FAQ.md : 17 Q/R prêtes à défendre en soutenance

Premier réflexe avant chaque réponse : vérifie la cohérence avec les
décisions verrouillées et les fichiers joints. Pose une question si
quelque chose n'est pas clair plutôt que d'inventer.
```

## Exemples de questions à poser à l'IA

- « Pourquoi on a choisi MariaDB plutôt que PostgreSQL ? »
- « Explique-moi l'option D multi-tenant comme si j'étais débutant. »
- « Si le jury me demande pourquoi FOURNISSEUR est une entité et pas un attribut d'ARTICLE, qu'est-ce que je réponds ? »
- « Pourquoi il y a 2 triggers sur mouvements alors qu'on a dit "pas de trigger en V1" ? »
- « Quels sont les risques si on supprime un article qui a des mouvements historiques ? »
- « Comment garantit-on que RTO 1h / RPO 15 min seront tenus ? »

## Maintenance

Les fichiers de ce dossier sont des **copies** des originaux du repo. Si une décision change ou un fichier est mis à jour, recopie-le depuis la racine du projet vers ce dossier :

```powershell
Copy-Item ..\wms-mcd.md, ..\wms-mld.md, ..\wms-ddl.md, ..\FAQ.md, `
  ..\convergence\arbitrages-v4-ianis.md, ..\ddl\wms-schema.sql, `
  ..\wms-mcd.png, ..\ressources\sujet-mspr3.pdf -Destination . -Force
```
