#!/bin/bash
#
# OPTIONAL — enable TLS (TCPS) on the local Oracle listener.
#
# Unlike PostgreSQL (which just needs a server cert file), Oracle serves TLS over
# a separate TCPS listener that reads its certificate from an Oracle *wallet*.
# This script builds a self-signed auto-login wallet and adds a TCPS endpoint on
# port 2484 next to the existing plaintext 1521 listener.
#
# gvenzl/oracle-free runs every file in /container-entrypoint-startdb.d/ on each
# start, so mount this script there (see docker-compose.yml) to apply it.
#
# After enabling: in docker-compose.yml uncomment the enable-tls.sh mount and the
# 2484 port; in .env/databunker.env set ORACLE_PORT=2484 and ORACLE_SSL_MODE=require.
#
# Note: go-ora connects with certificate verification disabled, so the self-signed
# wallet is sufficient — the connection is encrypted but the server identity is not
# verified (fine for local development). If the go-ora handshake fails with a cipher
# error, add a modern suite to sqlnet.ora via SSL_CIPHER_SUITES.
set -e

WALLET=/opt/oracle/wallet
TNS="${TNS_ADMIN:-$ORACLE_HOME/network/admin}"

if [ ! -f "$WALLET/cwallet.sso" ]; then
  echo "enable-tls: creating self-signed Oracle wallet at $WALLET"
  mkdir -p "$WALLET"
  orapki wallet create -wallet "$WALLET" -auto_login_only
  orapki wallet add -wallet "$WALLET" -dn "CN=oracle" -keysize 2048 \
    -self_signed -validity 3650 -auto_login_only
fi

echo "enable-tls: writing sqlnet.ora / listener.ora with a TCPS endpoint (2484)"
cat > "$TNS/sqlnet.ora" <<EOF
WALLET_LOCATION = (SOURCE = (METHOD = FILE)(METHOD_DATA = (DIRECTORY = $WALLET)))
SSL_CLIENT_AUTHENTICATION = FALSE
SSL_VERSION = 1.2
EOF

cat > "$TNS/listener.ora" <<EOF
WALLET_LOCATION = (SOURCE = (METHOD = FILE)(METHOD_DATA = (DIRECTORY = $WALLET)))
SSL_CLIENT_AUTHENTICATION = FALSE
LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521)))
    (DESCRIPTION = (ADDRESS = (PROTOCOL = TCPS)(HOST = 0.0.0.0)(PORT = 2484)))
  )
EOF

# Reload the listener so it picks up the TCPS endpoint; PMON re-registers the
# database services dynamically.
lsnrctl reload || lsnrctl start || true
echo "enable-tls: TCPS listener enabled on 2484"
