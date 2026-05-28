-- Demo users for local development and smoke tests.
--
-- Password hashes are precomputed PBKDF2-SHA256 outputs from the runtime
-- hash function. Sign-in code hashes are HMAC-SHA256 outputs. Both use the
-- runtime's encoded hash format with embedded salt/parameters so the
-- verify functions can validate against them.
--
-- Admin:  admin@example.com / admin / code A1Z9Q / role = 'admin'
-- Fan:    fan@example.com   / fan  / code A1Z9Q / role = 'fan'

INSERT OR IGNORE INTO users (email, display_name, password_hash, sign_in_code_hash, role)
VALUES
    (
        'admin@example.com',
        NULL,
        '$runtime-pbkdf2-sha256$v=1$i=600000$TLcZ1AIacSW2Y9Sx1n2quA$5BuKTg_PPcRyGNNFWAC-JWc4wHZyGhTfQfbiDtmS_Zo',
        '$runtime-sign-in-code-hmac-sha256$v=1$FY-UwgWkAUbUUAjKZIrySIhmkDwEniQHxhEw7QwbcGU',
        'admin'
    ),
    (
        'fan@example.com',
        'Fan',
        '$runtime-pbkdf2-sha256$v=1$i=600000$4JLcFedQMxkwHeAAxL_LjA$FOVkFBcXUNDrPTLYbFHMkqUGw8Bgnv9qdt_hC_bDQxA',
        '$runtime-sign-in-code-hmac-sha256$v=1$26QkhMJZyJsBDiH3ae0NfkdhN2ynV41mmuBmMphzqB8',
        'fan'
    );
