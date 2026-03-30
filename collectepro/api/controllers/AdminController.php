<?php
declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/auth_middleware.php';

/**
 * Administration : validation clients, gestion agents, rapports.
 */
class AdminController
{
    private PDO $pdo;

    public function __construct()
    {
        $this->pdo = getPdo();
    }

    private function fail(int $code, string $msg): void
    {
        http_response_code($code);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(['success' => false, 'message' => $msg], JSON_UNESCAPED_UNICODE);
        exit;
    }

    private function requireAdmin(): int
    {
        $userId = validateToken($this->pdo);
        if (!$userId) {
            $this->fail(401, 'Token invalide ou manquant');
        }

        $stmt = $this->pdo->prepare('SELECT role FROM utilisateurs WHERE id = ? LIMIT 1');
        $stmt->execute([$userId]);
        $role = $stmt->fetchColumn();

        if ($role !== 'administrateur') {
            $this->fail(403, 'Accès réservé aux administrateurs');
        }

        return (int) $userId;
    }

    /**
     * Dashboard : Statistiques globales
     */
    public function dashboard(): void
    {
        $this->requireAdmin();

        // Total collecté global
        $totalCollecte = (float) $this->pdo->query(
            "SELECT COALESCE(SUM(montant), 0) FROM transactions WHERE statut = 'success'"
        )->fetchColumn();

        // Total agents
        $totalAgents = (int) $this->pdo->query("SELECT COUNT(*) FROM agents")->fetchColumn();

        // Total clients
        $totalClients = (int) $this->pdo->query("SELECT COUNT(*) FROM clients")->fetchColumn();

        // Clients en attente
        $clientsEnAttente = (int) $this->pdo->query(
            "SELECT COUNT(*) FROM clients WHERE statut_compte = 'en_attente'"
        )->fetchColumn();

        // Total commissions
        $totalCommissions = (float) $this->pdo->query(
            "SELECT COALESCE(SUM(montant), 0) FROM commissions"
        )->fetchColumn();

        // Collecte par agent
        $stmt = $this->pdo->query(
            "SELECT u.nom as agent_nom, a.code_affiliation as code, 
                    COALESCE(SUM(t.montant), 0) as total,
                    COUNT(DISTINCT cl.id) as nb_clients
             FROM agents a
             JOIN utilisateurs u ON a.utilisateur_id = u.id
             LEFT JOIN clients cl ON cl.agent_id = a.id
             LEFT JOIN comptes co ON co.client_id = cl.id
             LEFT JOIN transactions t ON t.compte_id = co.id AND t.statut = 'success'
             GROUP BY a.id
             ORDER BY total DESC"
        );
        $collecteParAgent = $stmt->fetchAll(PDO::FETCH_ASSOC);

        header('Content-Type: application/json; charset=utf-8');
        echo json_encode([
            'success' => true,
            'data' => [
                'total_collecte_global' => $totalCollecte,
                'total_agents' => $totalAgents,
                'total_clients' => $totalClients,
                'total_clients_en_attente' => $clientsEnAttente,
                'total_commissions' => $totalCommissions,
                'collecte_par_agent' => array_map(fn($row) => [
                    'agent_nom' => $row['agent_nom'],
                    'code' => $row['code'],
                    'total' => floatval($row['total']),
                    'nb_clients' => (int) $row['nb_clients']
                ], $collecteParAgent)
            ]
        ], JSON_UNESCAPED_UNICODE);
    }

    /**
     * Liste des clients en attente de validation
     */
    public function clientsAttente(): void
    {
        $this->requireAdmin();

        $stmt = $this->pdo->query(
            "SELECT cl.id, u.nom, u.email, u.telephone, cl.created_at as date_inscription, 
                    cl.cni_path, ag_u.nom as agent_nom, a.code_affiliation
             FROM clients cl
             JOIN utilisateurs u ON cl.utilisateur_id = u.id
             JOIN agents a ON cl.agent_id = a.id
             JOIN utilisateurs ag_u ON a.utilisateur_id = ag_u.id
             WHERE cl.statut_compte = 'en_attente'
             ORDER BY cl.created_at DESC"
        );
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        header('Content-Type: application/json; charset=utf-8');
        echo json_encode([
            'success' => true,
            'data' => array_map(fn($r) => [
                'id' => (int) $r['id'],
                'nom' => $r['nom'],
                'email' => $r['email'],
                'telephone' => $r['telephone'],
                'agent_nom' => $r['agent_nom'],
                'code_affiliation' => $r['code_affiliation'],
                'date_inscription' => $r['date_inscription'],
                'cni_path' => $r['cni_path']
            ], $rows)
        ], JSON_UNESCAPED_UNICODE);
    }

