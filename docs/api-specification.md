# JagaFinance REST API Specification

## Base URL
```
Development: http://localhost:3001/api/v1
Production:  https://api.jagafinance.com/api/v1
```

## Authentication
All endpoints require JWT token via `Authorization: Bearer <token>` header, except auth endpoints.

## Response Format

### Success Response
```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "totalPages": 8
  }
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      }
    ]
  }
}
```

---

## 1. AUTHENTICATION

### 1.1 Register
```
POST /auth/register
```
**Request:**
```json
{
  "email": "user@company.com",
  "password": "securePassword123!",
  "name": "John Doe",
  "tenantName": "My Company",
  "tenantSlug": "my-company",
  "language": "id"
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "data": {
    "user": { "id": "...", "email": "...", "name": "..." },
    "tenant": { "id": "...", "name": "My Company", "slug": "my-company" },
    "accessToken": "...",
    "refreshToken": "..."
  }
}
```

### 1.2 Login
```
POST /auth/login
```
**Request:**
```json
{
  "email": "user@company.com",
  "password": "securePassword123!"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "user": { "id": "...", "email": "...", "name": "..." },
    "tenants": [
      { "id": "...", "name": "...", "slug": "...", "role": "ADMIN" }
    ],
    "accessToken": "...",
    "refreshToken": "..."
  }
}
```

### 1.3 Refresh Token
```
POST /auth/refresh
```
**Request:** `{ "refreshToken": "..." }`

**Response:** `200 OK` - New access + refresh tokens

### 1.4 Logout
```
POST /auth/logout
```
**Response:** `200 OK`

### 1.5 Forgot Password
```
POST /auth/forgot-password
```
**Request:** `{ "email": "user@company.com" }`

**Response:** `200 OK` - Email sent

### 1.6 Reset Password
```
POST /auth/reset-password
```
**Request:**
```json
{
  "token": "...",
  "newPassword": "newSecurePassword123!"
}
```

**Response:** `200 OK`

---

## 2. TENANTS

### 2.1 Get Current Tenant
```
GET /tenants/current
```
**Response:** `200 OK` - Full tenant object with membership info

### 2.2 Update Tenant
```
PATCH /tenants/current
```
**Request:**
```json
{
  "name": "New Company Name",
  "industry": "retail",
  "currency": "IDR",
  "timezone": "Asia/Jakarta",
  "language": "en",
  "settings": { "receipt_retention_days": 365 }
}
```

### 2.3 Get Tenant Members
```
GET /tenants/current/members
```
**Query:** `?page=1&limit=20&role=ADMIN&status=ACCEPTED`

**Response:** `200 OK` - List of tenant members with user details

### 2.4 Update Member Role
```
PATCH /tenants/current/members/:memberId
```
**Request:** `{ "role": "FINANCE" }`

### 2.5 Remove Member
```
DELETE /tenants/current/members/:memberId
```

---

## 3. INVITES

### 3.1 Send Invite
```
POST /tenants/current/invites
```
**Request:**
```json
{
  "email": "newuser@company.com",
  "role": "FINANCE"
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "data": { "id": "...", "email": "...", "role": "FINANCE", "status": "PENDING" }
}
```

### 3.2 List Invites
```
GET /tenants/current/invites
```
**Query:** `?status=PENDING&page=1&limit=20`

### 3.3 Cancel Invite
```
DELETE /tenants/current/invites/:inviteId
```

### 3.4 Accept Invite
```
POST /invites/:token/accept
```
**Request:**
```json
{
  "password": "securePassword123!",
  "name": "New User"
}
```

---

## 4. RECEIPTS

### 4.1 Upload Receipt
```
POST /receipts/upload
```
**Content-Type:** `multipart/form-data`

**Fields:**
- `file`: Image file (JPG, PNG, PDF, max 10MB)
- `title`: Optional receipt title
- `category_id`: Optional category assignment
- `expense_date`: Optional expense date override

**Response:** `201 Created`
```json
{
  "success": true,
  "data": {
    "id": "...",
    "status": "UPLOADED",
    "fileUrl": "https://...",
    "fileName": "receipt.jpg",
    "createdAt": "2024-01-15T10:30:00Z"
  }
}
```

### 4.2 List Receipts
```
GET /receipts
```
**Query:**
```
?status=COMPLETED
&category_id=...
&date_from=2024-01-01
&date_to=2024-01-31
&merchant_name=...
&sort=created_at
&order=desc
&page=1
&limit=20
```

