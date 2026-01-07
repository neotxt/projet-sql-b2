-- 1. Création de la table Station
CREATE TABLE Station (
    id_station SERIAL PRIMARY KEY,
    nom_station VARCHAR(100) NOT NULL,
    adresse VARCHAR(255),
    ville VARCHAR(100)
);

-- 2. Création de la table Borne
CREATE TABLE Borne (
    id_borne SERIAL PRIMARY KEY,
    type_prise VARCHAR(50),
    etat_borne VARCHAR(50),
    id_station INT NOT NULL,
    CONSTRAINT fk_station FOREIGN KEY (id_station) REFERENCES Station(id_station)
);

-- 3. Création de la table Vehicule
CREATE TABLE Vehicule (
    id_vehicule SERIAL PRIMARY KEY,
    marque VARCHAR(50),
    modele VARCHAR(50),
    annee INT,
    energie VARCHAR(30),
    autonomie_km INT,
    immatriculation VARCHAR(20) UNIQUE,
    etat VARCHAR(50),
    id_borne INT,
    CONSTRAINT fk_borne FOREIGN KEY (id_borne) REFERENCES Borne(id_borne)
);

-- 4. Création de la table Technicien
CREATE TABLE Technicien (
    id_technicien SERIAL PRIMARY KEY,
    nom VARCHAR(50),
    prenom VARCHAR(50),
    email VARCHAR(100) UNIQUE,
    specialite VARCHAR(100)
);

-- 5. Création de la table Maintenance
CREATE TABLE Maintenance (
    id_maintenance SERIAL PRIMARY KEY,
    date_intervention DATE NOT NULL,
    description TEXT,
    statut VARCHAR(50),
    id_vehicule INT,
    id_borne INT,
    id_technicien INT,
    CONSTRAINT fk_vehicule_maint FOREIGN KEY (id_vehicule) REFERENCES Vehicule(id_vehicule),
    CONSTRAINT fk_borne_maint FOREIGN KEY (id_borne) REFERENCES Borne(id_borne),
    CONSTRAINT fk_technicien FOREIGN KEY (id_technicien) REFERENCES Technicien(id_technicien)
);

-- 6. Création de la table Paiement
CREATE TABLE Paiement (
    id_paiement SERIAL PRIMARY KEY,
    montant DECIMAL(10,2),
    date_paiement DATE,
    mode_paiement VARCHAR(50),
    id_client INT -- Sera lié après la création de Client
);

-- 7. Création de la table Client
CREATE TABLE Client (
    id_client SERIAL PRIMARY KEY,
    nom VARCHAR(50),
    prenom VARCHAR(50),
    email VARCHAR(100) UNIQUE,
    telephone VARCHAR(20),
    permis_numero VARCHAR(50),
    id_paiement INT,
    CONSTRAINT fk_paiement_client FOREIGN KEY (id_paiement) REFERENCES Paiement(id_paiement)
);

-- Ajout de la contrainte manquante pour Paiement vers Client
ALTER TABLE Paiement ADD CONSTRAINT fk_client_paiement FOREIGN KEY (id_client) REFERENCES Client(id_client);

-- 8. Création de la table Reservation
CREATE TABLE Reservation (
    id_reservation SERIAL PRIMARY KEY,
    date_debut TIMESTAMP NOT NULL,
    date_fin TIMESTAMP,
    statut VARCHAR(50),
    id_vehicule INT NOT NULL,
    id_client INT NOT NULL,
    CONSTRAINT fk_vehicule_res FOREIGN KEY (id_vehicule) REFERENCES Vehicule(id_vehicule),
    CONSTRAINT fk_client_res FOREIGN KEY (id_client) REFERENCES Client(id_client)
);