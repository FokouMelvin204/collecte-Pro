<?php
declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/auth_middleware.php';

/**
 * Endpoints liés aux agents (dashboard, clients, commissions).
 * Tous les endpoints exigent un token Bearer valide et un rôle 'agent'.
 */
class AgentController
{
    private PDO $pdo;
    private int $userId;
    private int $agentId;

    public function __construct()
    {
        $this->pdo = getPdo();
        
        // Valider le token et récupérer le user_id
        $userId = validateToken($this->pdo);
        if ($userId === false) {
            $this->unauthorized('Token invalide ou manquant');
            return;
        }
        $this->userId = $userId;

        // Récupérer l'agent_id
        $stmt = $this->pdo->prepare('SELECT id FROM agents WHERE utilisateur_id = :uid LIMIT 1');
        $stmt->execute(['uid' => $this->userId]);
        $agent = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($agent === false) {
            $this->forbidden('Cet utilisateur n\'est pas un agent');
            return;
        }
        
        $this->agentId = (int) $agent['id'];
    }

    /**
     * GET /agent/dashboard
     * Stats du jour + activité des clients
     */
    public function dashboard(): void
    {
        header('Content-Type: application/json; charset=utf-8');

        // Total collecté aujourd'hui (transactions des clients de cet agent)
        $stmt = $this->pdo->prepare(
            'SELECT COALESCE(SUM(t.montant), 0) AS total
             FROM transactions t
             JOIN comptes co ON t.compte_id = co.id
             JOIN clients cl ON co.client_id = cl.id
             WHERE cl.agent_id = :agentId AND DATE(t.date) = CURDATE() AND t.statut = "success"'
        );
        $stmt->execute(['agentId' => $this->agentId]);
        $totalJour = (float) $stmt->fetch(PDO::FETCH_ASSOC)['total'];

        // Total collecté ce mois
        $stmt = $this->pdo->prepare(
            'SELECT COALESCE(SUM(t.montant), 0) AS total
             FROM transactions t
             JOIN comptes co ON t.compte_id = co.id
             JOIN clients cl ON co.client_id = cl.id
             WHERE cl.agent_id = :agentId AND MONTH(t.date) = MONTH(CURDATE()) 
             AND YEAR(t.date) = YEAR(CURDATE()) AND t.statut = "success"'
        );
        $stmt->execute(['agentId' => $this->agentId]);
        $totalMois = (float) $stmt->fetch(PDO::FETCH_ASSOC)['total'];

        // Nombre de clients
        $stmt = $this->pdo->prepare('SELECT COUNT(*) AS nb FROM clients WHERE agent_id = :agentId');
        $stmt->execute(['agentId' => $this->agentId]);
        $nbClients = (int) $stmt->fetch(PDO::FETCH_ASSOC)['nb'];

        // Commission aujourd'hui
        $stmt = $this->pdo->prepare(
            'SELECT COALESCE(SUM(c.montant), 0) AS total
             FROM commissions c
             WHERE c.agent_id = :agentId AND DATE(c.date) = CURDATE()'
        );
        $stmt->execute(['agentId' => $this->agentId]);
        $commissionJour = (float) $stmt->fetch(PDO::FETCH_ASSOC)['total'];

        // Commission ce mois
        $stmt = $this->pdo->prepare(
            'SELECT COALESCE(SUM(c.montant), 0) AS total
             FROM commissions c
             WHERE c.agent_id = :agentId AND MONTH(c.date) = MONTH(CURDATE())
             AND YEAR(c.date) = YEAR(CURDATE())'
        );
        $stmt->execute(['agentId' => $this->agentId]);
        $commissionMois = (float) $stmt->fetch(PDO::FETCH_ASSOC)['total'];

        // 5 derniers versements des clients
        $stmt = $this->pdo->prepare(
            'SELECT u.nom AS client_nom, t.montant, t.date AS date, t.statut
             FROM transactions t
             JOIN comptes co ON t.compte_id = co.id
             JOIN clients cl ON co.client_id = cl.id
             JOIN utilisateurs u ON cl.utilisateur_id = u.id
             WHERE cl.agent_id = :agentId
             ORDER BY t.date DESC
             LIMIT 5'
        );
        $stmt->execute(['agentId' => $this->agentId]);
        $versements = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $versementsRecents = array_map(function($v) {
            return [
                'client_nom' => $v['client_nom'],
                'montant' => (float) $v['montant'],
                'date' => $v['date'],
                'statut' => $v['statut'],
            ];
        }, $versements);

        echo json_encode([
            'success' => true,
            'data' => [
                'total_collecte_jour' => $totalJour,
                'total_collecte_mois' => $totalMois,
                'nombre_clients' => $nbClients,
                'commission_jour' => $commissionJour,
                'commission_mois' => $commissionMois,
                'versements_recents' => $versementsRecents,
            ],
        ], JSON_UNESCAPED_UNICODE);
    }

