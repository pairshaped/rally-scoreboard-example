-- Demo users for local development and smoke tests.
--
-- Sign-in code hashes are HMAC-SHA256 outputs using Rally runtime's encoded
-- hash format.
--
-- Admin:  admin@example.com / code A1Z9Q / role = 'admin'
-- Fan:    fan@example.com   / code A1Z9Q / role = 'fan'

INSERT INTO users (email, display_name, sign_in_code_hash, role)
VALUES
    (
        'admin@example.com',
        NULL,
        '$rally-login-code-hmac-sha256$v=1$SUvc9TOau_HmvzxwSkduw2POVNDwqq1x-HetwIF28_E',
        'admin'
    ),
    (
        'fan@example.com',
        'Fan',
        '$rally-login-code-hmac-sha256$v=1$LP3OoxyYmVWZb9RiH3vWI20CNh5-SkpRUIucN0IxQ4s',
        'fan'
    )
ON CONFLICT(email) DO UPDATE SET
    sign_in_code_hash = excluded.sign_in_code_hash,
    role = excluded.role;
