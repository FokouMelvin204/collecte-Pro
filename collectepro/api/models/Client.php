<?php
declare(strict_types=1);

/**
 * Représentation de la table `clients`.
 */
class Client
{
    public function __construct(
        public ?int $id,
        public int $utilisateurId,
        public int $agentId,
        public string $statutCompte,
        public string $numeroCompte,
        public ?string $cniPath,
    ) {
    }
}
