--Donor_profiles--

-- User accounts
CREATE TABLE user_accounts (
    account_id SERIAL PRIMARY KEY,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role VARCHAR(20) NOT NULL
        CHECK (role IN ('Donor', 'Recipient', 'Administrator')),
    account_status VARCHAR(20) NOT NULL DEFAULT 'Active'
        CHECK (account_status IN ('Active', 'Banned')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Donor profiles
CREATE TABLE donor_profiles (
    donor_id SERIAL PRIMARY KEY,

    account_id INTEGER UNIQUE NOT NULL,

    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    street_address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_donor_account
        FOREIGN KEY (account_id)
        REFERENCES user_accounts(account_id)
        ON DELETE CASCADE
);

--Recipient_profiles--
CREATE TABLE recipient_profiles (
    recipient_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    street_address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,

    dietary_preference VARCHAR(50) NOT NULL DEFAULT 'None'
        CHECK (
            dietary_preference IN (
                'None',
                'Vegetarian',
                'Vegan',
                'Gluten-Free',
                'Dairy-Free',
                'Nut-Free',
                'Halal',
                'Kosher'
            )
        ),

    allergies TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

--Food_listings--
CREATE TABLE food_listings (
    listing_id SERIAL PRIMARY KEY,

    donor_id INTEGER NOT NULL,

    food_name VARCHAR(100) NOT NULL,

    category VARCHAR(50) NOT NULL
        CHECK (
            category IN (
                'Cooked Meals',
                'Bakery',
                'Fruits',
                'Vegetables',
                'Other'
            )
        ),

    quantity VARCHAR(50) NOT NULL,

    pickup_location VARCHAR(255) NOT NULL,

    description TEXT,

    status VARCHAR(20) NOT NULL DEFAULT 'Available'
        CHECK (
            status IN (
                'Available',
                'Reserved',
                'Collected',
                'Expired',
                'Cancelled'
            )
        ),

    expiry_date DATE,

    is_flagged BOOLEAN NOT NULL DEFAULT FALSE,
    flag_reason TEXT,
    flagged_by VARCHAR(150),
    flagged_at TIMESTAMP,
    moderation_status VARCHAR(20) NOT NULL DEFAULT 'Pending'
        CHECK (
            moderation_status IN ('Pending', 'Under Review', 'Resolved')
        ),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_listing_donor
        FOREIGN KEY (donor_id)
        REFERENCES donor_profiles(donor_id)
        ON DELETE CASCADE
);

--Food_requests--
CREATE TABLE food_requests (
    request_id SERIAL PRIMARY KEY,

    listing_id INTEGER NOT NULL,
    recipient_id INTEGER NOT NULL,

    message TEXT,

    request_status VARCHAR(20) NOT NULL DEFAULT 'Pending'
        CHECK (
            request_status IN (
                'Pending',
                'Approved',
                'Rejected',
                'Cancelled',
                'Completed'
            )
        ),

    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_request_listing
        FOREIGN KEY (listing_id)
        REFERENCES food_listings(listing_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_request_recipient
        FOREIGN KEY (recipient_id)
        REFERENCES recipient_profiles(recipient_id)
        ON DELETE CASCADE,

    CONSTRAINT unique_recipient_listing_request
        UNIQUE (listing_id, recipient_id)
);

--Messages--
CREATE TABLE messages (
    message_id SERIAL PRIMARY KEY,
    donor_id INTEGER NOT NULL,
    recipient_id INTEGER NOT NULL,
    message TEXT NOT NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT fk_messages_donor
        FOREIGN KEY (donor_id)
        REFERENCES donor_profiles(donor_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_messages_recipient
        FOREIGN KEY (recipient_id)
        REFERENCES recipient_profiles(recipient_id)
        ON DELETE CASCADE
);

--Incident_reports--
CREATE TABLE incident_reports (
    incident_id SERIAL PRIMARY KEY,
    admin_id INTEGER,
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    reported_by VARCHAR(150),
    status VARCHAR(20) NOT NULL DEFAULT 'Open'
        CHECK (status IN ('Open', 'Investigating', 'Resolved')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_incident_admin
        FOREIGN KEY (admin_id)
        REFERENCES user_accounts(account_id)
);

