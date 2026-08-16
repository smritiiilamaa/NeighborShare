-- Create a donor account and get its account_id

WITH new_account AS (
    INSERT INTO user_accounts
    (
        email,
        password_hash,
        role
    )
    VALUES
    (
        'camanze@my.centennialcollege.ca',
        'password123',
        'Donor'
    )
    RETURNING account_id
)

INSERT INTO donor_profiles
(
    account_id,
    full_name,
    email,
    phone_number,
    street_address,
    city,
    postal_code
)
SELECT
    account_id,
    'Emmanuel Chimaobi',
    'camanze@my.centennialcollege.ca',
    '4165551111',
    '941 Progress Ave',
    'Toronto',
    'M1P 4P5'
FROM new_account;
