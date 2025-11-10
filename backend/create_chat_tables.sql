-- Tables pour le système de chat

-- Table des conversations
CREATE TABLE IF NOT EXISTS amicalclub_conversations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user1_id INT NOT NULL,
    user2_id INT NOT NULL,
    last_message_id INT NULL,
    last_message_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user1_id) REFERENCES amicalclub_users(id) ON DELETE CASCADE,
    FOREIGN KEY (user2_id) REFERENCES amicalclub_users(id) ON DELETE CASCADE,
    FOREIGN KEY (last_message_id) REFERENCES amicalclub_messages(id) ON DELETE SET NULL,
    
    UNIQUE KEY unique_conversation (user1_id, user2_id),
    INDEX idx_user1 (user1_id),
    INDEX idx_user2 (user2_id),
    INDEX idx_last_message_at (last_message_at)
);

-- Table des messages
CREATE TABLE IF NOT EXISTS amicalclub_messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    conversation_id INT NOT NULL,
    sender_id INT NOT NULL,
    receiver_id INT NOT NULL,
    message TEXT NOT NULL,
    message_type ENUM('text', 'image', 'file') DEFAULT 'text',
    file_url VARCHAR(500) NULL,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (conversation_id) REFERENCES amicalclub_conversations(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES amicalclub_users(id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES amicalclub_users(id) ON DELETE CASCADE,
    
    INDEX idx_conversation (conversation_id),
    INDEX idx_sender (sender_id),
    INDEX idx_receiver (receiver_id),
    INDEX idx_created_at (created_at),
    INDEX idx_is_read (is_read)
);

-- Table des notifications de chat
CREATE TABLE IF NOT EXISTS amicalclub_chat_notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    conversation_id INT NOT NULL,
    message_id INT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES amicalclub_users(id) ON DELETE CASCADE,
    FOREIGN KEY (conversation_id) REFERENCES amicalclub_conversations(id) ON DELETE CASCADE,
    FOREIGN KEY (message_id) REFERENCES amicalclub_messages(id) ON DELETE CASCADE,
    
    INDEX idx_user (user_id),
    INDEX idx_conversation (conversation_id),
    INDEX idx_is_read (is_read)
);

-- Table des statuts de présence (optionnel)
CREATE TABLE IF NOT EXISTS amicalclub_user_presence (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    is_online BOOLEAN DEFAULT FALSE,
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('online', 'away', 'busy', 'offline') DEFAULT 'offline',
    
    FOREIGN KEY (user_id) REFERENCES amicalclub_users(id) ON DELETE CASCADE,
    
    INDEX idx_is_online (is_online),
    INDEX idx_last_seen (last_seen)
);
