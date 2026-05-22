-- =====================================================================
-- WMS — Script DDL (V2 grossiste, 5 fixes MCD appliqués)
-- Voir ddl/wms-schema.sql pour la version annotée et documentée.
-- Charset : utf8mb4 / Moteur : InnoDB / Cible : MariaDB 11.4
-- =====================================================================

-- CREATE DATABASE gestion_stock;
-- USE gestion_stock;

-- 1. Table : UTILISATEUR
CREATE TABLE UTILISATEUR (
    id_utilisateur INT AUTO_INCREMENT,
    nom VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL,
    PRIMARY KEY (id_utilisateur)
) ENGINE=InnoDB;

-- 2. Table : CLIENT (FK → UTILISATEUR, association ECHANGER 1,1)
CREATE TABLE CLIENT (
    id_client INT AUTO_INCREMENT,
    nom VARCHAR(100) NOT NULL,
    siret VARCHAR(14),
    telephone VARCHAR(20),
    status VARCHAR(50),
    id_utilisateur INT NOT NULL,
    PRIMARY KEY (id_client),
    FOREIGN KEY (id_utilisateur) REFERENCES UTILISATEUR(id_utilisateur) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 3. Table : ARTICLE
CREATE TABLE ARTICLE (
    id_article INT AUTO_INCREMENT,
    nom VARCHAR(100) NOT NULL,
    poids DECIMAL(10,2),
    fournisseur VARCHAR(100),
    type VARCHAR(50),
    PRIMARY KEY (id_article)
) ENGINE=InnoDB;

-- 4. Table : COMMANDE (table associative CLIENT ↔ ARTICLE avec attributs)
CREATE TABLE COMMANDE (
    id_commande INT AUTO_INCREMENT,
    id_client INT NOT NULL,
    id_article INT NOT NULL,
    quantite_commandee INT NOT NULL,
    date_commande DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_commande),
    FOREIGN KEY (id_client) REFERENCES CLIENT(id_client) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_article) REFERENCES ARTICLE(id_article) ON DELETE RESTRICT ON UPDATE CASCADE,
    CHECK (quantite_commandee > 0)
) ENGINE=InnoDB;

-- 5. Table : SITE
CREATE TABLE SITE (
    id_site INT AUTO_INCREMENT,
    libelle VARCHAR(100) NOT NULL,
    adresse VARCHAR(255),
    PRIMARY KEY (id_site)
) ENGINE=InnoDB;

-- 6. Table : LOCALISATION (FK → SITE)
CREATE TABLE LOCALISATION (
    id_localisation INT AUTO_INCREMENT,
    code VARCHAR(50) NOT NULL,
    zone VARCHAR(50),
    allee VARCHAR(50),
    etage VARCHAR(50),
    place VARCHAR(50),
    id_site INT NOT NULL,
    PRIMARY KEY (id_localisation),
    FOREIGN KEY (id_site) REFERENCES SITE(id_site) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 7. Table : STOCK (V2 : FK → ARTICLE ajoutée, association CONTENIR_AS 1,1)
CREATE TABLE STOCK (
    id_stock INT AUTO_INCREMENT,
    quantite INT NOT NULL DEFAULT 0,
    id_article INT NOT NULL,
    id_localisation INT NOT NULL,
    PRIMARY KEY (id_stock),
    UNIQUE KEY uk_stock_article_localisation (id_article, id_localisation),
    FOREIGN KEY (id_article) REFERENCES ARTICLE(id_article) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_localisation) REFERENCES LOCALISATION(id_localisation) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 8. Table : MOUVEMENT (V2 : quantite + id_client ajoutées, id_stock devient NOT NULL)
CREATE TABLE MOUVEMENT (
    id_mouvement INT AUTO_INCREMENT,
    type VARCHAR(50) NOT NULL,
    reference VARCHAR(100),
    date DATE NOT NULL,
    heure TIME NOT NULL,
    quantite INT NOT NULL,
    id_stock INT NOT NULL,
    id_utilisateur INT NOT NULL,
    id_client INT NULL,
    PRIMARY KEY (id_mouvement),
    FOREIGN KEY (id_stock) REFERENCES STOCK(id_stock) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_utilisateur) REFERENCES UTILISATEUR(id_utilisateur) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_client) REFERENCES CLIENT(id_client) ON DELETE RESTRICT ON UPDATE CASCADE,
    CHECK (type IN ('entree','sortie','ajustement','transfert')),
    CHECK (quantite > 0)
) ENGINE=InnoDB;