### 4.3 Get Receipt Detail
```
GET /receipts/:id
```
**Response:** `200 OK` - Receipt with full OCR data

### 4.4 Review/Verify Receipt OCR
```
POST /receipts/:id/review
```
**Request:**
```json
{
  "action": "approve",  // approve | reject | edit
  "corrections": {
    "merchant_name": "Correct Merchant Name",
    "total_amount": 150000,
    "transaction_date": "2024-01-15"
  },
  "notes": "Fixed tax amount"
}
```

### 4.5 Delete Receipt
```
DELETE /receipts/:id
```
**Permission:** ADMIN only

---

## 5. EXPENSES

### 5.1 Create Expense
```
POST /expenses
```
**Request:**
```json
{
  "receipt_id": "...",
  "category_id": "...",
  "title": "Office Supplies",
  "description": "Printer paper and ink",
  "amount": 250000,
  "currency": "IDR",
  "expense_date": "2024-01-15",
  "payment_method": "transfer",
  "tax_deductible": true,
  "tags": ["office", "supplies"],
  "cost_center": "ADMIN",
  "project_code": "PRJ-001"
}
```

### 5.2 List Expenses
```
GET /expenses
```
**Query:**
```
?category_id=...
&status=CONFIRMED
&date_from=2024-01-01
&date_to=2024-01-31
&tags=office,supplies
&created_by=...
&search=printer
&sort=expense_date
&order=desc
&page=1
&limit=20
```

### 5.3 Get Expense Detail
```
GET /expenses/:id
```

### 5.4 Update Expense
```
PATCH /expenses/:id
```

### 5.5 Delete Expense
```
DELETE /expenses/:id
```
**Permission:** ADMIN only

### 5.6 Bulk Update Expenses
```
PATCH /expenses/bulk
```
**Request:**
```json
{
  "ids": ["...", "..."],
  "updates": {
    "status": "CONFIRMED",
    "category_id": "..."
  }
}
```

---

## 6. CATEGORIES

### 6.1 List Categories
```
GET /categories
```
**Query:** `?is_active=true&parent_id=null`

### 6.2 Create Category
```
POST /categories
```
**Request:**
```json
{
  "name": "Transportasi",
  "name_en": "Transportation",
  "color": "#3B82F6",
  "icon": "car",
  "parent_id": null,
  "sort_order": 1
}
```

### 6.3 Update Category
```
PATCH /categories/:id
```

### 6.4 Delete Category
```
DELETE /categories/:id
```

---

## 7. BUDGETS

### 7.1 List Budgets
```
GET /budgets
```
**Query:** `?period=MONTHLY&is_active=true&category_id=...`

### 7.2 Create Budget
```
POST /budgets
```
**Request:**
```json
{
  "category_id": "...",
  "amount": 5000000,
  "currency": "IDR",
  "period": "MONTHLY",
  "start_date": "2024-01-01",
  "end_date": "2024-01-31",
  "alert_threshold": 80
}
```

### 7.3 Update Budget
```
PATCH /budgets/:id
```

### 7.4 Delete Budget
```
DELETE /budgets/:id
```

### 7.5 Get Budget Usage
```
GET /budgets/:id/usage
```
**Response:**
```json
{
  "success": true,
  "data": {
    "budget": { "id": "...", "amount": 5000000, "period": "MONTHLY" },
    "spent": 3750000,
    "remaining": 1250000,
    "percentage": 75,
    "category": { "name": "Transportasi" },
    "alert_triggered": false,
    "next_threshold": 80
  }
}
```

---

## 8. DASHBOARD & ANALYTICS

### 8.1 Dashboard Overview
```
GET /dashboard/overview
```
**Query:** `?period=month&date=2024-01`

**Response:**
```json
{
  "success": true,
  "data": {
    "total_expenses": 45000000,
    "total_receipts": 127,
    "pending_reviews": 8,
    "budget_alerts": 2,
    "expenses_by_category": [
      { "category": "Transportasi", "amount": 12000000, "percentage": 26.7 },
      { "category": "Makanan", "amount": 8000000, "percentage": 17.8 }
    ],
    "monthly_trend": [
      { "month": "2023-11", "amount": 38000000 },
      { "month": "2023-12", "amount": 42000000 },
      { "month": "2024-01", "amount": 45000000 }
    ]
  }
}
```

### 8.2 Expense Analytics
```
GET /analytics/expenses
```
**Query:**
```
?group_by=category
&date_from=2024-01-01
&date_to=2024-01-31
&comparison=previous  // previous | year_ago
```

