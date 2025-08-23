# Test API Endpoints untuk Timesheet dengan Employee Filter

## Endpoints yang Dibutuhkan di Backend Laravel:

### 1. GET /api/timesheet/employees
**Description:** Mendapatkan daftar employee yang memiliki timesheet
**Response Format:**
```json
{
  "success": true,
  "data": [
    {
      "empno": "EMP001",
      "name": "John Doe",
      "fullname": "John Doe Smith"
    },
    {
      "empno": "EMP002", 
      "name": "Jane Smith",
      "fullname": "Jane Smith Wilson"
    }
  ]
}
```

### 2. GET /api/timesheet/periods?empno=EMP001&period=202401
**Description:** Mendapatkan timesheet dengan filter employee dan/atau period
**Query Parameters:**
- `empno` (optional): Employee number untuk filter
- `period` (optional): Period untuk filter

**Response Format:**
```json
{
  "success": true,
  "data": [
    {
      "period": "202401",
      "period_formatted": "January 2024",
      "filename": "timesheet_202401_EMP001.pdf",
      "file_size_mb": 2.5,
      "page_count": 5,
      "employee_name": "John Doe",
      "empno": "EMP001",
      "has_pdf": true,
      "access_info": {
        "pdf_url": "http://localhost:8000/api/timesheet/extract-page/202401?empno=EMP001"
      },
      "created_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

### 3. GET /api/timesheet/extract-page/{period}?empno=EMP001
**Description:** Download PDF timesheet untuk period dan employee tertentu
**Query Parameters:**
- `empno` (optional): Employee number untuk filter

**Response:** Binary PDF file

## Testing dengan cURL:

```bash
# Test get employees list
curl -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Accept: application/json" \
     http://localhost:8000/api/timesheet/employees

# Test get timesheet with employee filter
curl -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Accept: application/json" \
     "http://localhost:8000/api/timesheet/periods?empno=EMP001"

# Test download PDF with employee filter  
curl -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Accept: application/pdf" \
     "http://localhost:8000/api/timesheet/extract-page/202401?empno=EMP001" \
     --output timesheet_202401_EMP001.pdf
```

## Notes:
1. Backend Laravel perlu diupdate untuk mendukung parameter `empno` 
2. Endpoint `/api/timesheet/employees` perlu dibuat baru
3. Endpoint existing perlu dimodifikasi untuk support filter empno
