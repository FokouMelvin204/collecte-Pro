<?php
declare(strict_types=1);

/**
 * Représentation de la table `transactions`.
 */
class Transaction
{
    public function __construct(
        public ?int $id,
        public int $compteId,
        public string $montant,
        public string $date,
        public string $statut,
        public string $typePaiement,
    ) {
    }
}
