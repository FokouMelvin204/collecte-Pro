<?php
require_once __DIR__ . '/../middleware/auth_middleware.php';

class ClientController {
  private PDO $pdo;

  public function __construct(PDO $pdo) {
    $this->pdo = $pdo;
  }

  private function fail(int $code, string $msg): void {
    http_response_code($code);
    echo json_encode(['success' => false, 'message' => $msg]);
    exit;
  }

  private function requireAuth(): int {
    $userId = validateToken($this->pdo);
    if (!$userId) {
      $this->fail(401, 'Token invalide ou manquant');
    }
    return $userId;
  }

  private function requireClient(int $userId): array {
    $stmt = $this->pdo->prepare(
      'SELECT cl.id, cl.agent_id, cl.statut_compte, cl.created_at, cl.numero_compte,
              co.id AS compte_id, co.solde
       FROM clients cl
       LEFT JOIN comptes co ON co.client_id = cl.id
       WHERE cl.utilisateur_id = ?'
    );
    $stmt->execute([$userId]);
    $client = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$client) {
      $this->fail(403, 'Profil client introuvable');
    }
    return $client;
  }

  public function inscription(): void {
    $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
    if (stripos($contentType, 'application/json') !== false) {
      $raw = file_get_contents('php://input') ?: '';
      $data = json_decode($raw, true);
      $data = is_array($data) ? $data : [];
    } else {
      $data = array_merge($_POST, $_GET);
    }

    $nom = trim($data['nom'] ?? '');
    $email = trim($data['email'] ?? '');
    $telephone = trim($data['telephone'] ?? '');
    $motDePasse = $data['mot_de_passe'] ?? $data['password'] ?? '';
    $codeAffiliation = trim($data['code_affiliation'] ?? $data['codeAffiliation'] ?? '');

    $errors = [];
    if ($nom === '') $errors[] = 'Le nom est requis';
    if ($email === '') $errors[] = 'L\'email est requis';
    if ($telephone === '') $errors[] = 'Le téléphone est requis';
    if ($motDePasse === '') $errors[] = 'Le mot de passe est requis';
    if (strlen($motDePasse) < 6) $errors[] = '6 caractères minimum';

    if (!empty($errors)) {
      http_response_code(422);
      echo json_encode(['success' => false, 'errors' => $errors]);
      return;
    }

    $stmt = $this->pdo->prepare('SELECT id FROM utilisateurs WHERE email = ? LIMIT 1');
    $stmt->execute([$email]);
    if ($stmt->fetch(PDO::FETCH_ASSOC)) {
      http_response_code(409);
      echo json_encode(['success' => false, 'message' => 'Email déjà utilisé']);
      return;
    }

    $agentId = null;
    if ($codeAffiliation !== '') {
      $stmt = $this->pdo->prepare('SELECT id FROM agents WHERE code_affiliation = ? LIMIT 1');
      $stmt->execute([$codeAffiliation]);
      $agent = $stmt->fetch(PDO::FETCH_ASSOC);
      if (!$agent) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Code agent invalide']);
        return;
      }
      $agentId = (int) $agent['id'];
    } else {
      http_response_code(400);
      echo json_encode(['success' => false, 'message' => 'Code agent parrain requis']);
      return;
    }

    try {
      $this->pdo->beginTransaction();

      $hashedPassword = password_hash($motDePasse, PASSWORD_BCRYPT);
      $stmt = $this->pdo->prepare(
        'INSERT INTO utilisateurs (nom, email, telephone, mot_de_passe, role, created_at)
         VALUES (?, ?, ?, ?, "client", NOW())'
      );
      $stmt->execute([$nom, $email, $telephone, $hashedPassword]);
      $userId = (int) $this->pdo->lastInsertId();

      $stmt = $this->pdo->prepare(
        'INSERT INTO clients (utilisateur_id, agent_id, statut_compte, numero_compte, created_at)
         VALUES (?, ?, "en_attente", ?, NOW())'
      );
      // On met un numéro de compte temporaire unique pour l'inscription
      $tempNumero = 'TEMP-' . time() . '-' . $userId;
      $stmt->execute([$userId, $agentId, $tempNumero]);

      $this->pdo->commit();

      echo json_encode([
        'success' => true,
        'message' => 'Inscription soumise. En attente de validation.',
        'user_id' => $userId,
      ]);

    } catch (Exception $e) {
      $this->pdo->rollBack();
      http_response_code(500);
      echo json_encode(['success' => false, 'message' => 'Erreur: ' . $e->getMessage()]);
    }
  }

  public function dashboard(): void {
    $userId = $this->requireAuth();
    $client = $this->requireClient($userId);

    $stmt = $this->pdo->prepare(
      'SELECT u.nom, u.email, u.telephone, cl.statut_compte, cl.created_at
       FROM utilisateurs u
       JOIN clients cl ON cl.utilisateur_id = u.id
       WHERE u.id = ?'
    );
    $stmt->execute([$userId]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    $stmt = $this->pdo->prepare(
      'SELECT t.id, t.montant, t.date, t.statut, t.type_paiement
       FROM transactions t
       JOIN comptes co ON t.compte_id = co.id
       JOIN clients cl ON co.client_id = cl.id
       WHERE cl.utilisateur_id = ?
       ORDER BY t.date DESC
       LIMIT 5'
    );
    $stmt->execute([$userId]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $transactions = array_map(fn($r) => [
      'id' => (int) $r['id'],
      'montant' => floatval($r['montant']),
      'date' => $r['date'],
      'statut' => $r['statut'],
      'type_paiement' => $r['type_paiement'],
    ], $rows);

    echo json_encode([
      'success' => true,
      'data' => [
        'nom' => $user['nom'],
        'email' => $user['email'],
        'telephone' => $user['telephone'],
        'statut_compte' => $client['statut_compte'],
        'numero_compte' => $client['numero_compte'],
        'solde' => floatval($client['solde']),
        'date_inscription' => $user['created_at'],
        'dernieres_transactions' => $transactions,
      ],
    ]);
  }

  public function versement(): void {
    $userId = $this->requireAuth();
    $client = $this->requireClient($userId);

    if ($client['statut_compte'] !== 'actif') {
      $this->fail(403, 'Votre compte n\'est pas encore activé');
    }

    $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
    if (stripos($contentType, 'application/json') !== false) {
      $raw = file_get_contents('php://input') ?: '';
      $data = json_decode($raw, true);
      $data = is_array($data) ? $data : [];
    } else {
      $data = array_merge($_POST, $_GET);
    }

    $montant = isset($data['montant']) ? floatval($data['montant']) : 0;

    if ($montant <= 0) {
      $this->fail(422, 'Le montant doit être supérieur à 0');
    }
    if ($montant > 5000000) {
      $this->fail(422, 'Montant trop élevé (max 5 000 000 FCFA)');
    }

    try {
      $this->pdo->beginTransaction();

      $stmt = $this->pdo->prepare(
        'INSERT INTO transactions (compte_id, montant, date, statut, type_paiement)
         VALUES (?, ?, NOW(), "success", "depot")'
      );
      $stmt->execute([$client['compte_id'], $montant]);
      $transactionId = (int) $this->pdo->lastInsertId();

      $stmt = $this->pdo->prepare(
        'UPDATE comptes SET solde = solde + ? WHERE id = ?'
      );
      $stmt->execute([$montant, $client['compte_id']]);
      $nouveauSolde = floatval($client['solde']) + $montant;

      $stmt = $this->pdo->prepare(
        'SELECT a.taux_commission FROM agents a
         JOIN clients cl ON cl.agent_id = a.id
         WHERE cl.id = ?'
      );
      $stmt->execute([$client['id']]);
      $agent = $stmt->fetch(PDO::FETCH_ASSOC);
      
      $commission = 0;
      if ($agent) {
        $commission = $montant * floatval($agent['taux_commission']) / 100;
        $stmt = $this->pdo->prepare(
          'INSERT INTO commissions (agent_id, transaction_id, montant, date)
           VALUES (?, ?, ?, NOW())'
        );
        $stmt->execute([$client['agent_id'], $transactionId, $commission]);
      }

      $this->pdo->commit();

      echo json_encode([
        'success' => true,
        'message' => 'Versement effectué avec succès !',
        'data' => [
          'transaction_id' => $transactionId,
          'montant' => $montant,
          'nouveau_solde' => $nouveauSolde,
          'commission_agent' => $commission,
          'date' => date('Y-m-d H:i:s'),
        ],
      ]);

    } catch (Exception $e) {
      $this->pdo->rollBack();
      http_response_code(500);
      echo json_encode(['success' => false, 'message' => 'Erreur: ' . $e->getMessage()]);
    }
  }

  public function historique(): void {
    $userId = $this->requireAuth();
    $client = $this->requireClient($userId);

    $stmt = $this->pdo->prepare(
      'SELECT t.id, t.montant, t.date, t.statut, t.type_paiement
       FROM transactions t
       JOIN comptes co ON t.compte_id = co.id
       JOIN clients cl ON co.client_id = cl.id
       WHERE cl.utilisateur_id = ?
       ORDER BY t.date DESC'
    );
    $stmt->execute([$userId]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $transactions = array_map(fn($r) => [
      'id' => (int) $r['id'],
      'montant' => floatval($r['montant']),
      'date' => $r['date'],
      'statut' => $r['statut'],
      'type_paiement' => $r['type_paiement'],
    ], $rows);

    $totalVerse = array_sum(array_column($transactions, 'montant'));

    echo json_encode([
      'success' => true,
      'data' => [
        'transactions' => $transactions,
        'total_verse' => floatval($totalVerse),
        'nombre_transactions' => count($transactions),
      ],
    ]);
  }
}
