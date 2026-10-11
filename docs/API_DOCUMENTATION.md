# Field Notes - Complete API & Architecture Documentation

## 1. Overview & Base URLs

The **Field Notes** application is built on an **Offline-First Architecture**. It communicates with a backend REST server while maintaining a fully functioning local embedded database ([Hive](https://pub.dev/packages/hive_flutter)). All CRUD operations work offline and synchronize seamlessly when connected.

### Environment Endpoints

| Environment | Base URL | Description |
| :--- | :--- | :--- |
| **Android Emulator** | `http://10.0.2.2:8080` | Maps to the host machine's localhost |
| **iOS Simulator / macOS** | `http://127.0.0.1:8080` | Direct localhost access |
| **Web Browser** | `http://localhost:8080` | Web client localhost |
| **Production Server** | `https://api.fieldnotes.example.com` | Production deployment URL |

---

## 2. Authentication & Authorization

All authenticated endpoints require a **Bearer JWT Token** in the HTTP request headers:
```http
Authorization: Bearer <your_jwt_token>
```

### 2.1 Register Account
* **Endpoint**: `POST /api/auth/register`
* **Security**: Public
* **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "SecretPassword123"
  }
  ```
  > **Note**: Password must be between **10 and 72 characters**.

* **Response (`201 Created` / `200 OK`)**:
  ```json
  {
    "userId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "email": "user@example.com",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresAt": "2026-10-10T12:00:00Z"
  }
  ```

---

### 2.2 Login
* **Endpoint**: `POST /api/auth/login`
* **Security**: Public
* **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "SecretPassword123"
  }
  ```
* **Response (`200 OK`)**:
  ```json
  {
    "userId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "email": "user@example.com",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresAt": "2026-10-10T12:00:00Z"
  }
  ```

---

### 2.3 Get Current User Session
* **Endpoint**: `GET /api/auth/me`
* **Security**: `Bearer <token>`
* **Response (`200 OK`)**:
  ```json
  {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "email": "user@example.com"
  }
  ```

---

### 2.4 Logout
* **Endpoint**: `POST /api/auth/logout`
* **Security**: `Bearer <token>`
* **Response (`204 No Content`)**

---

## 3. Two-Way Sync Engine (Offline-First)

The app syncs local changes with the cloud and pulls remote modifications through two specialized sync endpoints:

```
                  ┌──────────────────────────────┐
                  │    Local Offline Mutation    │
                  │   (Create / Edit / Delete)   │
                  └──────────────┬───────────────┘
                                 │
                                 ▼
                  ┌──────────────────────────────┐
                  │   1. Saved in Local Hive     │
                  │   2. Enqueued in Queue Box   │
                  └──────────────┬───────────────┘
                                 │
                     When Network is Available
                                 │
            ┌────────────────────┴────────────────────┐
            ▼                                         ▼
┌─────────────────────────┐               ┌────────────────────────┐
│  POST /api/sync/push    │               │  GET /api/sync/changes │
│ (Pushes local mutation  │               │ (Pulls remote changes  │
│  queue to backend)      │               │  after last cursor)    │
└─────────────────────────┘               └────────────────────────┘
```

### 3.1 Push Local Changes (`POST /api/sync/push`)
Sends a batch of queued local mutations (up to 100 per batch) to the backend.

* **Request Body**:
  ```json
  {
    "mutations": [
      {
        "mutationId": "c8b417c8-0ef9-4089-a2e6-a059d64821a7",
        "entityType": "NOTE",
        "entityId": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
        "operation": "UPSERT",
        "expectedVersion": 0,
        "data": {
          "id": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
          "siteId": "site-uuid",
          "customerId": "customer-uuid",
          "title": "Foundation Crack Inspection",
          "notes": "Observed 2mm hairline crack on eastern pillar.",
          "status": "OPEN",
          "photos": [],
          "version": 1,
          "createdAt": "2026-10-09T10:30:00.000Z"
        }
      }
    ]
  }
  ```

* **Response (`200 OK`)**:
  ```json
  {
    "results": [
      {
        "mutationId": "c8b417c8-0ef9-4089-a2e6-a059d64821a7",
        "entityType": "NOTE",
        "entityId": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
        "version": 1,
        "revision": 42,
        "data": { ... }
      }
    ]
  }
  ```

---

### 3.2 Pull Remote Changes (`GET /api/sync/changes`)
Fetches incremental server modifications since the last known revision cursor.

* **Query Parameters**:
  - `after` (*int64*, default `0`): The last sync cursor processed by the client.
  - `limit` (*int32*, default `100`): Maximum items to fetch per request.

* **Response (`200 OK`)**:
  ```json
  {
    "changes": [
      {
        "revision": 43,
        "entityType": "CUSTOMER",
        "entityId": "7e1b34d2-...",
        "data": {
          "id": "7e1b34d2-...",
          "name": "Global Energy Corp",
          "contactPerson": "Alice Johnson",
          "phone": "+1 555-0144",
          "email": "alice@globalenergy.com",
          "address": "450 Power Ave",
          "version": 2
        }
      }
    ],
    "nextCursor": 43,
    "hasMore": false
  }
  ```

---

## 4. Entity REST Endpoints

### 4.1 Customers (`/api/customers`)
* **List Customers**: `GET /api/customers?page=0&size=50`
* **Get Single Customer**: `GET /api/customers/{id}`
* **Write / Upsert**: `PUT /api/customers/{id}`
* **Delete**: `DELETE /api/customers/{id}`

### 4.2 Sites (`/api/sites`)
* **List Sites**: `GET /api/sites?customerId={uuid}&page=0&size=50`
* **Get Single Site**: `GET /api/sites/{id}`
* **Write / Upsert**: `PUT /api/sites/{id}`
* **Delete**: `DELETE /api/sites/{id}`

### 4.3 Field Notes (`/api/notes`)
* **List Notes**: `GET /api/notes?siteId={uuid}&status={DRAFT|OPEN|IN_PROGRESS|COMPLETED}&q={query}&page=0&size=50`
* **Get Single Note**: `GET /api/notes/{id}`
* **Write / Upsert**: `PUT /api/notes/{id}`
* **Delete**: `DELETE /api/notes/{id}`

### 4.4 Photo Attachments (`/api/photos/{id}`)
* **Download Photo**: `GET /api/photos/{id}` -> Returns binary image stream.
* **Upload Photo**: `PUT /api/photos/{id}` -> Uploads binary image bytes.

---

## 5. Networking & Interceptor Pipeline

All API calls flow through the configured Dio pipeline in `lib/core/network/api_client.dart`:

```
Outgoing Request  ──> [AuthInterceptor]   (Injects Authorization: Bearer <token>)
                  ──> [LoggingInterceptor] (Formatted HTTP Request Console Logs)
                  ──> Backend API
                      │
Incoming Response <── [LoggingInterceptor] (Formatted HTTP Response Logs)
                  <── [ErrorInterceptor]   (Converts 400/401/500/timeout to typed AppExceptions)
```

1. **`AuthInterceptor`**:
   - Injects JWT into headers.
   - Listens for `401 Unauthorized` responses to invalidate expired sessions.
2. **`LoggingInterceptor`**:
   - Pretty-prints request/response payloads in `kDebugMode`.
3. **`ErrorInterceptor`**:
   - Maps status codes and backend error JSON to `NetworkException`, `TimeoutException`, `UnauthorizedException`, or `ServerException`.

---

## 6. Local Database (Hive) Store Mapping

| Hive Box | Model / Data | Purpose |
| :--- | :--- | :--- |
| `session_box` | `auth_token`, `auth_user` | Persists user credentials & active JWT |
| `customers_box` | `Map<id, Customer>` | Stores customers locally for offline search & access |
| `sites_box` | `Map<id, Site>` | Stores site locations locally |
| `notes_box` | `Map<id, FieldNote>` | Stores inspection observations & sync status flags |
| `sync_mutations_box`| `Map<mutationId, SyncMutation>` | FIFO mutation queue for offline changes |
| `settings_box` | `last_sync_cursor`, theme mode | Stores revision cursor & user preferences |