    /**
     * Valider un client
     */
    public function validerClient(int $id): void
    {
        $this->requireAdmin();

        try {
            $this->pdo->beginTransaction();

            // 1. Générer le numéro de compte
            $annee = date('Y');
            $numeroCompte = "CPT-" . $annee . "-" . str_pad((string)$id, 4, '0', STR_PAD_LEFT);

            // 2. Changer le statut ET mettre à jour le numéro de compte en table 'clients'
            $stmt = $this->pdo->prepare("UPDATE clients SET statut_compte = 'actif', numero_compte = ? WHERE id = ?");
            $stmt->execute([$numeroCompte, $id]);

            if ($stmt->rowCount() === 0) {
                // On vérifie si le client existe déjà ou est déjà actif
                $check = $this->pdo->prepare("SELECT statut_compte FROM clients WHERE id = ?");
                $check->execute([$id]);
                $statut = $check->fetchColumn();
                if (!$statut) {
                    throw new Exception("Client ID $id introuvable");
                }
                if ($statut === 'actif') {
                    // Déjà actif, on peut continuer pour s'assurer que le compte existe en table 'comptes'
                } else {
                    throw new Exception("Échec de la mise à jour du statut (Statut actuel: $statut)");
                }
            }

            // 3. Créer l'entrée en table 'comptes' (si elle n'existe pas)
            $stmt = $this->pdo->prepare("SELECT id FROM comptes WHERE client_id = ?");
            $stmt->execute([$id]);
            if (!$stmt->fetch()) {
                $stmt = $this->pdo->prepare(
                    "INSERT INTO comptes (client_id, solde, date_creation) VALUES (?, 0, NOW())"
                );
                $stmt->execute([$id]);
            }

            $this->pdo->commit();

            header('Content-Type: application/json; charset=utf-8');
            echo json_encode([
                'success' => true,
                'message' => 'Client validé avec succès',
                'numero_compte' => $numeroCompte
            ], JSON_UNESCAPED_UNICODE);

        } catch (Exception $e) {
            if ($this->pdo->inTransaction()) {
                $this->pdo->rollBack();
            }
            $this->fail(500, "Erreur validation (ID $id) : " . $e->getMessage());
        }
    }

    /**
     * Rejeter un client
     */
    public function rejeterClient(int $id): void
    {
        $this->requireAdmin();

        $stmt = $this->pdo->prepare("UPDATE clients SET statut_compte = 'rejete' WHERE id = ?");
        $stmt->execute([$id]);

        header('Content-Type: application/json; charset=utf-8');
        echo json_encode([
            'success' => true,
            'message' => 'Client rejeté'
        ], JSON_UNESCAPED_UNICODE);
    }

    /**
     * Liste de tous les agents avec leurs statistiques
     */
    public function agents(): void
    {
        $this->requireAdmin();

        $stmt = $this->pdo->query(
            "SELECT u.id, u.nom, u.email, u.telephone, a.code_affiliation, 
                    a.taux_commission, a.statut,
                    COUNT(DISTINCT cl.id) as nb_clients,
                    COALESCE(SUM(t.montant), 0) as total_collecte,
                    COALESCE(SUM(comm.montant), 0) as total_commissions
             FROM agents a
             JOIN utilisateurs u ON a.utilisateur_id = u.id
             LEFT JOIN clients cl ON cl.agent_id = a.id
             LEFT JOIN comptes co ON co.client_id = cl.id
             LEFT JOIN transactions t ON t.compte_id = co.id AND t.statut = 'success'
             LEFT JOIN commissions comm ON comm.agent_id = a.id
             GROUP BY a.id
             ORDER BY u.nom ASC"
        );
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        header('Content-Type: application/json; charset=utf-8');
        echo json_encode([
            'success' => true,
            'data' => array_map(fn($r) => [
                'id' => (int) $r['id'],
                'nom' => $r['nom'],
                'email' => $r['email'],
                'telephone' => $r['telephone'],
                'code_affiliation' => $r['code_affiliation'],
                'taux_commission' => floatval($r['taux_commission']),
                'statut' => $r['statut'],
                'nb_clients' => (int) $r['nb_clients'],
                'total_collecte' => floatval($r['total_collecte']),
                'total_commissions' => floatval($r['total_commissions'])
            ], $rows)
        ], JSON_UNESCAPED_UNICODE);
    }

    /**
     * Création d'un agent
     */
    public function creerAgent(): void
    {
        $this->requireAdmin();

        $raw = file_get_contents('php://input') ?: '';
        $data = json_decode($raw, true) ?: [];

        $nom = trim($data['nom'] ?? '');
        $email = trim($data['email'] ?? '');
        $telephone = trim($data['telephone'] ?? '');
        $password = $data['mot_de_passe'] ?? '';
        $taux = floatval($data['taux_commission'] ?? 2.0);

        if ($nom === '' || $email === '' || $password === '') {
            $this->fail(422, 'Nom, email et mot de passe requis');
        }

        try {
            $this->pdo->beginTransaction();

            // Vérifier email
            $st = $this->pdo->prepare("SELECT id FROM utilisateurs WHERE email = ?");
            $st->execute([$email]);
            if ($st->fetch()) {
                throw new Exception("Email déjà utilisé");
            }

            // Créer utilisateur
            $st = $this->pdo->prepare(
                "INSERT INTO utilisateurs (nom, email, telephone, mot_de_passe, role, created_at) 
                 VALUES (?, ?, ?, ?, 'agent', NOW())"
            );
            $st->execute([$nom, $email, $telephone, password_hash($password, PASSWORD_BCRYPT)]);
            $userId = (int) $this->pdo->lastInsertId();

            // Générer code
            $count = (int) $this->pdo->query("SELECT COUNT(*) FROM agents")->fetchColumn();
            $code = 'EE-AKWA-' . str_pad((string)($count + 1), 3, '0', STR_PAD_LEFT);

            // Créer agent
            $st = $this->pdo->prepare(
                "INSERT INTO agents (utilisateur_id, code_affiliation, taux_commission, statut) 
                 VALUES (?, ?, ?, 'actif')"
            );
            $st->execute([$userId, $code, $taux]);

            $this->pdo->commit();

            header('Content-Type: application/json; charset=utf-8');
            echo json_encode([
                'success' => true,
                'message' => 'Agent créé avec succès',
                'code' => $code
            ], JSON_UNESCAPED_UNICODE);

        } catch (Exception $e) {
            $this->pdo->rollBack();
            $this->fail(500, $e->getMessage());
        }
    }

