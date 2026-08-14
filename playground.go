ip netns exec testns python3 -c "
import socket, time
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.setblocking(False)  # non-blocking, like real apps
sock.connect(('8.8.8.8', 9999))
data = b'A' * 1400
sent, errs = 0, 0

while True:
        try:
                sock.send(data)
                sent += 1
        except BlockingIOError:
                pass  # EAGAIN — would block
        except OSError as e:
                errs += 1
" &

while true; do
    tx_hex=$(awk 'NR>1 {split($5,q,":"); print q[1]}' /proc/net/udp)
    tx_dec=$((16#${tx_hex:-0}))
    errs=$(awk '/^Udp:/{nr++; if(nr==2) print $7}' /proc/net/snmp)
    echo "$(date +%H:%M:%S) tx_queue: ${tx_dec} bytes ($((tx_dec/1024)) KB)  SndbufErrors: $errs"
    sleep 0.5
  done

ip netns exec testns tc qdisc add dev eth0 root netem delay 1ms reorder 10%

tc qdisc del dev eth0 root

while true; do
    echo "--- $(date +%H:%M:%S) ---"
    ip netns exec testns awk 'NR>1 {
      split($5,q,":");
      tx=strtonum("0x"q[1]);
      if(tx>2147483647) tx=tx-4294967296;
      printf "  socket %s tx_queue: %d bytes\n",$2,tx
    }' /proc/net/udp
    errs=$(ip netns exec testns awk '/^Udp:/{nr++; if(nr==2) print $7}' /proc/net/snmp)
    echo "  SndbufErrors: $errs"
    sleep 0.5
  done

python3 -c "
import socket, time
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.connect(('8.8.8.8', 9999))
data = b'A' * 1400
while True:
	try: sock.send(data)
	except: pass
	time.sleep(0.01)
" &

{
  "name": "mysql-user-connector",
  "config": {
    "connector.class":
"io.debezium.connector.mysql.MySqlConnector",
    "tasks.max": "1",
    "value.converter":
"org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "false",
    "database.hostname":
"host.containers.internal",
    "database.port": "3306",
    "database.user": "debezium",
    "database.password": "dbz",
    "database.server.id": "54001",
    "topic.prefix": "vm-mysql",
    "database.include.list": "keycloak",
    "table.include.list":
"keycloak.user_entity",
    "include.schema.changes": "false",
    "schema.history.internal.kafka.bootstrap.se
rvers":
"${YOUR_OPENSHIFT_BOOTSTRAP_ROUTE_URL}:443",
    "schema.history.internal.kafka.topic":
"schemahistory.vm-mysql",
    "schema.history.internal.producer.security.
protocol": "SSL",
    "schema.history.internal.producer.ssl.trust
store.location":
"/kafka/config/certs/strimzi-ca.crt",
    "schema.history.internal.producer.ssl.trust
store.type": "PEM",
    "schema.history.internal.consumer.security.
protocol": "SSL",
    "schema.history.internal.consumer.ssl.trust
store.location":
"/kafka/config/certs/strimzi-ca.crt",
    "schema.history.internal.consumer.ssl.trust
store.type": "PEM"
  }
}