**Response:**
```json
{
  "success": true,
  "data": {
    "current_period": { "total": 45000000, "count": 127 },
    "previous_period": { "total": 42000000, "count": 115 },
    "change_percentage": 7.14,
    "breakdown": [
      {
        "category": "Transportasi",
        "current": 12000000,
        "previous": 10000000,
        "change": 20
      }
    ]
  }
}
```

### 8.3 Tax Summary
```
GET /analytics/tax
```
**Query:** `?period=month&date=2024-01`

**Response:**
```json
{
  "success": true,
  "data": {
    "total_tax_collected": 5500000,
    "tax_deductible_expenses": 32000000,
    "estimated_tax_savings": 3200000,
    "receipts_with_tax": 45,
    "average_tax_rate": 11.0
  }
}
```

---

## 9. EXPORTS

### 9.1 Create Export Job
```
POST /exports
```
**Request:**
```json
{
  "format": "XLSX",        // XLSX | CSV | PDF
  "export_type": "expenses", // expenses | receipts | budget_report | tax_summary
  "filters": {
    "date_from": "2024-01-01",
    "date_to": "2024-01-31",
    "category_id": "...",
    "accounting_format": "jurnal"  // jurnal | accurate | standard
  }
}
```

### 9.2 Get Export Status
```
GET /exports/:id
```

### 9.3 List Exports
```
GET /exports
```

### 9.4 Download Export
```
GET /exports/:id/download
```
Returns file download

---

## 10. WEBHOOKS (M4)

### 10.1 List Webhooks
```
GET /webhooks
```

### 10.2 Create Webhook
```
POST /webhooks
```
**Request:**
```json
{
  "url": "https://your-app.com/webhook/jagafinance",
  "events": ["RECEIPT_PROCESSED", "BUDGET_EXCEEDED"],
  "secret": "your-webhook-secret"
}
```

### 10.3 Update Webhook
```
PATCH /webhooks/:id
```

### 10.4 Delete Webhook
```
DELETE /webhooks/:id
```

### 10.5 Get Webhook Deliveries
```
GET /webhooks/:id/deliveries
```

### 10.6 Retry Delivery
```
POST /webhooks/:id/deliveries/:deliveryId/retry
```

---

## 11. API KEYS (M4)

### 11.1 Create API Key
```
POST /api-keys
```
**Request:**
```json
{
  "name": "Integration Key",
  "permissions": ["receipts:read", "receipts:write", "expenses:read"],
  "expires_at": "2025-01-01"
}
```

**Response:** Returns full key ONCE at creation
```json
{
  "success": true,
  "data": {
    "id": "...",
    "name": "Integration Key",
    "key": "vl_xxx_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    "keyPrefix": "vl_xxx_",
    "permissions": [...],
    "expiresAt": "2025-01-01"
  }
}
```

### 11.2 List API Keys
```
GET /api-keys
```

### 11.3 Revoke API Key
```
POST /api-keys/:id/revoke
```

---

## 12. AUDIT LOGS

### 12.1 List Audit Logs
```
GET /audit-logs
```
**Query:**
```
?action=CREATE
&entity_type=receipt
&user_id=...
&date_from=2024-01-01
&date_to=2024-01-31
&page=1
&limit=50
```
**Permission:** ADMIN only

---

## 13. HEALTH CHECK

### 13.1 API Health
```
GET /health
```
**Response:** `200 OK`
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "services": {
    "database": "connected",
    "redis": "connected",
    "storage": "connected"
  }
}
```

---

## Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `AUTH_REQUIRED` | 401 | Missing or invalid JWT token |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `VALIDATION_ERROR` | 400 | Invalid request body |
| `NOT_FOUND` | 404 | Resource not found |
| `TENANT_NOT_FOUND` | 404 | Tenant does not exist |
| `MEMBER_NOT_FOUND` | 404 | Member not in tenant |
| `INVITE_EXPIRED` | 410 | Invite has expired |
| `RECEIPT_PROCESSING` | 409 | Receipt still being processed |
| `BUDGET_NOT_FOUND` | 404 | Budget not found |
| `DUPLICATE_INVITE` | 409 | User already invited |
| `RATE_LIMITED` | 429 | Too many requests |

---

## Rate Limits

| Endpoint | Limit |
|----------|-------|
| Auth endpoints | 10 req/min per IP |
| Receipt upload | 30 req/min per user |
| API endpoints | 100 req/min per user |
| Export endpoints | 5 req/min per user |
| API Key endpoints | 200 req/min per key |
