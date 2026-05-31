-- Demo users for local development and smoke tests.
--
-- Sign-in code hashes are HMAC-SHA256 outputs using the runtime's encoded
-- hash format.
--
-- Admin:  admin@example.com / code A1Z9Q / role = 'admin'
-- Fan:    fan@example.com   / code A1Z9Q / role = 'fan'

INSERT OR IGNORE INTO users (email, display_name, sign_in_code_hash, role)
VALUES
    (
        'admin@example.com',
        NULL,
        '$runtime-sign-in-code-hmac-sha256$v=1$FY-UwgWkAUbUUAjKZIrySIhmkDwEniQHxhEw7QwbcGU',
        'admin'
    ),
    (
        'fan@example.com',
        'Fan',
        '$runtime-sign-in-code-hmac-sha256$v=1$26QkhMJZyJsBDiH3ae0NfkdhN2ynV41mmuBmMphzqB8',
        'fan'
    );
