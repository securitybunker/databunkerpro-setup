#!/bin/sh
#
# Generates the .env files for the Oracle docker-compose stack.
#
#   ./generate-env-files.sh          # plaintext (default) — Databunker Pro <-> Oracle on 1521
#   ./generate-env-files.sh ssl      # also pack a TLS wallet and configure Oracle on 2484 (TCPS)
#
# ---------------------------------------------------------------------------
# Using it WITHOUT SSL (default)
#   Nothing to do — this writes ORACLE_PORT=1521 and leaves ORACLE_SSL_MODE off.
#   `./hard-reset.sh` and the stack talks plaintext on the private compose network.
#
# Configuring SSL (TLS / TCPS)
#   Run `./generate-env-files.sh ssl`. That packs a self-signed Oracle *wallet*
#   into .env/wallet (see pack_wallet below) and writes ORACLE_PORT=2484 +
#   ORACLE_SSL_MODE=require. To make the listener serve TCPS on 2484, mount the
#   wallet and drop these two files into the container's TNS_ADMIN
#   ($ORACLE_HOME/network/admin), then `./hard-reset.sh`:
#
#     # sqlnet.ora
#     WALLET_LOCATION = (SOURCE=(METHOD=FILE)(METHOD_DATA=(DIRECTORY=/opt/oracle/wallet)))
#     SSL_CLIENT_AUTHENTICATION = FALSE
#     SSL_VERSION = 1.2
#
#     # listener.ora
#     WALLET_LOCATION = (SOURCE=(METHOD=FILE)(METHOD_DATA=(DIRECTORY=/opt/oracle/wallet)))
#     SSL_CLIENT_AUTHENTICATION = FALSE
#     LISTENER = (DESCRIPTION_LIST =
#       (DESCRIPTION = (ADDRESS = (PROTOCOL=TCP)(HOST=0.0.0.0)(PORT=1521)))
#       (DESCRIPTION = (ADDRESS = (PROTOCOL=TCPS)(HOST=0.0.0.0)(PORT=2484))))
#
#   go-ora connects with cert verification disabled, so the self-signed wallet is
#   enough — the link is encrypted, the server identity is not verified (fine for
#   local dev). If the handshake fails on a cipher, add SSL_CIPHER_SUITES to
#   sqlnet.ora. Production/managed TLS: see the Oracle Database backend docs.
# ---------------------------------------------------------------------------

mkdir -p .env

# Oracle limits passwords to 30 bytes and parses them as identifiers, so use a
# short, letter-initial, alphanumeric value (no long hex, no special characters).
oracle_pw() { printf 'Db%s' "$(< /dev/urandom LC_CTYPE=C tr -dc 'A-Za-z0-9' | head -c24)"; }

APP_USER_PASSWORD=$(oracle_pw)
ORACLE_PASSWORD=$(oracle_pw)
REDIS_USER_PASS=$(< /dev/urandom LC_CTYPE=C tr -dc '_A-Za-z0-9' | head -c32)
WRAPPINGKEY=$(< /dev/urandom LC_CTYPE=C tr -dc 'a-f0-9' | head -c48)

echo 'generating .env/oracle.env'
{
  echo "ORACLE_PASSWORD=$ORACLE_PASSWORD"
  echo "APP_USER=bunkeruser"
  echo "APP_USER_PASSWORD=$APP_USER_PASSWORD"
} > .env/oracle.env

echo 'generating .env/redis.env'
{
  echo "REDIS_USER_PASS=$REDIS_USER_PASS"
  echo "REDIS_USER_NAME=default"
} > .env/redis.env

# --- optional: pack the TLS wallet with orapki -----------------------------
# Oracle serves TLS over a TCPS listener that reads its certificate from an
# Oracle *wallet*. A wallet is ewallet.p12 (PKCS#12) + cwallet.sso (the
# passwordless "auto-login" file the listener opens at boot). openssl can make
# the p12 but NOT cwallet.sso — only Oracle's `orapki` can.
#
# NOTE: `orapki` is a Java tool. The compose runtime uses the `:slim` image, which
# ships NO Java, so orapki cannot run there. We pack the wallet with a host `orapki`
# if you have one, otherwise with the *full* gvenzl/oracle-free image (it bundles a
# JDK). The packed wallet is then just mounted into the slim runtime — whose TCPS
# listener is C-based and needs no Java. The full image is a one-time ~2 GB pull.
WALLET_PACK_IMAGE="gvenzl/oracle-free:latest"   # full image (has Java); NOT :slim
pack_wallet() {
  WALLET="$PWD/.env/wallet"
  WALLET_PWD="Wallet_$(< /dev/urandom LC_CTYPE=C tr -dc 'A-Za-z0-9' | head -c16)"  # only used now; runtime uses auto-login
  rm -rf "$WALLET"; mkdir -p "$WALLET"

  if command -v orapki >/dev/null 2>&1; then
    echo 'packing wallet with host orapki'
    orapki wallet create -wallet "$WALLET" -pwd "$WALLET_PWD" -auto_login
    orapki wallet add    -wallet "$WALLET" -pwd "$WALLET_PWD" \
        -dn "CN=oracle" -keysize 2048 -self_signed -validity 3650
  else
    echo "orapki not on PATH — packing wallet via $WALLET_PACK_IMAGE (needs Java; slim has none)"
    # override the DB-boot entrypoint, run as root so orapki can write the bind mount,
    # then make the files world-readable for the slim runtime's oracle user.
    docker run --rm --user root --entrypoint bash -v "$WALLET:/wallet" "$WALLET_PACK_IMAGE" -lc "
      \$ORACLE_HOME/bin/orapki wallet create -wallet /wallet -pwd '$WALLET_PWD' -auto_login &&
      \$ORACLE_HOME/bin/orapki wallet add    -wallet /wallet -pwd '$WALLET_PWD' \
          -dn 'CN=oracle' -keysize 2048 -self_signed -validity 3650 &&
      chmod -R a+rX /wallet"
  fi
  echo "wallet packed at .env/wallet (ewallet.p12 + cwallet.sso)"
}

echo 'generating .env/databunker.env'
if [ "$1" = "ssl" ] || [ "$1" = "--ssl" ]; then
  pack_wallet
  ORACLE_PORT=2484
  ORACLE_SSL_LINE='ORACLE_SSL_MODE=require'
  echo "SSL mode: Databunker Pro -> Oracle over TLS on 2484"
  echo "  next: mount the wallet + TNS_ADMIN config and the 2484 port in docker-compose.yml (see the SSL comments)"
else
  ORACLE_PORT=1521
  ORACLE_SSL_LINE='# ORACLE_SSL_MODE=require   # (SSL is off; regenerate with: ./generate-env-files.sh ssl)'
fi

{
  echo "DATABUNKER_WRAPPINGKEY=$WRAPPINGKEY"
  echo "ORACLE_HOST=oracle"
  echo "ORACLE_PORT=$ORACLE_PORT"
  echo "ORACLE_SERVICE=FREEPDB1"
  echo "ORACLE_USER_NAME=bunkeruser"
  echo "ORACLE_USER_PASS=$APP_USER_PASSWORD"
  echo "$ORACLE_SSL_LINE"
  echo "REDIS_HOST=redis"
  echo "REDIS_PORT=6379"
  echo "REDIS_USER_PASS=$REDIS_USER_PASS"
  echo "REDIS_USER_NAME=default"
} > .env/databunker.env

echo 'done. next: ./hard-reset.sh (or: docker compose up -d)'
