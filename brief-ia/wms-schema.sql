-- =============================================================================
-- WMS-DB — schéma DDL MariaDB 11.4 LTS
-- Source : wms-mld.md V1
-- Convention nommage : pk_/uk_/fk_/ck_/ix_ + nom de table + colonnes
-- Charset : utf8mb4 / utf8mb4_unicode_ci
-- Moteur  : InnoDB (transactionnel, FK, Galera-ready)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Database
-- -----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS wms
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE wms;

-- -----------------------------------------------------------------------------
-- 1. clients
-- -----------------------------------------------------------------------------
CREATE TABLE clients (
  id_client       INT UNSIGNED NOT NULL AUTO_INCREMENT,
  code_client     VARCHAR(20)  NOT NULL,
  raison_sociale  VARCHAR(150) NOT NULL,
  siret           CHAR(14)     NOT NULL,
  contact_nom     VARCHAR(100) NULL,
  contact_email   VARCHAR(150) NULL,
  adresse         VARCHAR(255) NULL,
  status          ENUM('actif','suspendu','resilie') NOT NULL DEFAULT 'actif',
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT pk_clients PRIMARY KEY (id_client),
  CONSTRAINT uk_clients_code  UNIQUE (code_client),
  CONSTRAINT uk_clients_siret UNIQUE (siret)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 2. fournisseurs
-- -----------------------------------------------------------------------------
CREATE TABLE fournisseurs (
  id_fournisseur    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  code_fournisseur  VARCHAR(20)  NOT NULL,
  raison_sociale    VARCHAR(150) NOT NULL,
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT pk_fournisseurs PRIMARY KEY (id_fournisseur),
  CONSTRAINT uk_fournisseurs_code UNIQUE (code_fournisseur)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 3. sites
-- -----------------------------------------------------------------------------
CREATE TABLE sites (
  id_site     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  code_site   VARCHAR(20)  NOT NULL,
  nom         VARCHAR(100) NOT NULL,
  adresse     VARCHAR(255) NOT NULL,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT pk_sites PRIMARY KEY (id_site),
  CONSTRAINT uk_sites_code UNIQUE (code_site)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 4. utilisateurs
-- -----------------------------------------------------------------------------
CREATE TABLE utilisateurs (
  id_utilisateur  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  login           VARCHAR(50)  NOT NULL,
  nom             VARCHAR(100) NOT NULL,
  prenom          VARCHAR(100) NOT NULL,
  role            ENUM('operateur','cariste','admin') NOT NULL,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT pk_utilisateurs PRIMARY KEY (id_utilisateur),
  CONSTRAINT uk_utilisateurs_login UNIQUE (login)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 5. articles
--    Note : UNIQUE (id_article, id_client) sert de cible aux FK composites
--           option D depuis stocks et mouvements.
-- -----------------------------------------------------------------------------
CREATE TABLE articles (
  id_article      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_client       INT UNSIGNED NOT NULL,
  id_fournisseur  INT UNSIGNED NULL,
  reference       VARCHAR(50)  NOT NULL,
  libelle         VARCHAR(200) NOT NULL,
  poids           DECIMAL(10,3) NULL,
  longueur        DECIMAL(8,2)  NULL,
  largeur         DECIMAL(8,2)  NULL,
  hauteur         DECIMAL(8,2)  NULL,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT pk_articles PRIMARY KEY (id_article),
  CONSTRAINT uk_articles_client_ref UNIQUE (id_client, reference),
  CONSTRAINT uk_articles_id_client  UNIQUE (id_article, id_client),
  CONSTRAINT fk_articles_client
    FOREIGN KEY (id_client) REFERENCES clients (id_client)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_articles_fournisseur
    FOREIGN KEY (id_fournisseur) REFERENCES fournisseurs (id_fournisseur)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 6. emplacements
--    Note : UNIQUE (id_emplacement, id_site) sert de cible aux FK composites
--           TRANSFERT intra-site depuis mouvements.
-- -----------------------------------------------------------------------------
CREATE TABLE emplacements (
  id_emplacement    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_site           INT UNSIGNED NOT NULL,
  code              VARCHAR(30)  NOT NULL,
  zone              VARCHAR(20)  NULL,
  allee             VARCHAR(20)  NULL,
  etagere           VARCHAR(20)  NULL,
  niveau            VARCHAR(20)  NULL,
  type_emplacement  ENUM('rack','picking','masse','quai') NOT NULL,
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT pk_emplacements PRIMARY KEY (id_emplacement),
  CONSTRAINT uk_emplacements_site_code UNIQUE (id_site, code),
  CONSTRAINT uk_emplacements_id_site   UNIQUE (id_emplacement, id_site),
  CONSTRAINT fk_emplacements_site
    FOREIGN KEY (id_site) REFERENCES sites (id_site)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 7. stocks
--    FK composite option D : (id_article, id_client) → articles
--    UNIQUE (id_article, id_emplacement) : unicité métier obligatoire.
-- -----------------------------------------------------------------------------
CREATE TABLE stocks (
  id_stock        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_article      INT UNSIGNED NOT NULL,
  id_client       INT UNSIGNED NOT NULL,
  id_emplacement  INT UNSIGNED NOT NULL,
  quantite        INT NOT NULL DEFAULT 0,
  date_maj        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT pk_stocks PRIMARY KEY (id_stock),
  CONSTRAINT uk_stocks_article_emplacement UNIQUE (id_article, id_emplacement),
  CONSTRAINT fk_stocks_article_client
    FOREIGN KEY (id_article, id_client) REFERENCES articles (id_article, id_client)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_stocks_emplacement
    FOREIGN KEY (id_emplacement) REFERENCES emplacements (id_emplacement)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT ck_stocks_quantite CHECK (quantite >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 8. mouvements
--    - FK composite option D : (id_article, id_client) → articles
--    - FK composites TRANSFERT intra-site :
--        (id_depart,  id_site) → emplacements (id_emplacement, id_site)
--        (id_arrivee, id_site) → emplacements (id_emplacement, id_site)
--    - CHECK ck_mvt_src_dst : XOR conditionnel selon type_mouvement,
--      ajouté via ALTER TABLE après création (workaround bug parser MariaDB 11.4)
-- -----------------------------------------------------------------------------
CREATE TABLE mouvements (
  id_mouvement    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  numero_mvt      VARCHAR(30) NOT NULL,
  type_mouvement  ENUM('ENTREE','SORTIE','TRANSFERT','AJUSTEMENT') NOT NULL,
  id_article      INT UNSIGNED NOT NULL,
  id_client       INT UNSIGNED NOT NULL,
  id_site         INT UNSIGNED NOT NULL,
  id_depart       INT UNSIGNED NULL,
  id_arrivee      INT UNSIGNED NULL,
  id_utilisateur  INT UNSIGNED NOT NULL,
  quantite        INT NOT NULL,
  date_mouvement  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT pk_mouvements PRIMARY KEY (id_mouvement),
  CONSTRAINT uk_mouvements_numero UNIQUE (numero_mvt),
  CONSTRAINT fk_mouvements_article_client
    FOREIGN KEY (id_article, id_client) REFERENCES articles (id_article, id_client)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_mouvements_site
    FOREIGN KEY (id_site) REFERENCES sites (id_site)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_mouvements_depart_site
    FOREIGN KEY (id_depart, id_site) REFERENCES emplacements (id_emplacement, id_site)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_mouvements_arrivee_site
    FOREIGN KEY (id_arrivee, id_site) REFERENCES emplacements (id_emplacement, id_site)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_mouvements_utilisateur
    FOREIGN KEY (id_utilisateur) REFERENCES utilisateurs (id_utilisateur)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT ck_mouvements_quantite CHECK (quantite > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- Règle XOR ck_mvt_src_dst portée par 2 triggers (BEFORE INSERT + BEFORE UPDATE)
--
-- Bug parser MariaDB 11.4.10 confirmé : tout CHECK référençant id_depart ou
-- id_arrivee sur la table mouvements est rejeté avec ERROR 1901 dès lors
-- que les FK composites (id_depart, id_site) → emplacements et
-- (id_arrivee, id_site) → emplacements sont déclarées. Les FK composites
-- étant critiques pour la garantie déclarative TRANSFERT intra-site
-- (décision V4 verrouillée), on porte la règle XOR via triggers SIGNAL.
--
-- Sémantique identique au CHECK initialement prévu :
--   ENTREE     → id_depart NULL, id_arrivee NOT NULL
--   SORTIE     → id_depart NOT NULL, id_arrivee NULL
--   TRANSFERT  → les deux NOT NULL, distincts (intra-site garanti par FK)
--   AJUSTEMENT → XOR (exactement un des deux)
-- -----------------------------------------------------------------------------
DELIMITER //

CREATE TRIGGER tg_mvt_src_dst_ins
BEFORE INSERT ON mouvements
FOR EACH ROW
BEGIN
  IF NOT (
       (NEW.type_mouvement = 'ENTREE'
          AND NEW.id_depart IS NULL AND NEW.id_arrivee IS NOT NULL)
    OR (NEW.type_mouvement = 'SORTIE'
          AND NEW.id_depart IS NOT NULL AND NEW.id_arrivee IS NULL)
    OR (NEW.type_mouvement = 'TRANSFERT'
          AND NEW.id_depart IS NOT NULL AND NEW.id_arrivee IS NOT NULL
          AND NEW.id_depart <> NEW.id_arrivee)
    OR (NEW.type_mouvement = 'AJUSTEMENT'
          AND ((NEW.id_depart IS NOT NULL AND NEW.id_arrivee IS NULL)
            OR (NEW.id_depart IS NULL     AND NEW.id_arrivee IS NOT NULL)))
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'ck_mvt_src_dst: id_depart/id_arrivee invalides pour ce type_mouvement';
  END IF;
END//

CREATE TRIGGER tg_mvt_src_dst_upd
BEFORE UPDATE ON mouvements
FOR EACH ROW
BEGIN
  IF NOT (
       (NEW.type_mouvement = 'ENTREE'
          AND NEW.id_depart IS NULL AND NEW.id_arrivee IS NOT NULL)
    OR (NEW.type_mouvement = 'SORTIE'
          AND NEW.id_depart IS NOT NULL AND NEW.id_arrivee IS NULL)
    OR (NEW.type_mouvement = 'TRANSFERT'
          AND NEW.id_depart IS NOT NULL AND NEW.id_arrivee IS NOT NULL
          AND NEW.id_depart <> NEW.id_arrivee)
    OR (NEW.type_mouvement = 'AJUSTEMENT'
          AND ((NEW.id_depart IS NOT NULL AND NEW.id_arrivee IS NULL)
            OR (NEW.id_depart IS NULL     AND NEW.id_arrivee IS NOT NULL)))
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'ck_mvt_src_dst: id_depart/id_arrivee invalides pour ce type_mouvement';
  END IF;
END//

DELIMITER ;

-- =============================================================================
-- Index additionnels (reporting / audit) — cf. wms-mld.md §7
-- Les index sur PK et FK sont créés automatiquement par InnoDB,
-- ne sont pas redéclarés ici.
-- =============================================================================

CREATE INDEX ix_articles_client_libelle
  ON articles (id_client, libelle);

CREATE INDEX ix_stocks_client_emplacement
  ON stocks (id_client, id_emplacement);

CREATE INDEX ix_mouvements_client_date
  ON mouvements (id_client, date_mouvement DESC);

CREATE INDEX ix_mouvements_site_date
  ON mouvements (id_site, date_mouvement DESC);

CREATE INDEX ix_mouvements_type_date
  ON mouvements (type_mouvement, date_mouvement DESC);

CREATE INDEX ix_mouvements_article_date
  ON mouvements (id_article, date_mouvement DESC);

CREATE INDEX ix_mouvements_utilisateur_date
  ON mouvements (id_utilisateur, date_mouvement DESC);
