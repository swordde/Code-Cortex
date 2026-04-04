# MongoDB Atlas Setup Procedure (Cortex Backend)

This is the full procedure to connect the Go backend to MongoDB Atlas cloud.

## 1) Create Atlas resources

1. Create/Login to MongoDB Atlas.
2. Create a **Project** (example: `Cortex`).
3. Create an **M0 Free Cluster** (or higher).
4. Create a **Database User**:
   - Authentication: Password
   - Privileges: `Read and write to any database` (or restrict to target DB)
5. Configure **Network Access**:
   - Add your current public IP (`Add Current IP Address`)
   - For temporary testing only, you can use `0.0.0.0/0` (not recommended for long-term)

## 2) Get connection string

1. Atlas → Cluster → **Connect** → **Drivers**.
2. Copy the `mongodb+srv://...` URI.
3. Replace placeholders:
   - `<username>` with DB user
   - `<password>` with URL-encoded password
   - `<db-name>` with your DB name (example: `snp`)

## 3) Configure backend env

Use local env file (already created):

- File: `backend/.env`
- Set:
  - `SNP_MONGO_URI`
  - `SNP_MONGO_DB`

## 4) Start backend with env loaded

```bash
cd backend
./scripts/run_backend.sh
```

## 5) Verify end-to-end

In another terminal:

```bash
cd backend
./scripts/verify_backend_db.sh
```

If successful, you will see `[OK] Backend + Mongo flow looks healthy.`

## 6) Expected initial seeded data

On first successful startup, backend seeds:
- preset modes: `default`, `study`, `office`, `home`, `gaming`
- default cortex config
- default profile

## 7) Security checklist

- Never commit `backend/.env`.
- Rotate Atlas password if it was exposed.
- Prefer IP allowlist over `0.0.0.0/0`.
- Use least-privileged DB role for production.
- Consider separate Atlas projects for dev and prod.

## 8) Common issues

- `server selection timeout`:
  - wrong URI, wrong credentials, or IP not allowlisted.
- auth failed:
  - wrong password or special chars not URL-encoded.
- backend starts but no data:
  - verify `SNP_MONGO_DB` is the expected database.