    /**
     * Changer le statut d'un agent
     */
    public function modifierStatutAgent(int $id): void
    {
        $this->requireAdmin();

        $raw = file_get_contents('php://input') ?: '';
        $data = json_decode($raw, true) ?: [];
        $statut = $data['statut'] ?? '';

        if (!in_array($statut, ['actif', 'inactif'])) {
            $this->fail(422, 'Statut invalide');
        }

        $stmt = $this->pdo->prepare("UPDATE agents SET statut = ? WHERE utilisateur_id = ?");
        $stmt->execute([$statut, $id]);

        header('Content-Type: application/json; charset=utf-8');
        echo json_encode([
            'success' => true,
            'message' => 'Statut mis à jour'
        ], JSON_UNESCAPED_UNICODE);
    }

    /**
     * Rapports : Synthèse mensuelle
     */
    public function rapports(): void
    {
        $this->requireAdmin();

        $moisCourant = date('Y-m');

        // Total collecte mois
        $stmt = $this->pdo->prepare(
            "SELECT COALESCE(SUM(montant), 0) FROM transactions 
             WHERE statut = 'success' AND date LIKE ?"
        );
        $stmt->execute([$moisCourant . '%']);
        $totalCollecte = (float) $stmt->fetchColumn();

        // Total commissions mois
        $stmt = $this->pdo->prepare(
            "SELECT COALESCE(SUM(montant), 0) FROM commissions WHERE date LIKE ?"
        );
        $stmt->execute([$moisCourant . '%']);
        $totalCommissions = (float) $stmt->fetchColumn();

        // Nb transactions mois
        $stmt = $this->pdo->prepare(
            "SELECT COUNT(*) FROM transactions WHERE statut = 'success' AND date LIKE ?"
        );
        $stmt->execute([$moisCourant . '%']);
        $nbTransactions = (int) $stmt->fetchColumn();

        // 10 dernières transactions
        $stmt = $this->pdo->query(
            "SELECT t.id, t.montant, t.date, t.statut, t.type_paiement, u.nom as client_nom
             FROM transactions t
             JOIN comptes co ON t.compte_id = co.id
             JOIN clients cl ON co.client_id = cl.id
             JOIN utilisateurs u ON cl.utilisateur_id = u.id
             ORDER BY t.date DESC
             LIMIT 10"
        );
        $transactions = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Collecte par agent ce mois
        $stmt = $this->pdo->prepare(
            "SELECT u.nom as agent_nom, a.code_affiliation as code, 
                    COALESCE(SUM(t.montant), 0) as total
             FROM agents a
             JOIN utilisateurs u ON a.utilisateur_id = u.id
             LEFT JOIN clients cl ON cl.agent_id = a.id
             LEFT JOIN comptes co ON co.client_id = cl.id
             LEFT JOIN transactions t ON t.compte_id = co.id AND t.statut = 'success' AND t.date LIKE ?
             GROUP BY a.id
             ORDER BY total DESC"
        );
        $stmt->execute([$moisCourant . '%']);
        $collecteParAgent = $stmt->fetchAll(PDO::FETCH_ASSOC);

        header('Content-Type: application/json; charset=utf-8');
        echo json_encode([
            'success' => true,
            'data' => [
                'periode' => $moisCourant,
                'total_collecte' => $totalCollecte,
                'total_commissions' => $totalCommissions,
                'nombre_transactions' => $nbTransactions,
                'transactions_recentes' => array_map(fn($t) => [
                    'id' => (int) $t['id'],
                    'montant' => floatval($t['montant']),
                    'date' => $t['date'],
                    'statut' => $t['statut'],
                    'type_paiement' => $t['type_paiement'],
                    'client_nom' => $t['client_nom']
                ], $transactions),
                'collecte_par_agent' => array_map(fn($row) => [
                    'agent_nom' => $row['agent_nom'],
                    'code' => $row['code'],
                    'total' => floatval($row['total'])
                ], $collecteParAgent)
            ]
        ], JSON_UNESCAPED_UNICODE);
    }
}
