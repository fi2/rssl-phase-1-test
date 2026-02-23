# RSSL Subcontractor API — Test Report

**Generated:** 2026-02-23 09:50:03 GMT
**Target:** `http://staging.api.rssl.com`
**API Version:** v0 (simulation)

## Summary

| Metric | Count |
|--------|-------|
| Total tests | 11 |
| Passed | 11 |
| Failed | 0 |
| Pass rate | 100.0% |

---

## 1. Authenticate — fetch access token

| | |
|---|---|
| **Status** | `PASS` |
| **HTTP Method** | `POST` |
| **Endpoint** | `/oauth2/token` |

**Request Body:**

```json
{
  "grant_type": "client_credentials",
  "client_id": "41ae877c-...",
  "client_secret": "fa5716e7-..."
}
```

**API Response:**

```json
{
  "access_token": "iMCguVRAO32y15bLJ07Hnop+svA3aLBNfL5uPlSPe...",
  "token_type": "bearer"
}
```

**Assertions:**

- [x] Token is a non-empty string

---

## 2. List all samples

| | |
|---|---|
| **Status** | `PASS` |
| **HTTP Method** | `GET` |
| **Endpoint** | `/raptor/v0/samples` |

**API Response:**

```json
{
  "samples": [
    {
      "sample_number": 101,
      "rssl_code": "X26-01001-2",
      "description": "Sample of chocolate"
    },
    {
      "sample_number": 102,
      "rssl_code": "X26-01021-1A",
      "description": "Assorted biscuits"
    },
    {
      "sample_number": 103,
      "rssl_code": "X26-02877-38",
      "description": "Crunchy frog"
    }
  ]
}
```

**Assertions:**

- [x] Response contains 'samples' key
- [x] 'samples' is an array
- [x] Array is not empty
- [x] Each sample has 'sample_number'
- [x] Each sample has 'rssl_code'
- [x] Each sample has 'description'

---

## 3. Get a single sample

| | |
|---|---|
| **Status** | `PASS` |
| **HTTP Method** | `GET` |
| **Endpoint** | `/raptor/v0/samples/101` |

**API Response:**

```json
{
  "sample_number": 101,
  "rssl_code": "X26-01001-2",
  "description": "Sample of chocolate"
}
```

**Assertions:**

- [x] Response contains 'sample_number'
- [x] sample_number matches requested id (101)
- [x] Response contains 'rssl_code'
- [x] Response contains 'description'

---

## 4. List results for a sample

| | |
|---|---|
| **Status** | `PASS` |
| **HTTP Method** | `GET` |
| **Endpoint** | `/raptor/v0/samples/101/results` |

**API Response:**

```json
{
  "results": []
}
```

**Assertions:**

- [x] Response contains 'results' key
- [x] 'results' is an array

---

## 5. Create a single result

| | |
|---|---|
| **Status** | `PASS` |
| **HTTP Method** | `POST` |
| **Endpoint** | `/raptor/v0/samples/101/results` |

**Request Body:**

```json
{
  "result_name": "Report Test Single",
  "result_value": "99.9"
}
```

**API Response:**

```json
{}
```

**Assertions:**

- [x] API returns a hash (empty JSON object)
- [x] New result appears in results list
- [x] Created result has correct name
- [x] Created result has correct value

---

## 6. Create multiple results (batch)

| | |
|---|---|
| **Status** | `PASS` |
| **HTTP Method** | `POST` |
| **Endpoint** | `/raptor/v0/samples/101/results` |

**Request Body:**

```json
{
  "results": [
    {
      "result_name": "Report Batch A",
      "result_value": "10.0"
    },
    {
      "result_name": "Report Batch B",
      "result_value": "20.0"
    }
  ]
}
```

**API Response:**

```json
{}
```

**Assertions:**

- [x] API returns a hash (empty JSON object)
- [x] Batch result A appears in results list
- [x] Batch result B appears in results list
- [x] Batch result A has correct value
- [x] Batch result B has correct value

---

## 7. Get a single result

| | |
|---|---|
| **Status** | `PASS` |
| **HTTP Method** | `GET` |
| **Endpoint** | `/raptor/v0/samples/101/results/1023` |

**API Response:**

```json
{
  "result_number": 1023,
  "sample_number": 101,
  "result_name": "Report Test Single",
  "result_value": "99.9"
}
```

**Assertions:**

- [x] result_number matches requested id
- [x] sample_number matches 101
- [x] result_name is 'Report Test Single'
- [x] result_value is '99.9'

---

## 8. Update a result value

| | |
|---|---|
| **Status** | `PASS` |
| **HTTP Method** | `PUT` |
| **Endpoint** | `/raptor/v0/samples/101/results/1023` |

**Request Body:**

```json
{
  "result_value": "UPDATED-777"
}
```

**API Response:**

```json
{}
```

**Assertions:**

- [x] API returns a hash (empty JSON object)
- [x] result_value was updated to 'UPDATED-777'

---

## 9. Delete a result

| | |
|---|---|
| **Status** | `PASS` |
| **HTTP Method** | `DELETE` |
| **Endpoint** | `/raptor/v0/samples/101/results/1023` |

**API Response:**

```json
{}
```

**Assertions:**

- [x] API returns a hash (empty JSON object)

---

## 10. Verify deleted result is gone

| | |
|---|---|
| **Status** | `PASS` |
| **HTTP Method** | `GET` |
| **Endpoint** | `/raptor/v0/samples/101/results` |

**API Response:**

```json
{
  "remaining_result_ids": [
    1024,
    1025
  ]
}
```

**Assertions:**

- [x] Deleted result no longer appears in results list

---

## 11. Unauthenticated request is rejected by client

| | |
|---|---|
| **Status** | `PASS` |
| **HTTP Method** | `N/A` |
| **Endpoint** | `N/A (client-side guard)` |

**API Response:**

```json
{
  "error": "No access token. Call fetch_access_token first."
}
```

**Assertions:**

- [x] RuntimeError is raised
- [x] Error message mentions missing token

---