    /**
     * GET /agent/clients
     * Liste des clients parrainés par l'agent
     */
    public function clients(): void
    {
        header('Content-Type: application/json; charset=utf-8');

        $stmt = $this->pdo->prepare(
            'SELECT u.id, u.nom, u.email, u.telephone, c.statut_compte, 
                    c.numero_compte, COALESCE(co.solde, 0) AS solde,
                    c.created_at AS date_inscription
             FROM clients c
             JOIN utilisateurs u ON c.utilisateur_id = u.id
             LEFT JOIN comptes co ON co.client_id = c.id
             WHERE c.agent_id = :agentId
             ORDER BY u.nom ASC'
        );
        $stmt->execute(['agentId' => $this->agentId]);
        $clients = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $data = array_map(function($c) {
            return [
                'id' => (int) $c['id'],
                'nom' => $c['nom'],
                'email' => $c['email'],
                'telephone' => $c['telephone'],
                'statut_compte' => $c['statut_compte'],
                'numero_compte' => $c['numero_compte'],
                'solde' => (float) $c['solde'],
                'date_inscription' => $c['date_inscription'],
            ];
        }, $clients);

        echo json_encode([
            'success' => true,
            'data' => $data,
        ], JSON_UNESCAPED_UNICODE);
    }

    /**
     * GET /agent/commissions
     * Historique des commissions
     */
    public function commissions(): void
    {
        header('Content-Type: application/json; charset=utf-8');

        // Récupérer le taux de commission de l'agent
        $stmt = $this->pdo->prepare('SELECT taux_commission FROM agents WHERE id = :agentId');
        $stmt->execute(['agentId' => $this->agentId]);
        $agent = $stmt->fetch(PDO::FETCH_ASSOC);
        $taux = (float) ($agent['taux_commission'] ?? 0);

        // Total des commissions
        $stmt = $this->pdo->prepare(
            'SELECT COALESCE(SUM(montant), 0) AS total FROM commissions WHERE agent_id = :agentId'
        );
        $stmt->execute(['agentId' => $this->agentId]);
        $totalCommissions = (float) $stmt->fetch(PDO::FETCH_ASSOC)['total'];

        // Liste des commissions
        $stmt = $this->pdo->prepare(
            'SELECT c.id, c.montant, c.date AS date, t.montant AS transaction_montant,
                    u.nom AS client_nom
             FROM commissions c
             JOIN transactions t ON c.transaction_id = t.id
             JOIN comptes co ON t.compte_id = co.id
             JOIN clients cl ON co.client_id = cl.id
             JOIN utilisateurs u ON cl.utilisateur_id = u.id
             WHERE c.agent_id = :agentId
             ORDER BY c.date DESC'
        );
        $stmt->execute(['agentId' => $this->agentId]);
        $commissions = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $data = array_map(function($c) {
            return [
                'id' => (int) $c['id'],
                'montant' => (float) $c['montant'],
                'date' => $c['date'],
                'transaction_montant' => (float) $c['transaction_montant'],
                'client_nom' => $c['client_nom'],
            ];
        }, $commissions);

        echo json_encode([
            'success' => true,
            'data' => [
                'total_commissions' => $totalCommissions,
                'taux' => $taux,
                'commissions' => $data,
            ],
        ], JSON_UNESCAPED_UNICODE);
    }

    /**
     * GET /agent/profile
     * Profil de l'agent (déjà existant)
     */
    public function profile(): void
    {
        header('Content-Type: application/json; charset=utf-8');

        $stmt = $this->pdo->prepare(
            'SELECT u.nom, u.email, u.telephone, a.code_affiliation, 
                    a.taux_commission, a.statut
             FROM utilisateurs u
             JOIN agents a ON u.id = a.utilisateur_id
             WHERE u.id = :userId'
        );
        $stmt->execute(['userId' => $this->userId]);
        $agent = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($agent === false) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Agent non trouvé']);
            return;
        }

        echo json_encode([
            'success' => true,
            'data' => [
                'nom' => $agent['nom'],
                'email' => $agent['email'],
                'telephone' => $agent['telephone'],
                'code_affiliation' => $agent['code_affiliation'],
                'taux_commission' => (float) $agent['taux_commission'],
                'statut' => $agent['statut'],
            ],
        ], JSON_UNESCAPED_UNICODE);
    }

    private function unauthorized(string $message): void
    {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => $message]);
    }

    private function forbidden(string $message): void
    {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => $message]);
    }
}
