<?php
declare(strict_types=1);

/**
 * Représentation de la table `commissions`.
 */
class Commission
{
    public function __construct(
        public ?int $id,
        public int $agentId,
        public int $transactionId,
        public string $montant,
        public string $date,
    ) {
    }
}
