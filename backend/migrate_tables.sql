-- Script de migration pour ajouter les colonnes manquantes
-- À exécuter sur votre base de données MySQL

-- Vérifier et ajouter les colonnes manquantes à amicalclub_matches
ALTER TABLE amicalclub_matches 
ADD COLUMN IF NOT EXISTS status ENUM('available', 'pending', 'confirmed', 'finished') DEFAULT 'available';

ALTER TABLE amicalclub_matches 
ADD COLUMN IF NOT EXISTS auto_validation BOOLEAN DEFAULT FALSE;

ALTER TABLE amicalclub_matches 
ADD COLUMN IF NOT EXISTS confirmed_team_id INT NULL;

ALTER TABLE amicalclub_matches 
ADD COLUMN IF NOT EXISTS home_score VARCHAR(10) NULL;

ALTER TABLE amicalclub_matches 
ADD COLUMN IF NOT EXISTS away_score VARCHAR(10) NULL;

ALTER TABLE amicalclub_matches 
ADD COLUMN IF NOT EXISTS home_scorers TEXT NULL;

ALTER TABLE amicalclub_matches 
ADD COLUMN IF NOT EXISTS away_scorers TEXT NULL;

ALTER TABLE amicalclub_matches 
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE amicalclub_matches 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

-- Créer la table match_requests si elle n'existe pas
CREATE TABLE IF NOT EXISTS amicalclub_match_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    match_id INT NOT NULL,
    requesting_team_id INT NOT NULL,
    message TEXT NULL,
    status ENUM('pending', 'accepted', 'rejected') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    responded_at TIMESTAMP NULL,
    
    FOREIGN KEY (match_id) REFERENCES amicalclub_matches(id) ON DELETE CASCADE,
    FOREIGN KEY (requesting_team_id) REFERENCES amicalclub_teams(id) ON DELETE CASCADE,
    
    UNIQUE KEY unique_request (match_id, requesting_team_id),
    INDEX idx_match (match_id),
    INDEX idx_status (status),
    INDEX idx_team (requesting_team_id)
);

-- Ajouter les colonnes logo et avatar si elles n'existent pas
ALTER TABLE amicalclub_teams 
ADD COLUMN IF NOT EXISTS logo VARCHAR(255) NULL;

ALTER TABLE amicalclub_users 
ADD COLUMN IF NOT EXISTS avatar VARCHAR(255) NULL;
