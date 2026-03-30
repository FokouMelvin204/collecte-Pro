<?php
declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';

/**
 * Transactions et historique.
 */
class TransactionController
{
    public function list(): void
    {
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode([
            'data' => [],
            'message' => 'TransactionController::list — à compléter.',
        ], JSON_UNESCAPED_UNICODE);
    }
}
