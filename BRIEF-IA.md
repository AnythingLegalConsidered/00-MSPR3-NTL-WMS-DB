# BRIEF-IA — interroger une IA sur le projet

> **Utilise le dossier [`brief-ia/`](brief-ia/)** : il contient les 8 fichiers à joindre + un README avec le prompt prêt à coller. Mode d'emploi en 2 min.
>
> Ce fichier-ci reste comme point d'entrée historique / référence. Pour l'usage opérationnel, va dans `brief-ia/`.

---

## Prompt à coller en premier message

```
Tu vas m'aider sur un projet de fin d'année EPSI Nantes (MSPR3 BAC+3 ASRBD,
2025-2026). Le sujet : concevoir et industrialiser une base de données WMS
(Warehouse Management System) pour un client fictif, NordTransit Logistics
(NTL), PME logistique des Hauts-de-France.

Le SGBD cible est MariaDB 11.4 LTS. Contraintes critiques : RTO 1h, RPO 15 min.
Équipe de 4 personnes, 19h chacun.

ÉTAT D'AVANCEMENT
- MCD V4 officiel à 8 entités : validé, verrouillé.
- MLD V1 : draft, validé conceptuellement.
- DDL V1 : exécuté avec succès sur MariaDB 11.4.10, 8 tests fonctionnels OK.
- Reste à faire : justification SGBD, HA/PRA Galera, sécurité, supervision,
  logs, RunBook exploitation, pilotage projet, note CODIR, soutenance.

DÉCISIONS VERROUILLÉES (ne pas rouvrir, propose des workarounds MLD/DDL
si tu vois une incohérence, mais ne reviens pas sur le MCD)
1. Périmètre : 8 entités (CLIENT, ARTICLE, FOURNISSEUR, SITE, EMPLACEMENT,
   STOCK, MOUVEMENT, UTILISATEUR). Modèle complet à 14 entités (lots, FEFO,
   commandes, expéditions, transporteurs) reporté en V2.
2. Multi-tenant : option D — FK composite (id_article, id_client) depuis
   stocks et mouvements vers articles(id_article, id_client). Association
   `realise_pour` aussi visible au MCD pour rendre la séparation explicite.
3. TRANSFERT intra-site : garanti déclarativement par dénormalisation
   mouvements.id_site + FK composites (id_depart, id_site) et
   (id_arrivee, id_site) vers emplacements(id_emplacement, id_site).
4. Surrogate keys id_* partout au MLD, code métier MCD conservé en UNIQUE.
5. ENUM natif MariaDB pour les 4 domaines de valeurs (status, role,
   type_emplacement, type_mouvement). Tables de référence reportées V2.
6. Triggers minimisés. EXCEPTION : ck_mvt_src_dst (règle XOR sur mouvements)
   porté par 2 triggers BEFORE INSERT / BEFORE UPDATE car bug parser
   MariaDB 11.4 rejette tout CHECK qui référence id_depart/id_arrivee
   en présence des FK composites (voir wms-ddl.md §5.bis).
7. FK toutes en ON DELETE RESTRICT (protection historique).
   Exception articles.id_fournisseur en SET NULL.

STYLE ATTENDU
- Réponses en français, code et identifiants SQL en anglais.
- Concision, droit au but, tableaux quand pertinent.
- Anti-sycophancy : pas de flatterie, pas d'agreement gratuit.
- Si une demande est incohérente avec une décision verrouillée, dis-le
  et propose une alternative au niveau MLD/DDL ou aval, pas au niveau MCD.
- Quand tu écris du SQL : MariaDB 11.4, InnoDB, utf8mb4, contraintes
  nommées (pk_/uk_/fk_/ck_/ix_).

FICHIERS JOINTS À LA CONVERSATION (lis-les avant de répondre)
- sujet-mspr3.pdf : cahier des charges officiel EPSI
- wms-mcd.md : modèle conceptuel V4 (entités, associations, règles,
  domaines de valeurs)
- wms-mld.md : modèle logique V1 (tables, FK simples et composites,
  CHECK, index)
- wms-ddl.md : choix techniques DDL + investigation bug parser MariaDB
- wms-schema.sql : script DDL exécutable (8 CREATE TABLE + 2 triggers
  + index)

Premier réflexe avant chaque réponse : vérifie que ta proposition est
cohérente avec les décisions verrouillées ci-dessus. Si tu hésites,
réfère-toi aux fichiers joints. Et pose une question si quelque chose
n'est pas clair plutôt que d'inventer.
```

---

## Fichiers à joindre en pièces jointes

Selon la plateforme (Claude Desktop, ChatGPT, Gemini…), upload ces fichiers en pièces jointes du premier message :

### Pack minimal (5 fichiers, ~80 ko, suffisant pour 90% des questions)

| Fichier | Pourquoi |
|---|---|
| `ressources/sujet-mspr3.pdf` | Cahier des charges officiel — l'IA doit savoir ce qui est demandé par EPSI |
| `wms-mcd.md` | Modèle conceptuel V4, règles métier, domaines de valeurs |
| `wms-mld.md` | Modèle logique V1, contraintes, mapping MCD→MLD |
| `ddl/wms-schema.sql` | Le code SQL réel exécutable |
| `wms-ddl.md` | Choix techniques + investigation bug parser MariaDB 11.4 |

### Pack étendu (à joindre uniquement si discussion approfondie)

| Fichier | Pourquoi |
|---|---|
| `wms-mcd.png` | Diagramme MCD visuel (utile si IA multimodale) |
| `convergence/arbitrages-v4-ianis.md` | Historique des 5 arbitrages V4 — utile pour comprendre POURQUOI tel choix |
| `FAQ.md` | 17 Q/R prêtes pour soutenance — utile si l'IA doit anticiper attaques jury |
| `EQUIPE.md` | État livrables restants, qui fait quoi |

---

## Astuce d'usage

- Si la conv part en live et que l'IA propose un truc bizarre → renvoie-la vers `wms-mcd.md §1` (décisions intégrées) ou `wms-ddl.md §5.bis` (le bug parser, qui revient souvent dans les questions).
- Si tu veux que l'IA produise du DDL : précise « MariaDB 11.4, attention au bug parser sur les CHECK référençant id_depart/id_arrivee de mouvements ».
- Si tu veux que l'IA produise une justification soutenance : précise « format FAQ.md du repo, 2-3 lignes par Q/R avec référence fichier ».
