USE person;

-- =============================================================
-- Person.Address
-- =============================================================
DROP TABLE IF EXISTS address;
CREATE TABLE address (
    address_id BIGINT PRIMARY KEY,
    address_line1 VARCHAR(60),
    address_line2 VARCHAR(60),
    city VARCHAR(30),
    state_province_id INT,
    postal_code VARCHAR(15),
    spatial_location TEXT,
    rowguid CHAR(36),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================
-- Person.AddressType
-- =============================================================
DROP TABLE IF EXISTS address_type;
CREATE TABLE address_type (
    address_type_id INT PRIMARY KEY,
    name VARCHAR(50),
    rowguid CHAR(36),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================
-- Person.BusinessEntity
-- =============================================================
DROP TABLE IF EXISTS business_entity;
CREATE TABLE business_entity (
    business_entity_id BIGINT PRIMARY KEY,
    rowguid CHAR(36),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================
-- Person.BusinessEntityAddress
-- =============================================================
DROP TABLE IF EXISTS business_entity_address;
CREATE TABLE business_entity_address (
    business_entity_id BIGINT,
    address_id BIGINT,
    address_type_id INT,
    rowguid CHAR(36),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (business_entity_id, address_id, address_type_id)
);

-- =============================================================
-- Person.BusinessEntityContact
-- =============================================================
DROP TABLE IF EXISTS business_entity_contact;
CREATE TABLE business_entity_contact (
    business_entity_id BIGINT,
    person_id BIGINT,
    contact_type_id INT,
    rowguid CHAR(36),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (business_entity_id, person_id, contact_type_id)
);

-- =============================================================
-- Person.ContactType
-- =============================================================
DROP TABLE IF EXISTS contact_type;
CREATE TABLE contact_type (
    contact_type_id INT PRIMARY KEY,
    name VARCHAR(50),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================
-- Person.CountryRegion
-- =============================================================
DROP TABLE IF EXISTS country_region;
CREATE TABLE country_region (
    country_region_code VARCHAR(3) PRIMARY KEY,
    name VARCHAR(50),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================
-- Person.EmailAddress
-- =============================================================
DROP TABLE IF EXISTS email_address;
CREATE TABLE email_address (
    business_entity_id BIGINT,
    email_address_id INT,
    email_address VARCHAR(50),
    rowguid CHAR(36),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (business_entity_id, email_address_id)
);

-- =============================================================
-- Person.Password
-- =============================================================
DROP TABLE IF EXISTS password;
CREATE TABLE password (
    business_entity_id BIGINT PRIMARY KEY,
    password_hash VARCHAR(128),
    password_salt VARCHAR(10),
    rowguid CHAR(36),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================
-- Person.Person
-- =============================================================
DROP TABLE IF EXISTS person;
CREATE TABLE person (
    business_entity_id BIGINT PRIMARY KEY,
    person_type CHAR(2),
    name_style TINYINT(1) DEFAULT 0,
    title VARCHAR(8),
    first_name VARCHAR(50),
    middle_name VARCHAR(50),
    last_name VARCHAR(50),
    suffix VARCHAR(10),
    email_promotion SMALLINT DEFAULT 0,
    additional_contact_info TEXT,
    demographics TEXT,
    rowguid CHAR(36),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================
-- Person.PersonPhone
-- =============================================================
DROP TABLE IF EXISTS person_phone;
CREATE TABLE person_phone (
    business_entity_id BIGINT,
    phone_number VARCHAR(25),
    phone_number_type_id INT,
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (business_entity_id, phone_number, phone_number_type_id)
);

-- =============================================================
-- Person.PhoneNumberType
-- =============================================================
DROP TABLE IF EXISTS phone_number_type;
CREATE TABLE phone_number_type (
    phone_number_type_id INT PRIMARY KEY,
    name VARCHAR(50),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================
-- Person.StateProvince
-- =============================================================
DROP TABLE IF EXISTS state_province;
CREATE TABLE state_province (
    state_province_id INT PRIMARY KEY,
    state_province_code CHAR(3),
    country_region_code VARCHAR(3),
    is_only_state_province_flag TINYINT(1) DEFAULT 1,
    name VARCHAR(50),
    territory_id INT,
    rowguid CHAR(36),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

