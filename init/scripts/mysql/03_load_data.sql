SET GLOBAL local_infile=1;

-- =============================================================
-- Load data for PERSON database
-- =============================================================
USE person;

LOAD DATA INFILE '/init/data/mysql/Person_BusinessEntity.csv'
INTO TABLE business_entity
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(business_entity_id, rowguid, modified_date);

LOAD DATA INFILE '/init/data/mysql/Person_AddressType.csv'
INTO TABLE address_type
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(address_type_id, name, rowguid, modified_date);

LOAD DATA INFILE '/init/data/mysql/Person_PhoneNumberType.csv'
INTO TABLE phone_number_type
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(phone_number_type_id, name, modified_date);

LOAD DATA INFILE '/init/data/mysql/Person_ContactType.csv'
INTO TABLE contact_type
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(contact_type_id, name, modified_date);

LOAD DATA INFILE '/init/data/mysql/Person_CountryRegion.csv'
INTO TABLE country_region
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(country_region_code, name, modified_date);

LOAD DATA INFILE '/init/data/mysql/Person_StateProvince.csv'
INTO TABLE state_province
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(state_province_id, state_province_code, country_region_code, @is_only_state_province_flag, name, territory_id, rowguid, modified_date)
SET is_only_state_province_flag = CASE
        WHEN LOWER(@is_only_state_province_flag) IN ('true', '1') THEN 1
        ELSE 0
    END;

LOAD DATA INFILE '/init/data/mysql/Person_Address.csv'
INTO TABLE address
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(address_id, address_line1, address_line2, city, state_province_id, postal_code, spatial_location, rowguid, modified_date);

LOAD DATA INFILE '/init/data/mysql/Person_BusinessEntityAddress.csv'
INTO TABLE business_entity_address
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(business_entity_id, address_id, address_type_id, rowguid, modified_date);

LOAD DATA INFILE '/init/data/mysql/Person_Person.csv'
INTO TABLE person
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(business_entity_id, person_type, @name_style_raw, title, first_name, middle_name, last_name, suffix, email_promotion, additional_contact_info, demographics, rowguid, modified_date)
SET name_style = CASE
        WHEN LOWER(@name_style_raw) IN ('true', '1') THEN 1
        ELSE 0
    END;

LOAD DATA INFILE '/init/data/mysql/Person_EmailAddress.csv'
INTO TABLE email_address
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(business_entity_id, email_address_id, email_address, rowguid, modified_date);

LOAD DATA INFILE '/init/data/mysql/Person_Password.csv'
INTO TABLE password
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(business_entity_id, password_hash, password_salt, rowguid, modified_date);

LOAD DATA INFILE '/init/data/mysql/Person_BusinessEntityContact.csv'
INTO TABLE business_entity_contact
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(business_entity_id, person_id, contact_type_id, rowguid, modified_date);

LOAD DATA INFILE '/init/data/mysql/Person_PersonPhone.csv'
INTO TABLE person_phone
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(business_entity_id, phone_number, phone_number_type_id, modified_date);

-- =============================================================
-- Load data for HUMAN_RESOURCES database
-- =============================================================
USE human_resources;

LOAD DATA INFILE '/init/data/mysql/HumanResources_Department.csv'
INTO TABLE department
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(department_id, name, group_name, modified_date);

LOAD DATA INFILE '/init/data/mysql/HumanResources_Shift.csv'
INTO TABLE shift
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(shift_id, name, start_time, end_time, modified_date);

LOAD DATA INFILE '/init/data/mysql/HumanResources_Employee.csv'
INTO TABLE employee
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(business_entity_id, national_id_number, login_id, organization_node, @organization_level_raw, job_title, birth_date, marital_status, gender, hire_date, @salaried_flag_raw, vacation_hours, sick_leave_hours, @current_flag_raw, rowguid, modified_date)
SET salaried_flag = CASE
        WHEN LOWER(@salaried_flag_raw) IN ('true', '1') THEN 1
        ELSE 0
    END,
    current_flag = CASE
        WHEN LOWER(@current_flag_raw) IN ('true', '1') THEN 1
        ELSE 0
    END,
    organization_level = NULLIF(@organization_level_raw, '');

LOAD DATA INFILE '/init/data/mysql/HumanResources_EmployeeDepartmentHistory.csv'
INTO TABLE employee_department_history
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(business_entity_id, department_id, shift_id, start_date, @end_date_raw, modified_date)
SET end_date = NULLIF(@end_date_raw, '');

LOAD DATA INFILE '/init/data/mysql/HumanResources_EmployeePayHistory.csv'
INTO TABLE employee_pay_history
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(business_entity_id, rate_change_date, rate, pay_frequency, modified_date);

LOAD DATA INFILE '/init/data/mysql/HumanResources_JobCandidate.csv'
INTO TABLE job_candidate
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(job_candidate_id, @business_entity_id_raw, resume, modified_date)
SET business_entity_id = NULLIF(@business_entity_id_raw, '');