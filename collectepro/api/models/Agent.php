<?php
declare(strict_types=1);

/**
 * Représentation de la table `agents`.
 */
class Agent
{
    public function __construct(
        public ?int $id,
        public int $utilisateurId,
        public string $codeAffiliation,
        public string $tauxCommission,
        public string $statut,
    ) {
    }
}
