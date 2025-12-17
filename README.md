# Binary Data Correction via SQL: Multi-Table Aggregation with In-Place Blob Modification

## Problem Statement

A legacy system stores critical numeric data within a large binary profile blob at a fixed byte offset (bytes 4749-4752). Due to a system bug, these values became desynchronized from their transaction history. The challenge: recalculate correct values from audit logs and update the binary blob **directly in SQL** without external application logic.

## Why This Was Considered "Impossible"

Senior system architects stated:
> "It's in the [binary] blob, not easily extracted and almost impossible to edit from MySQL directly... you need a program to do it."

The technical barriers:
- Binary data stored as 4-byte little-endian integers within large BLOB fields
- Required parsing binary data using ASCII byte extraction
- Needed to aggregate transaction history across multiple tables
- Had to reconstruct binary representation and perform in-place BLOB modification
- All operations must be atomic to prevent data corruption

## Solution Approach

**Phase 1: Parse and Calculate**
1. Extract 4-byte integer from binary blob using byte-by-byte ASCII parsing with proper endianness
2. Join audit logs with transaction reference tables to calculate required adjustment
3. Reconstruct corrected value as binary string with proper byte ordering

**Phase 2: Atomic Update**
1. Use MySQL's `REPLACE()` function on BLOB field to perform in-place modification
2. Dynamic length calculation ensures variable-length binary representations are handled correctly

## Technical Complexity

### Binary Parsing (Little-Endian)
(ASCII(MID(profile, 4749, 1))) +           -- Byte 1 (least significant)
(ASCII(MID(profile, 4750, 1)) * 256) +     -- Byte 2
(ASCII(MID(profile, 4751, 1)) * 65536) +   -- Byte 3
(ASCII(MID(profile, 4752, 1)) * 16777216)  -- Byte 4 (most significant)

### Multi-Table Join with Aggregation
- INNER JOIN across 3 tables
- GROUP BY with calculated fields
- Substring parsing from description fields to extract transaction codes

### Binary Reconstruction
REVERSE(CHAR(calculated_value))  -- Convert number back to binary representation

## Healthcare Analytics Applications

This pattern directly applies to:

**Epic Clarity/Caboodle Scenarios:**
- **Claims adjustment reconciliation**: Aggregate multiple claim line items and update patient account balances
- **Lab result corrections**: Recalculate aggregated values (e.g., panel totals) from component test results
- **Encounter-level financial reconciliation**: Sum procedure codes and update encounter-level billing totals

**Similar Technical Challenges:**
- Parsing HL7 message segments stored as text blobs
- Reconstructing hierarchical data from flat audit tables
- Atomic multi-record updates with calculated aggregations
- Legacy system data migration where binary formats must be preserved

## Performance Considerations

- Single-pass aggregation minimizes table scans
- Temporary table (`CREATE TABLE AS`) allows verification before UPDATE
- Atomic UPDATE with INNER JOIN ensures referential integrity
- Binary operations avoid expensive serialization/deserialization

## Skills Demonstrated

- **Advanced SQL**: Binary data manipulation, multi-table JOINs, GROUP BY with complex calculations
- **Data Architecture**: Understanding of binary storage formats and endianness
- **Problem Solving**: Solved a problem senior architects deemed "impossible" in pure SQL
- **Production Safety**: Two-phase approach (validate then update) prevents data corruption

## Impact

Successfully corrected data for thousands of records without:
- Writing external application code
- Taking the system offline
- Risking data corruption
- Manual record-by-record processing

---

**Author**: Matthew Miles
**Focus**: Healthcare IT Analytics | Epic Systems | Database Solutions
