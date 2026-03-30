<?php
declare(strict_types=1);

/**
 * Représentation de la table `utilisateurs`.
 */
class User
{
    public function __construct(
        public ?int $id,
        public string $nom,
        public string $email,
        public string $telephone,
        public string $role,
        public ?string $motDePasseHash = null,
    ) {
    }
}
