-- Script de création des tables pour le système de matchs
-- À exécuter sur votre base de données MySQL

-- Table pour les matchs
CREATE TABLE IF NOT EXISTS amicalclub_matches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    team_id INT NOT NULL,
    coach_id INT NOT NULL,
    date DATE NOT NULL,
    time TIME NOT NULL,
    location VARCHAR(255) NOT NULL,
    stadium VARCHAR(255) NULL,
    category VARCHAR(50) NOT NULL,
    level VARCHAR(50) NULL,
    gender VARCHAR(20) NULL,
    description TEXT NULL,
    notes TEXT NULL,
    auto_validation BOOLEAN DEFAULT FALSE,
    status ENUM('available', 'pending', 'confirmed', 'finished') DEFAULT 'available',
    confirmed_team_id INT NULL,
    home_score VARCHAR(10) NULL,
    away_score VARCHAR(10) NULL,
    home_scorers TEXT NULL,
    away_scorers TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (team_id) REFERENCES amicalclub_teams(id) ON DELETE CASCADE,
    FOREIGN KEY (coach_id) REFERENCES amicalclub_users(id) ON DELETE CASCADE,
    FOREIGN KEY (confirmed_team_id) REFERENCES amicalclub_teams(id) ON DELETE SET NULL,
    
    INDEX idx_date (date),
    INDEX idx_status (status),
    INDEX idx_coach (coach_id),
    INDEX idx_team (team_id)
);

-- Table pour les demandes de match
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

-- Ajouter la colonne logo à la table des équipes si elle n'existe pas
ALTER TABLE amicalclub_teams 
ADD COLUMN IF NOT EXISTS logo VARCHAR(255) NULL;

-- Ajouter la colonne avatar à la table des utilisateurs si elle n'existe pas
ALTER TABLE amicalclub_users 
ADD COLUMN IF NOT EXISTS avatar VARCHAR(255) NULL;
