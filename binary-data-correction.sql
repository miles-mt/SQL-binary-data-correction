-- Binary Data Correction via SQL
-- Author: Matthew Miles
-- Challenge: Parse and update 4-byte integers stored in binary BLOB without external programs

-- Complex Data Recovery: Binary Blob Parsing with Multi-Table Aggregation
CREATE TABLE data_correction AS
SELECT
    patient.id AS PatientID,
    audit_log.patient_name AS PatientName,

    -- Parse 4-byte integer from binary profile data (little-endian)
    (ASCII(MID(clinical_profile, 4749, 1))) + 
    (ASCII(MID(clinical_profile, 4750, 1)) * 256) + 
    (ASCII(MID(clinical_profile, 4751, 1)) * 65536) + 
    (ASCII(MID(clinical_profile, 4752, 1)) * 16777216) AS current_balance,
    -- Calculate total adjustment needed from transaction history
    SUM((SUBSTRING(description, 7, 2) * transaction_types.cost_value)) AS total_adjustment,
    
    -- Reconstruct binary representation of corrected value
    REVERSE(CHAR(
        (ASCII(MID(clinical_profile, 4749, 1))) + 
        (ASCII(MID(clinical_profile, 4750, 1)) * 256) + 
        (ASCII(MID(clinical_profile, 4751, 1)) * 65536) + 
        (ASCII(MID(clinical_profile, 4752, 1)) * 16777216) + 
        SUM((SUBSTRING(description, 7, 2) * transaction_types.cost_value))
    )) AS corrected_binary,
 
    -- Calculate length for binary replacement
    LENGTH(REVERSE(CHAR(
        (ASCII(MID(clinical_profile, 4749, 1))) + 
        (ASCII(MID(clinical_profile, 4750, 1)) * 256) + 
        (ASCII(MID(clinical_profile, 4751, 1)) * 65536) + 
        (ASCII(MID(clinical_profile, 4752, 1)) * 16777216) + 
        SUM((SUBSTRING(description, 7, 2) * transaction_types.cost_value))
    ))) AS binary_length
FROM
    audit_log
    INNER JOIN patient ON audit_log.patient_name = patient.name
    INNER JOIN transaction_types ON LTRIM(SUBSTRING(description, 40, 8)) = transaction_types.id
WHERE 
    event_type_id = '3' 
    AND LTRIM(SUBSTRING(description, 29, 3)) = '0'
GROUP BY PatientID;

-- Apply corrections to binary profile data
UPDATE patient
    INNER JOIN data_correction ON patient.id = data_correction.PatientID
SET patient.clinical_profile = REPLACE(
    patient.clinical_profile, 
    MID(clinical_profile, 4749, data_correction.binary_length), 
    data_correction.corrected_binary
);
