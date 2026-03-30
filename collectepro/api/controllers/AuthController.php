<?php
declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';

/**
 * Authentification : login / logout — JSON uniquement, sessions persistées en base.
 */
class AuthController
{
    public function login(): void
    {
        header('Content-Type: application/json; charset=utf-8');

        $raw = file_get_contents('php://input') ?: '';
        $input = json_decode($raw, true);
        if (!is_array($input)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'JSON invalide'], JSON_UNESCAPED_UNICODE);
            return;
        }

        $email = trim((string) ($input['email'] ?? ''));
        $password = (string) ($input['mot_de_passe'] ?? $input['password'] ?? '');

        if ($email === '' || $password === '') {
            http_response_code(422);
            echo json_encode(['success' => false, 'message' => 'E-mail et mot de passe requis'], JSON_UNESCAPED_UNICODE);
            return;
        }

        $pdo = getPdo();
        $stmt = $pdo->prepare(
            'SELECT id, nom, email, telephone, role, mot_de_passe FROM utilisateurs WHERE email = :email LIMIT 1'
        );
        $stmt->execute(['email' => $email]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($row === false) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'Email ou mot de passe incorrect'], JSON_UNESCAPED_UNICODE);
            return;
        }

        if (!password_verify($password, $row['mot_de_passe'])) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'Email ou mot de passe incorrect'], JSON_UNESCAPED_UNICODE);
            return;
        }

        $userId = (int) $row['id'];
        $role = $row['role'];

        // Un seul jeton actif par utilisateur (nouvelle connexion invalide les précédents).
        $del = $pdo->prepare('DELETE FROM sessions WHERE user_id = :uid');
        $del->execute(['uid' => $userId]);

        $token = bin2hex(random_bytes(32));
        $ins = $pdo->prepare(
            'INSERT INTO sessions (user_id, token, created_at) VALUES (:uid, :token, NOW())'
        );
        $ins->execute(['uid' => $userId, 'token' => $token]);

        $extra = $this->buildExtraForRole($pdo, $role, $userId);

        echo json_encode([
            'success' => true,
            'token' => $token,
            'role' => $role,
            'user' => [
                'id' => $userId,
                'nom' => $row['nom'],
                'email' => $row['email'],
                'telephone' => $row['telephone'],
            ],
            'extra' => $extra,
        ], JSON_UNESCAPED_UNICODE);
    }

    /**
     * @return array<string, mixed>
     */
    private function buildExtraForRole(PDO $pdo, string $role, int $userId): array
    {
        if ($role === 'agent') {
            $st = $pdo->prepare(
                'SELECT code_affiliation, taux_commission, statut FROM agents WHERE utilisateur_id = :uid LIMIT 1'
            );
            $st->execute(['uid' => $userId]);
            $a = $st->fetch(PDO::FETCH_ASSOC);
            if ($a === false) {
                return [];
            }

            return [
                'code_affiliation' => $a['code_affiliation'],
                'taux_commission' => (float) $a['taux_commission'],
                'statut' => $a['statut'],
            ];
        }

        if ($role === 'client') {
            $st = $pdo->prepare(
                'SELECT c.statut_compte, c.numero_compte, COALESCE(co.solde, 0) AS solde
                 FROM clients c
                 LEFT JOIN comptes co ON co.client_id = c.id
                 WHERE c.utilisateur_id = :uid
                 LIMIT 1'
            );
            $st->execute(['uid' => $userId]);
            $c = $st->fetch(PDO::FETCH_ASSOC);
            if ($c === false) {
                return [];
            }

            return [
                'statut_compte' => $c['statut_compte'],
                'numero_compte' => $c['numero_compte'],
                'solde' => (float) $c['solde'],
            ];
        }

        return [];
    }

    public function logout(): void
    {
        header('Content-Type: application/json; charset=utf-8');

        $token = $this->readBearerToken();
        if ($token === null || $token === '') {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'Token manquant'], JSON_UNESCAPED_UNICODE);
            return;
        }

        $pdo = getPdo();
        $stmt = $pdo->prepare('DELETE FROM sessions WHERE token = :token');
        $stmt->execute(['token' => $token]);

        echo json_encode([
            'success' => true,
            'message' => 'Déconnecté',
        ], JSON_UNESCAPED_UNICODE);
    }

    private function readBearerToken(): ?string
    {
        $headers = [];
        if (function_exists('getallheaders')) {
            $headers = getallheaders() ?: [];
        }
        $auth = $headers['Authorization'] ?? $headers['authorization'] ?? ($_SERVER['HTTP_AUTHORIZATION'] ?? '');
        if ($auth !== '' && preg_match('/Bearer\s+(\S+)/i', $auth, $m)) {
            return $m[1];
        }
        // Apache peut passer le header autrement
        if (!empty($_SERVER['REDIRECT_HTTP_AUTHORIZATION']) && preg_match('/Bearer\s+(\S+)/i', (string) $_SERVER['REDIRECT_HTTP_AUTHORIZATION'], $m)) {
            return $m[1];
        }

        return null;
    }
}
