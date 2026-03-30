<?php
declare(strict_types=1);

/**
 * Représentation de la table `rapports`.
 */
class Rapport
{
    public function __construct(
        public ?int $id,
        public int $adminId,
        public string $dateGeneration,
        public string $typeRapport,
        public string $montantTotal,
    ) {
    }
}
