-- =====================================================================
-- WMS — Schéma DDL MariaDB 11.4
-- Version : 2.0 (2026-05-22) — MCD V2 grossiste, 5 fixes appliqués
-- Voir : ../mcd/wms-mcd.md  et  ../mld/wms-mld.md
-- Charset : utf8mb4 / collation utf8mb4_unicode_ci
-- Moteur : InnoDB (FK + transactions)
-- =====================================================================

SET FOREIGN_KEY_CHECKS = 0;

-- Ordre de DROP : tables dépendantes d'abord
DROP TABLE IF EXISTS commande;
DROP TABLE IF EXISTS mouvement;
DROP TABLE IF EXISTS stock;
DROP TABLE IF EXISTS article;
DROP TABLE IF EXISTS client;
DROP TABLE IF EXISTS utilisateur;
DROP TABLE IF EXISTS localisation;
DROP TABLE IF EXISTS site;
-- V2 : table article_stock supprimée (N-N → 1-N via stock.id_article)
DROP TABLE IF EXISTS article_stock;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
-- 1. SITE
-- =====================================================================
CREATE TABLE site (
    id_site     INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    libelle     VARCHAR(100)  NOT NULL,
    adresse     VARCHAR(255)  NOT NULL,
    PRIMARY KEY (id_site)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 2. LOCALISATION (FK → site)
-- =====================================================================
CREATE TABLE localisation (
    id_localisation INT UNSIGNED NOT NULL AUTO_INCREMENT,
    code            VARCHAR(30)  NOT NULL,
    zone            VARCHAR(30)  NOT NULL,
    allee           VARCHAR(10)  NOT NULL,
    etage           VARCHAR(10)  NOT NULL,
    place           VARCHAR(10)  NOT NULL,
    id_site         INT UNSIGNED NOT NULL,
    PRIMARY KEY (id_localisation),
    UNIQUE KEY uk_localisation_code (code),
    KEY idx_localisation_site (id_site),
    CONSTRAINT fk_localisation_site
        FOREIGN KEY (id_site) REFERENCES site(id_site)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 3. UTILISATEUR
-- =====================================================================
CREATE TABLE utilisateur (
    id_utilisateur INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nom            VARCHAR(100) NOT NULL,
    role           VARCHAR(30)  NOT NULL,
    PRIMARY KEY (id_utilisateur)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 4. CLIENT (FK → utilisateur, association ECHANGER)
-- =====================================================================
CREATE TABLE client (
    id_client      INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    nom            VARCHAR(100)  NOT NULL,
    siret          CHAR(14)      NOT NULL,
    telephone      VARCHAR(20)   NULL,
    status         VARCHAR(20)   NOT NULL DEFAULT 'actif',
    id_utilisateur INT UNSIGNED  NOT NULL,
    PRIMARY KEY (id_client),
    UNIQUE KEY uk_client_siret (siret),
    KEY idx_client_utilisateur (id_utilisateur),
    CONSTRAINT fk_client_utilisateur
        FOREIGN KEY (id_utilisateur) REFERENCES utilisateur(id_utilisateur)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 5. ARTICLE
-- =====================================================================
CREATE TABLE article (
    id_article  INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    nom         VARCHAR(150)   NOT NULL,
    poids       DECIMAL(10,3)  NOT NULL,
    fournisseur VARCHAR(100)   NULL,
    type        VARCHAR(50)    NOT NULL,
    PRIMARY KEY (id_article),
    CONSTRAINT ck_article_poids CHECK (poids > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 6. STOCK (FK → article ★ V2, → localisation)
-- V2 : 1 stock = 1 article × 1 emplacement × 1 quantité
-- =====================================================================
CREATE TABLE stock (
    id_stock        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    quantite        INT UNSIGNED NOT NULL DEFAULT 0,
    id_article      INT UNSIGNED NOT NULL,
    id_localisation INT UNSIGNED NOT NULL,
    PRIMARY KEY (id_stock),
    UNIQUE KEY uk_stock_article_localisation (id_article, id_localisation),
    KEY idx_stock_article (id_article),
    KEY idx_stock_localisation (id_localisation),
    CONSTRAINT fk_stock_article
        FOREIGN KEY (id_article) REFERENCES article(id_article)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_stock_localisation
        FOREIGN KEY (id_localisation) REFERENCES localisation(id_localisation)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 7. MOUVEMENT (FK → stock, utilisateur, client ★ V2)
-- V2 changements :
--   - quantite ajoutée (CHECK > 0)
--   - id_stock devient NOT NULL (cardinalité 1,1)
--   - id_client ajoutée nullable (association CONCERNE 0,1)
-- =====================================================================
CREATE TABLE mouvement (
    id_mouvement   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    type           VARCHAR(20)  NOT NULL,
    reference      VARCHAR(50)  NOT NULL,
    date           DATE         NOT NULL,
    heure          TIME         NOT NULL,
    quantite       INT UNSIGNED NOT NULL,
    id_stock       INT UNSIGNED NOT NULL,
    id_utilisateur INT UNSIGNED NOT NULL,
    id_client      INT UNSIGNED NULL,
    PRIMARY KEY (id_mouvement),
    UNIQUE KEY uk_mouvement_reference (reference),
    KEY idx_mouvement_date (date),
    KEY idx_mouvement_stock (id_stock),
    KEY idx_mouvement_utilisateur (id_utilisateur),
    KEY idx_mouvement_client (id_client),
    CONSTRAINT fk_mouvement_stock
        FOREIGN KEY (id_stock) REFERENCES stock(id_stock)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_mouvement_utilisateur
        FOREIGN KEY (id_utilisateur) REFERENCES utilisateur(id_utilisateur)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_mouvement_client
        FOREIGN KEY (id_client) REFERENCES client(id_client)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_mouvement_type CHECK (type IN ('entree','sortie','ajustement','transfert')),
    CONSTRAINT ck_mouvement_quantite CHECK (quantite > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 8. COMMANDE (table associative CLIENT ↔ ARTICLE)
-- =====================================================================
CREATE TABLE commande (
    id_commande        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_client          INT UNSIGNED NOT NULL,
    id_article         INT UNSIGNED NOT NULL,
    quantite_commandee INT UNSIGNED NOT NULL,
    date_commande      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_commande),
    KEY idx_commande_client (id_client),
    KEY idx_commande_article (id_article),
    CONSTRAINT fk_commande_client
        FOREIGN KEY (id_client) REFERENCES client(id_client)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_commande_article
        FOREIGN KEY (id_article) REFERENCES article(id_article)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_commande_quantite CHECK (quantite_commandee > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- Fin du script — 8 tables (V2 : article_stock supprimée)
-- =====================================================================
