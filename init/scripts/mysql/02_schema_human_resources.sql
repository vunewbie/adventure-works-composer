USE human_resources;

-- =============================================================
-- HumanResources.Department
-- =============================================================
DROP TABLE IF EXISTS department;
CREATE TABLE department (
    department_id INT PRIMARY KEY,
    name VARCHAR(50),
    group_name VARCHAR(50),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================
-- HumanResources.Employee
-- =============================================================
DROP TABLE IF EXISTS employee;
CREATE TABLE employee (
    business_entity_id BIGINT PRIMARY KEY,
    national_id_number VARCHAR(15),
    login_id VARCHAR(256),
    organization_node BLOB,
    organization_level SMALLINT,
    job_title VARCHAR(50),
    birth_date DATE,
    marital_status CHAR(1),
    gender CHAR(1),
    hire_date DATE,
    salaried_flag TINYINT(1) DEFAULT 1,
    vacation_hours SMALLINT DEFAULT 0,
    sick_leave_hours SMALLINT DEFAULT 0,
    current_flag TINYINT(1) DEFAULT 1,
    rowguid CHAR(36),
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================
-- HumanResources.EmployeeDepartmentHistory
-- =============================================================
DROP TABLE IF EXISTS employee_department_history;
CREATE TABLE employee_department_history (
    business_entity_id BIGINT,
    department_id INT,
    shift_id INT,
    start_date DATE,
    end_date DATE,
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (business_entity_id, department_id, shift_id, start_date)
);

-- =============================================================
-- HumanResources.EmployeePayHistory
-- =============================================================
DROP TABLE IF EXISTS employee_pay_history;
CREATE TABLE employee_pay_history (
    business_entity_id BIGINT,
    rate_change_date TIMESTAMP,
    rate DECIMAL(19,4),
    pay_frequency SMALLINT,
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (business_entity_id, rate_change_date)
);

-- =============================================================
-- HumanResources.JobCandidate
-- =============================================================
DROP TABLE IF EXISTS job_candidate;
CREATE TABLE job_candidate (
    job_candidate_id BIGINT PRIMARY KEY,
    business_entity_id BIGINT,
    resume TEXT,
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================
-- HumanResources.Shift
-- =============================================================
DROP TABLE IF EXISTS shift;
CREATE TABLE shift (
    shift_id INT PRIMARY KEY,
    name VARCHAR(50),
    start_time TIME,
    end_time TIME,
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

