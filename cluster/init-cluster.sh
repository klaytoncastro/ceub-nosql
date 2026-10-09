#!/bin/bash
set -e

wait_for_port() {
  local host="$1"
  local port="$2"
  local timeout="${3:-60}"
  local started="$SECONDS"

  until nc -z -w 1 "$host" "$port" 2>/dev/null; do
    if (( SECONDS - started >= timeout )); then
      echo "Tempo esgotado aguardando $host:$port" >&2
      return 1
    fi
    sleep 1
  done

  echo "$host:$port disponível."
}

echo "Aguardando portas MongoDB..."

wait_for_port 192.168.100.101 27101 60
wait_for_port 192.168.100.102 27102 60
wait_for_port 192.168.100.103 27103 60

wait_for_port 192.168.100.101 27201 60
wait_for_port 192.168.100.102 27202 60
wait_for_port 192.168.100.103 27203 60

wait_for_port 192.168.100.101 27301 60
wait_for_port 192.168.100.102 27302 60
wait_for_port 192.168.100.103 27303 60

wait_for_port 192.168.100.101 27401 60
wait_for_port 192.168.100.102 27402 60
wait_for_port 192.168.100.103 27403 60

echo "Inicializando configRS..."

docker exec -i mongo-config-1 mongosh --host 192.168.100.101 --port 27101 <<'EOF'
rs.initiate({
  _id: "configRS",
  configsvr: true,
  members: [
    { _id: 0, host: "192.168.100.101:27101" },
    { _id: 1, host: "192.168.100.102:27102" },
    { _id: 2, host: "192.168.100.103:27103" }
  ]
})
EOF

sleep 10

echo "Inicializando shard1RS..."

docker exec -i mongo-shard1-1 mongosh --host 192.168.100.101 --port 27201 <<'EOF'
rs.initiate({
  _id: "shard1RS",
  members: [
    { _id: 0, host: "192.168.100.101:27201" },
    { _id: 1, host: "192.168.100.102:27202" },
    { _id: 2, host: "192.168.100.103:27203" }
  ]
})
EOF

echo "Inicializando shard2RS..."

docker exec -i mongo-shard2-1 mongosh --host 192.168.100.101 --port 27301 <<'EOF'
rs.initiate({
  _id: "shard2RS",
  members: [
    { _id: 0, host: "192.168.100.101:27301" },
    { _id: 1, host: "192.168.100.102:27302" },
    { _id: 2, host: "192.168.100.103:27303" }
  ]
})
EOF

echo "Inicializando shard3RS..."

docker exec -i mongo-shard3-1 mongosh --host 192.168.100.101 --port 27401 <<'EOF'
rs.initiate({
  _id: "shard3RS",
  members: [
    { _id: 0, host: "192.168.100.101:27401" },
    { _id: 1, host: "192.168.100.102:27402" },
    { _id: 2, host: "192.168.100.103:27403" }
  ]
})
EOF

sleep 20

echo "Aguardando mongos..."

wait_for_port 192.168.100.101 27017 60

echo "Adicionando shards ao cluster..."

docker exec -i mongos-vm1 mongosh --host 192.168.100.101 --port 27017 <<'EOF'
sh.addShard("shard1RS/192.168.100.101:27201,192.168.100.102:27202,192.168.100.103:27203")
sh.addShard("shard2RS/192.168.100.101:27301,192.168.100.102:27302,192.168.100.103:27303")
sh.addShard("shard3RS/192.168.100.101:27401,192.168.100.102:27402,192.168.100.103:27403")

sh.status()
EOF

echo "Cluster MongoDB inicializado."
