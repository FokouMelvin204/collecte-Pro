<?php
declare(strict_types=1);

/**
 * Dispatch REST minimal : méthode HTTP + segments de chemin après /api/
 */

require_once __DIR__ . '/../controllers/AuthController.php';
require_once __DIR__ . '/../controllers/AgentController.php';
require_once __DIR__ . '/../controllers/ClientController.php';
require_once __DIR__ . '/../controllers/TransactionController.php';
require_once __DIR__ . '/../controllers/AdminController.php';

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$uriPath = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';

// Normalise le chemin relatif à ce dossier (api/).
$scriptDir = str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'] ?? ''));
if ($scriptDir !== '' && str_starts_with($uriPath, $scriptDir)) {
    $uriPath = substr($uriPath, strlen($scriptDir));
}
$uriPath = trim($uriPath, '/');
$segments = $uriPath === '' ? [] : explode('/', $uriPath);

// Retire "index.php" si présent en premier segment
if (isset($segments[0]) && $segments[0] === 'index.php') {
    array_shift($segments);
}

$resource = $segments[0] ?? '';
$action = $segments[1] ?? '';

if ($resource === '' || $resource === 'index.php') {
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'name' => 'Collecte Pro API',
        'status' => 'ok',
        'hint' => 'Exemple : POST /auth/login',
    ], JSON_UNESCAPED_UNICODE);
    return;
}

// --- Auth ---
if ($resource === 'auth') {
    $auth = new AuthController();
    if ($method === 'POST' && $action === 'login') {
        $auth->login();
        return;
    }
    if ($method === 'POST' && $action === 'logout') {
        $auth->logout();
        return;
    }
}

// --- Agent ---
if ($resource === 'agent') {
    $c = new AgentController();
    if ($method === 'GET' && $action === 'dashboard') {
        $c->dashboard();
        return;
    }
    if ($method === 'GET' && $action === 'clients') {
        $c->clients();
        return;
    }
    if ($method === 'GET' && $action === 'commissions') {
        $c->commissions();
        return;
    }
    if ($method === 'GET' && ($action === '' || $action === 'profile')) {
        $c->profile();
        return;
    }
}

// --- Client ---
if ($resource === 'client') {
    require_once __DIR__ . '/../config/database.php';
    $pdo = getPdo();
    $c = new ClientController($pdo);

    if ($method === 'POST' && $action === 'inscription') {
        $c->inscription();
        return;
    }
    if ($method === 'GET' && $action === 'dashboard') {
        $c->dashboard();
        return;
    }
    if ($method === 'POST' && $action === 'versement') {
        $c->versement();
        return;
    }
    if ($method === 'GET' && $action === 'historique') {
        $c->historique();
        return;
    }

    // Route client inconnue
    http_response_code(404);
    echo json_encode([
        'success' => false,
        'message' => 'Route client non trouvée'
    ]);
    return;
}

// --- Transactions ---
if ($resource === 'transactions') {
    $c = new TransactionController();
    if ($method === 'GET') {
        $c->list();
        return;
    }
}

// --- Admin ---
if ($resource === 'admin') {
    $c = new AdminController();
    
    // GET /admin/dashboard
    if ($method === 'GET' && ($action === '' || $action === 'dashboard')) {
        $c->dashboard();
        return;
    }

    // GET /admin/clients/attente
    if ($method === 'GET' && $action === 'clients' && ($segments[2] ?? '') === 'attente') {
        $c->clientsAttente();
        return;
    }

    // POST /admin/clients/{id}/valider
    if ($method === 'POST' && $action === 'clients' && ($segments[3] ?? '') === 'valider') {
        $id = (int) ($segments[2] ?? 0);
        $c->validerClient($id);
        return;
    }

    // POST /admin/clients/{id}/rejeter
    if ($method === 'POST' && $action === 'clients' && ($segments[3] ?? '') === 'rejeter') {
        $id = (int) ($segments[2] ?? 0);
        $c->rejeterClient($id);
        return;
    }

    // GET /admin/agents
    if ($method === 'GET' && $action === 'agents' && !isset($segments[2])) {
        $c->agents();
        return;
    }

    // POST /admin/agents (création)
    if ($method === 'POST' && $action === 'agents' && !isset($segments[2])) {
        $c->creerAgent();
        return;
    }

    // POST /admin/agents/{id}/statut
    if ($method === 'POST' && $action === 'agents' && ($segments[3] ?? '') === 'statut') {
        $id = (int) ($segments[2] ?? 0);
        $c->modifierStatutAgent($id);
        return;
    }

    // GET /admin/rapports
    if ($method === 'GET' && $action === 'rapports') {
        $c->rapports();
        return;
    }
}

http_response_code(404);
header('Content-Type: application/json; charset=utf-8');
echo json_encode(['message' => 'Route introuvable', 'path' => $segments], JSON_UNESCAPED_UNICODE);
