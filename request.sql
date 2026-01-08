--I. Requêtes de base et Agrégations (Maitrise des données)

--Nombre de véhicules par type d'énergie (Utile pour le suivi de la flotte):


SELECT energie, COUNT(*) AS nombre_vehicules 
FROM Vehicule 
GROUP BY energie;





--Chiffre d'affaires total par mode de paiement:

SELECT mode_paiement, SUM(montant) AS total_recettes 
FROM Paiement 
GROUP BY mode_paiement;





--Moyenne d'autonomie des véhicules par marque:
SELECT marque, AVG(autonomie_km) AS autonomie_moyenne 
FROM Vehicule 
GROUP BY marque 
HAVING AVG(autonomie_km) > 200;





--Top 3 des clients ayant effectué le plus de réservations:
SELECT c.nom, c.prenom, COUNT(r.id_reservation) AS nb_locations
FROM Client c
JOIN Reservation r ON c.id_client = r.id_client
GROUP BY c.id_client
ORDER BY nb_locations DESC
LIMIT 3;





--Liste des bornes actuellement disponibles dans une station donnée:

SELECT s.nom_station, b.id_borne, b.type_prise
FROM Station s
JOIN Borne b ON s.id_station = b.id_station
WHERE b.etat_borne = 'Disponible' AND s.ville = 'Paris';






--II. Jointures Complexes et Sous-requêtes
--Véhicules n'ayant jamais fait l'objet d'une maintenance:

SELECT immatriculation, marque, modele 
FROM Vehicule 
WHERE id_vehicule NOT IN (SELECT DISTINCT id_vehicule FROM Maintenance WHERE id_vehicule IS NOT NULL);





--Détails des interventions de maintenance par technicien et type de matériel:
SELECT t.nom AS technicien, m.date_intervention, v.immatriculation AS vehicule, b.id_borne AS borne
FROM Maintenance m
JOIN Technicien t ON m.id_technicien = t.id_technicien
LEFT JOIN Vehicule v ON m.id_vehicule = v.id_vehicule
LEFT JOIN Borne b ON m.id_borne = b.id_borne;





--Clients ayant payé plus que la moyenne globale des paiements:
SELECT nom, prenom, email 
FROM Client 
WHERE id_client IN (
    SELECT id_client FROM Paiement WHERE montant > (SELECT AVG(montant) FROM Paiement)
);





--Nombre de bornes par station avec une sous-requête corrélée:
SELECT nom_station, 
       (SELECT COUNT(*) FROM Borne b WHERE b.id_station = s.id_station) AS total_bornes
FROM Station s;





--Trouver les véhicules réservés à une date spécifique:
SELECT v.marque, v.modele, r.date_debut
FROM Vehicule v
JOIN Reservation r ON v.id_vehicule = r.id_vehicule
WHERE r.date_debut::DATE = '2026-01-07';






--III.Vues et Simplification d'accès (Mission 3.4) 
--Vue du planning des réservations avec noms clients et véhicules 
CREATE VIEW vue_planning_complet AS
SELECT r.id_reservation, c.nom, c.prenom, v.immatriculation, r.date_debut, r.date_fin, r.statut
FROM Reservation r
JOIN Client c ON r.id_client = c.id_client
JOIN Vehicule v ON r.id_vehicule = v.id_vehicule;






--Vue pour le suivi technique (Matériel en panne) :
CREATE VIEW vue_materiel_en_panne AS
SELECT 'Vehicule' AS type, immatriculation AS ref, etat FROM Vehicule WHERE etat = 'En panne'
UNION
SELECT 'Borne' AS type, CAST(id_borne AS VARCHAR), etat_borne FROM Borne WHERE etat_borne = 'HS';





--IV.Fonctions et Procédures (Mission 3.6) 
--Fonction pour calculer le coût d'une location selon la durée :
CREATE OR REPLACE FUNCTION calculer_cout_location(id_res INT, tarif_horaire DECIMAL) 
RETURNS DECIMAL AS $$
DECLARE
    duree_heures INT;
BEGIN
    SELECT EXTRACT(HOUR FROM (date_fin - date_debut)) INTO duree_heures 
    FROM Reservation WHERE id_reservation = id_res;
    RETURN duree_heures * tarif_horaire;
END;
$$ LANGUAGE plpgsql;
--Appel de la fonction pour une réservation précise :
SELECT calculer_cout_location(1, 15.5);




--V. Triggers et Automatisation (Mission 3.5) 
--Trigger pour mettre le véhicule à 'Indisponible' lors d'une réservation :

CREATE OR REPLACE FUNCTION maj_statut_vehicule_reserve()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Vehicule SET etat = 'Loué' WHERE id_vehicule = NEW.id_vehicule;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_apres_reservation
AFTER INSERT ON Reservation
FOR EACH ROW EXECUTE FUNCTION maj_statut_vehicule_reserve();




--Trigger pour empêcher la suppression d'un client ayant des dettes :
CREATE OR REPLACE FUNCTION verif_suppression_client()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT SUM(montant) FROM Paiement WHERE id_client = OLD.id_client) < 0 THEN
        RAISE EXCEPTION 'Impossible de supprimer un client avec un solde négatif';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_avant_suppression_client
BEFORE DELETE ON Client
FOR EACH ROW EXECUTE FUNCTION verif_suppression_client();




--VI. Requêtes d'Analyse Avancée

--Taux d'occupation des bornes par station (en pourcentage):
SELECT s.nom_station, 
       ROUND(COUNT(CASE WHEN b.etat_borne = 'Occupé' THEN 1 END) * 100.0 / COUNT(b.id_borne), 2) AS taux_occupation
FROM Station s
JOIN Borne b ON s.id_station = b.id_station
GROUP BY s.nom_station;

--Répartition du chiffre d'affaires par mois:
SELECT TO_CHAR(date_paiement, 'YYYY-MM') AS mois, SUM(montant) AS CA_mensuel
FROM Paiement
GROUP BY mois
ORDER BY mois;

--Identification des techniciens n'ayant pas fait de maintenance ce mois-ci:
SELECT nom, prenom 
FROM Technicien
EXCEPT
SELECT t.nom, t.prenom
FROM Technicien t
JOIN Maintenance m ON t.id_technicien = m.id_technicien
WHERE m.date_intervention >= CURRENT_DATE - INTERVAL '1 month';

--Recherche plein texte sur les descriptions de maintenance:

SELECT id_maintenance, description 
FROM Maintenance 
WHERE description ILIKE '%batterie%' OR description ILIKE '%frein%';








