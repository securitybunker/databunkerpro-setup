# Databunker Pro + Oracle (local docker-compose)

Runs Databunker Pro against a local **Oracle Database** using the
[`gvenzl/oracle-free`](https://github.com/gvenzl/oci-oracle-free) image (Oracle
Database 23ai Free), plus Redis. It mirrors `docker-compose-pgsql/`.

The Oracle backend is built into the standard Databunker Pro image and is selected
automatically when `ORACLE_HOST` is set (pure-Go `go-ora` driver — no Oracle
Instant Client needed). See the docs: [Oracle Database backend](https://databunker.org/pro/installation/oracle-database).

## Quick start

```sh
./generate-env-files.sh   # creates .env/{oracle,redis,databunker}.env with fresh secrets
./hard-reset.sh           # docker compose down -v && up -d
./logs.sh                 # follow the Databunker Pro logs
```

Databunker Pro is on http://localhost:3000. First boot takes a few minutes while
Oracle initializes (longer on Apple Silicon, where the image runs emulated).

- `oracle.sh` — open a `sqlplus` session as the schema user.
- `reload.sh` — restart the stack (keep data).
- `hard-reset.sh` — wipe the database volume and start fresh.

## How the schema user is created

`gvenzl/oracle-free` reads `APP_USER` / `APP_USER_PASSWORD` from `.env/oracle.env`
and auto-creates that user in the **`FREEPDB1`** pluggable database with
`CONNECT` + `RESOURCE` + unlimited quota — exactly what Databunker Pro needs to
create its tables and indexes. So, unlike Postgres, there is no separate
schema-setup SQL: the app user *is* the namespace (`ORACLE_SERVICE=FREEPDB1`).

Oracle limits passwords to 30 bytes and parses them as identifiers, so
`generate-env-files.sh` produces a short, letter-initial, alphanumeric password.

## Environment variables

`.env/databunker.env` points Databunker Pro at Oracle:

| Variable | Value here | Notes |
| --- | --- | --- |
| `ORACLE_HOST` | `oracle` | selects the Oracle backend |
| `ORACLE_PORT` | `1521` | `2484` for TLS |
| `ORACLE_SERVICE` | `FREEPDB1` | the gvenzl PDB |
| `ORACLE_USER_NAME` | `bunkeruser` | = `APP_USER` |
| `ORACLE_USER_PASS` | *(generated)* | = `APP_USER_PASSWORD` |
| `ORACLE_SSL_MODE` | *(commented)* | `require` to use TLS |

## TLS (optional)

Postgres serves TLS from a single cert file; Oracle serves it over a separate
**TCPS** listener that reads its certificate from an Oracle **wallet**, so there
is no one-line switch. `enable-tls.sh` builds a self-signed auto-login wallet and
adds a TCPS endpoint on **2484** next to the plaintext 1521 listener. To turn it on:

1. In `docker-compose.yml`, uncomment the `enable-tls.sh` volume mount and the
   `2484` port under the `oracle` service.
2. In `.env/databunker.env`, set `ORACLE_PORT=2484` and `ORACLE_SSL_MODE=require`.
3. `./hard-reset.sh`.

`go-ora` connects with certificate verification disabled, so the self-signed
wallet is enough — the connection is encrypted but the server identity is not
verified (fine for local dev). For production/managed TLS (AWS RDS option group,
cipher pinning), see the [Oracle Database backend](https://databunker.org/pro/installation/oracle-database) docs.
