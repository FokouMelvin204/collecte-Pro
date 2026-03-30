-- Collecte Pro — schéma MySQL + données de test
-- Importer dans phpMyAdmin (création base + tables + jeux d’essai).

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP DATABASE IF EXISTS collectepro;
CREATE DATABASE collectepro CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE collectepro;

-- ——— Utilisateurs ———
CREATE TABLE utilisateurs (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nom VARCHAR(120) NOT NULL,
  email VARCHAR(180) NOT NULL UNIQUE,
  telephone VARCHAR(40) NOT NULL,
  mot_de_passe VARCHAR(255) NOT NULL,
  role ENUM('agent','client','administrateur') NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ——— Sessions API (jetons Bearer) ———
CREATE TABLE sessions (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  token VARCHAR(64) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_sessions_token (token),
  KEY idx_sessions_user (user_id),
  CONSTRAINT fk_sessions_user FOREIGN KEY (user_id) REFERENCES utilisateurs(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ——— Agents ———
CREATE TABLE agents (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  utilisateur_id INT UNSIGNED NOT NULL,
  code_affiliation VARCHAR(32) NOT NULL UNIQUE,
  taux_commission DECIMAL(5,2) NOT NULL DEFAULT 2.00,
  statut ENUM('actif','inactif') NOT NULL DEFAULT 'actif',
  CONSTRAINT fk_agents_user FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ——— Clients ———
CREATE TABLE clients (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  utilisateur_id INT UNSIGNED NOT NULL,
  agent_id INT UNSIGNED NOT NULL,
  statut_compte ENUM('en_attente','actif','rejete') NOT NULL DEFAULT 'en_attente',
  numero_compte VARCHAR(40) NOT NULL UNIQUE,
  cni_path VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_clients_user FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
  CONSTRAINT fk_clients_agent FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ——— Comptes ———
CREATE TABLE comptes (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  client_id INT UNSIGNED NOT NULL,
  solde DECIMAL(15,2) NOT NULL DEFAULT 0.00,
  date_creation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_comptes_client FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ——— Transactions ———
CREATE TABLE transactions (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  compte_id INT UNSIGNED NOT NULL,
  montant DECIMAL(15,2) NOT NULL,
  date DATETIME NOT NULL,
  statut ENUM('success','failed','pending') NOT NULL,
  type_paiement VARCHAR(50) NOT NULL,
  CONSTRAINT fk_trans_compte FOREIGN KEY (compte_id) REFERENCES comptes(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ——— Commissions ———
CREATE TABLE commissions (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  agent_id INT UNSIGNED NOT NULL,
  transaction_id INT UNSIGNED NOT NULL,
  montant DECIMAL(15,2) NOT NULL,
  date DATETIME NOT NULL,
  CONSTRAINT fk_comm_agent FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE,
  CONSTRAINT fk_comm_trans FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ——— Rapports ———
CREATE TABLE rapports (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  admin_id INT UNSIGNED NOT NULL,
  date_generation DATETIME NOT NULL,
  type_rapport VARCHAR(50) NOT NULL,
  montant_total DECIMAL(15,2) NOT NULL,
  CONSTRAINT fk_rapports_admin FOREIGN KEY (admin_id) REFERENCES utilisateurs(id) ON DELETE CASCADE
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;

-- Mots de passe : bcrypt (compatibles PHP password_verify)
-- admin@express.cm → Admin1234
-- agent*@express.cm → Agent1234
-- client*@express.cm → Client1234

INSERT INTO utilisateurs (id, nom, email, telephone, mot_de_passe, role, created_at) VALUES
(1, 'Admin Express', 'admin@express.cm', '+237600000001', '$2a$10$nZt1uXiFpASfrJGdu1a4W.zMZqgjIq2jcp44EhwtmcL1xy12f4UOW', 'administrateur', NOW()),
(2, 'Nkoulou Jean', 'agent1@express.cm', '+237600000002', '$2a$10$08qZXPjqoVH9r91EjykO5OMZUX46LgCamdGAwR5QgSlSxoz4OfqD6', 'agent', NOW()),
(3, 'Mbarga Marie', 'agent2@express.cm', '+237600000003', '$2a$10$08qZXPjqoVH9r91EjykO5OMZUX46LgCamdGAwR5QgSlSxoz4OfqD6', 'agent', NOW()),
(4, 'Client En Attente', 'client1@express.cm', '+237600000004', '$2a$10$bWG.KXT6AhJfLS8CAhrMFOaBJqSJ15Uys0QjFvKrPT1lUF77mNLke', 'client', NOW()),
(5, 'Client Actif', 'client2@express.cm', '+237600000005', '$2a$10$bWG.KXT6AhJfLS8CAhrMFOaBJqSJ15Uys0QjFvKrPT1lUF77mNLke', 'client', NOW()),
(6, 'Client Rejeté', 'client3@express.cm', '+237600000006', '$2a$10$bWG.KXT6AhJfLS8CAhrMFOaBJqSJ15Uys0QjFvKrPT1lUF77mNLke', 'client', NOW());

INSERT INTO agents (id, utilisateur_id, code_affiliation, taux_commission, statut) VALUES
(1, 2, 'EE-AKWA-001', 2.00, 'actif'),
(2, 3, 'EE-AKWA-002', 2.00, 'actif');

INSERT INTO clients (id, utilisateur_id, agent_id, statut_compte, numero_compte, cni_path, created_at) VALUES
(1, 4, 1, 'en_attente', 'CP-2026-0001', NULL, NOW()),
(2, 5, 1, 'actif', 'CP-2026-0002', 'uploads/cni/demo_cni.jpg', NOW()),
(3, 6, 2, 'rejete', 'CP-2026-0003', NULL, NOW());

INSERT INTO comptes (id, client_id, solde, date_creation) VALUES
(1, 1, 0.00, NOW()),
(2, 2, 15000.50, NOW()),
(3, 3, 0.00, NOW());

INSERT INTO transactions (id, compte_id, montant, date, statut, type_paiement) VALUES
(1, 2, 10000.00, DATE_SUB(NOW(), INTERVAL 2 DAY), 'success', 'mobile_money'),
(2, 2, 5000.00, DATE_SUB(NOW(), INTERVAL 1 DAY), 'pending', 'especes'),
(3, 2, 500.00, DATE_SUB(NOW(), INTERVAL 1 DAY), 'failed', 'carte'),
(4, 1, 2000.00, DATE_SUB(NOW(), INTERVAL 3 HOUR), 'success', 'mobile_money'),
(5, 3, 8000.00, DATE_SUB(NOW(), INTERVAL 1 HOUR), 'success', 'virement');

-- Commissions = 2 % du montant des transactions en succès
INSERT INTO commissions (id, agent_id, transaction_id, montant, date) VALUES
(1, 1, 1, 200.00, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(2, 1, 4, 40.00, DATE_SUB(NOW(), INTERVAL 3 HOUR)),
(3, 2, 5, 160.00, DATE_SUB(NOW(), INTERVAL 1 HOUR));

INSERT INTO rapports (id, admin_id, date_generation, type_rapport, montant_total) VALUES
(1, 1, NOW(), 'mensuel', 45000.00);
