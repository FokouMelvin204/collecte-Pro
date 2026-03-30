<?php
declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';

/**
 * Valide le jeton Bearer contre la table `sessions`.
 *
 * @return int|false user_id si valide, false sinon
 */
function validateToken(PDO $pdo): int|false
{
    $token = readBearerTokenFromRequest();
    if ($token === null || $token === '') {
        return false;
    }

    $stmt = $pdo->prepare('SELECT user_id FROM sessions WHERE token = :token LIMIT 1');
    $stmt->execute(['token' => $token]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($row === false) {
        return false;
    }

    return (int) $row['user_id'];
}

function readBearerTokenFromRequest(): ?string
{
    $headers = function_exists('getallheaders') ? (getallheaders() ?: []) : [];
    $auth = $headers['Authorization'] ?? $headers['authorization'] ?? ($_SERVER['HTTP_AUTHORIZATION'] ?? '');
    if ($auth !== '' && preg_match('/Bearer\s+(\S+)/i', $auth, $m)) {
        return $m[1];
    }
    if (!empty($_SERVER['REDIRECT_HTTP_AUTHORIZATION']) && preg_match('/Bearer\s+(\S+)/i', (string) $_SERVER['REDIRECT_HTTP_AUTHORIZATION'], $m)) {
        return $m[1];
    }

    return null;
}
