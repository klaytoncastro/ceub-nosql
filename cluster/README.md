# Cluster MongoDB 7 com Docker Compose em 3 VMs

Este material monta um cluster MongoDB didático com:

```text
3 VMs
3 Config Servers
3 Shards reais
3 réplicas por shard
3 Mongos
1 Mongo Express na VM1
```

Objetivo: demonstrar, de forma prática, os conceitos de:

```text
Replica Set
Sharding
Config Server
Mongos
Failover
Eleição de primário
Tolerância à perda de uma VM
Distribuição horizontal de dados
```

Este ambiente está propositalmente **sem autenticação** e **sem keyFile**, para simplificar o aprendizado.

Não use este modelo diretamente em produção.

---

## 1. Endereçamento usado

```text
VM1 = 192.168.100.101
VM2 = 192.168.100.102
VM3 = 192.168.100.103
```

---

## 2. Topologia

### VM1

```text
mongo-config-1   -> configRS  -> 192.168.100.101:27101
mongo-shard1-1   -> shard1RS  -> 192.168.100.101:27201
mongo-shard2-1   -> shard2RS  -> 192.168.100.101:27301
mongo-shard3-1   -> shard3RS  -> 192.168.100.101:27401
mongos-vm1       -> mongos    -> 192.168.100.101:27017
mongo-express    -> web       -> 192.168.100.101:8081
```

### VM2

```text
mongo-config-2   -> configRS  -> 192.168.100.102:27102
mongo-shard1-2   -> shard1RS  -> 192.168.100.102:27202
mongo-shard2-2   -> shard2RS  -> 192.168.100.102:27302
mongo-shard3-2   -> shard3RS  -> 192.168.100.102:27402
mongos-vm2       -> mongos    -> 192.168.100.102:27017
```

### VM3

```text
mongo-config-3   -> configRS  -> 192.168.100.103:27103
mongo-shard1-3   -> shard1RS  -> 192.168.100.103:27203
mongo-shard2-3   -> shard2RS  -> 192.168.100.103:27303
mongo-shard3-3   -> shard3RS  -> 192.168.100.103:27403
mongos-vm3       -> mongos    -> 192.168.100.103:27017
```

---

## 3. Distribuição lógica

```text
Config Server Replica Set
  configRS:
    192.168.100.101:27101
    192.168.100.102:27102
    192.168.100.103:27103

Shard 1 Replica Set
  shard1RS:
    192.168.100.101:27201
    192.168.100.102:27202
    192.168.100.103:27203

Shard 2 Replica Set
  shard2RS:
    192.168.100.101:27301
    192.168.100.102:27302
    192.168.100.103:27303

Shard 3 Replica Set
  shard3RS:
    192.168.100.101:27401
    192.168.100.102:27402
    192.168.100.103:27403
```

Cada shard possui um membro em cada VM. Assim, se qualquer VM cair, cada replica set ainda mantém 2 de 3 membros.

---

## 4. Arquivo `docker-compose-mongo-vm1.yml`

```yaml
version: "3.3"

services:
  mongo-config-1:
    image: mongo:7
    container_name: mongo-config-1
    network_mode: host
    restart: unless-stopped
    command: >
      mongod --configsvr
      --replSet configRS
      --port 27101
      --bind_ip 0.0.0.0
    volumes:
      - config1_data:/data/configdb

  mongo-shard1-1:
    image: mongo:7
    container_name: mongo-shard1-1
    network_mode: host
    restart: unless-stopped
    command: >
      mongod --shardsvr
      --replSet shard1RS
      --port 27201
      --bind_ip 0.0.0.0
    volumes:
      - shard1_1_data:/data/db

  mongo-shard2-1:
    image: mongo:7
    container_name: mongo-shard2-1
    network_mode: host
    restart: unless-stopped
    command: >
      mongod --shardsvr
      --replSet shard2RS
      --port 27301
      --bind_ip 0.0.0.0
    volumes:
      - shard2_1_data:/data/db

  mongo-shard3-1:
    image: mongo:7
    container_name: mongo-shard3-1
    network_mode: host
    restart: unless-stopped
    command: >
      mongod --shardsvr
      --replSet shard3RS
      --port 27401
      --bind_ip 0.0.0.0
    volumes:
      - shard3_1_data:/data/db

  mongos:
    image: mongo:7
    container_name: mongos-vm1
    network_mode: host
    restart: unless-stopped
    command: >
      mongos
      --configdb configRS/192.168.100.101:27101,192.168.100.102:27102,192.168.100.103:27103
      --port 27017
      --bind_ip 0.0.0.0
    depends_on:
      - mongo-config-1

  mongo-express:
    image: mongo-express:latest
    container_name: mongo-express-vm1
    restart: unless-stopped
    ports:
      - "8081:8081"
    environment:
      ME_CONFIG_MONGODB_URL: mongodb://192.168.100.101:27017/
    volumes:
      - ./wait-for-it.sh:/wait-for-it.sh
    command:
      [
        "/wait-for-it.sh",
        "192.168.100.101:27017",
        "--",
        "npm",
        "start"
      ]
    depends_on:
      - mongos

volumes:
  config1_data:
  shard1_1_data:
  shard2_1_data:
  shard3_1_data:
```

---

## 5. Arquivo `docker-compose-mongo-vm2.yml`

```yaml
version: "3.3"

services:
  mongo-config-2:
    image: mongo:7
    container_name: mongo-config-2
    network_mode: host
    restart: unless-stopped
    command: >
      mongod --configsvr
      --replSet configRS
      --port 27102
      --bind_ip 0.0.0.0
    volumes:
      - config2_data:/data/configdb

  mongo-shard1-2:
    image: mongo:7
    container_name: mongo-shard1-2
    network_mode: host
    restart: unless-stopped
    command: >
      mongod --shardsvr
      --replSet shard1RS
      --port 27202
      --bind_ip 0.0.0.0
    volumes:
      - shard1_2_data:/data/db

  mongo-shard2-2:
    image: mongo:7
    container_name: mongo-shard2-2
    network_mode: host
    restart: unless-stopped
    command: >
      mongod --shardsvr
      --replSet shard2RS
      --port 27302
      --bind_ip 0.0.0.0
    volumes:
      - shard2_2_data:/data/db

  mongo-shard3-2:
    image: mongo:7
    container_name: mongo-shard3-2
    network_mode: host
    restart: unless-stopped
    command: >
      mongod --shardsvr
      --replSet shard3RS
      --port 27402
      --bind_ip 0.0.0.0
    volumes:
      - shard3_2_data:/data/db

  mongos:
    image: mongo:7
    container_name: mongos-vm2
    network_mode: host
    restart: unless-stopped
    command: >
      mongos
      --configdb configRS/192.168.100.101:27101,192.168.100.102:27102,192.168.100.103:27103
      --port 27017
      --bind_ip 0.0.0.0
    depends_on:
      - mongo-config-2

volumes:
  config2_data:
  shard1_2_data:
  shard2_2_data:
  shard3_2_data:
```

---

## 6. Arquivo `docker-compose-mongo-vm3.yml`

```yaml
version: "3.3"

services:
  mongo-config-3:
    image: mongo:7
    container_name: mongo-config-3
    network_mode: host
    restart: unless-stopped
    command: >
      mongod --configsvr
      --replSet configRS
      --port 27103
      --bind_ip 0.0.0.0
    volumes:
      - config3_data:/data/configdb

  mongo-shard1-3:
    image: mongo:7
    container_name: mongo-shard1-3
    network_mode: host
    restart: unless-stopped
    command: >
      mongod --shardsvr
      --replSet shard1RS
      --port 27203
      --bind_ip 0.0.0.0
    volumes:
      - shard1_3_data:/data/db

  mongo-shard2-3:
    image: mongo:7
    container_name: mongo-shard2-3
    network_mode: host
    restart: unless-stopped
    command: >
      mongod --shardsvr
      --replSet shard2RS
      --port 27303
      --bind_ip 0.0.0.0
    volumes:
      - shard2_3_data:/data/db

  mongo-shard3-3:
    image: mongo:7
    container_name: mongo-shard3-3
    network_mode: host
    restart: unless-stopped
    command: >
      mongod --shardsvr
      --replSet shard3RS
      --port 27403
      --bind_ip 0.0.0.0
    volumes:
      - shard3_3_data:/data/db

  mongos:
    image: mongo:7
    container_name: mongos-vm3
    network_mode: host
    restart: unless-stopped
    command: >
      mongos
      --configdb configRS/192.168.100.101:27101,192.168.100.102:27102,192.168.100.103:27103
      --port 27017
      --bind_ip 0.0.0.0
    depends_on:
      - mongo-config-3

volumes:
  config3_data:
  shard1_3_data:
  shard2_3_data:
  shard3_3_data:
```

---

## 7. Subir os containers

Na VM1:

```bash
docker compose -f docker-compose-mongo-vm1.yml up -d
```

Na VM2:

```bash
docker compose -f docker-compose-mongo-vm2.yml up -d
```

Na VM3:

```bash
docker compose -f docker-compose-mongo-vm3.yml up -d
```

Verificar:

```bash
docker ps
```

---

## 8. Script `init-cluster.sh`

Execute este script apenas uma vez, preferencialmente na VM1.

```bash
#!/bin/bash
set -e

echo "Aguardando portas MongoDB..."

./wait-for-it.sh 192.168.100.101:27101 --timeout=60
./wait-for-it.sh 192.168.100.102:27102 --timeout=60
./wait-for-it.sh 192.168.100.103:27103 --timeout=60

./wait-for-it.sh 192.168.100.101:27201 --timeout=60
./wait-for-it.sh 192.168.100.102:27202 --timeout=60
./wait-for-it.sh 192.168.100.103:27203 --timeout=60

./wait-for-it.sh 192.168.100.101:27301 --timeout=60
./wait-for-it.sh 192.168.100.102:27302 --timeout=60
./wait-for-it.sh 192.168.100.103:27303 --timeout=60

./wait-for-it.sh 192.168.100.101:27401 --timeout=60
./wait-for-it.sh 192.168.100.102:27402 --timeout=60
./wait-for-it.sh 192.168.100.103:27403 --timeout=60

echo "Inicializando configRS..."

mongosh --host 192.168.100.101 --port 27101 <<'EOF'
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

mongosh --host 192.168.100.101 --port 27201 <<'EOF'
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

mongosh --host 192.168.100.101 --port 27301 <<'EOF'
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

mongosh --host 192.168.100.101 --port 27401 <<'EOF'
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

./wait-for-it.sh 192.168.100.101:27017 --timeout=60

echo "Adicionando shards ao cluster..."

mongosh --host 192.168.100.101 --port 27017 <<'EOF'
sh.addShard("shard1RS/192.168.100.101:27201,192.168.100.102:27202,192.168.100.103:27203")
sh.addShard("shard2RS/192.168.100.101:27301,192.168.100.102:27302,192.168.100.103:27303")
sh.addShard("shard3RS/192.168.100.101:27401,192.168.100.102:27402,192.168.100.103:27403")

sh.status()
EOF

echo "Cluster MongoDB inicializado."
```

Dar permissão:

```bash
chmod +x init-cluster.sh wait-for-it.sh
```

Executar:

```bash
./init-cluster.sh
```

---

## 9. Habilitar sharding em um banco

Conectar ao `mongos`:

```bash
mongosh --host 192.168.100.101 --port 27017
```

Criar banco e coleção:

```javascript
use cluster

db.createCollection("events")
```

Habilitar sharding no banco:

```javascript
sh.enableSharding("cluster")
```

Shard collection com chave hashed:

```javascript
sh.shardCollection("cluster.events", { "_id": "hashed" })
```

---

## 10. Inserir dados de teste

```javascript
use cluster

for (let i = 0; i < 100000; i++) {
  db.events.insertOne({
    origem: "teste",
    valor: i,
    criadoEm: new Date()
  })
}
```

Verificar distribuição:

```javascript
sh.status()
```

---

## 11. Mongo Express

Acessar pela VM1:

```text
http://192.168.100.101:8081
```

Ele se conecta ao `mongos` da VM1:

```text
mongodb://192.168.100.101:27017/
```

---

## 12. Testes úteis

### Ver status do sharding

```bash
mongosh --host 192.168.100.101 --port 27017
```

```javascript
sh.status()
```

### Ver status dos replica sets

Config server:

```bash
mongosh --host 192.168.100.101 --port 27101
```

```javascript
rs.status()
```

Shard 1:

```bash
mongosh --host 192.168.100.101 --port 27201
```

```javascript
rs.status()
```

Shard 2:

```bash
mongosh --host 192.168.100.101 --port 27301
```

```javascript
rs.status()
```

Shard 3:

```bash
mongosh --host 192.168.100.101 --port 27401
```

```javascript
rs.status()
```

---

## 13. Teste de perda de uma VM

Desligue uma VM inteira, por exemplo a VM3.

O cluster deve continuar funcionando, pois cada replica set continuará com 2 de 3 membros:

```text
configRS  -> 2/3 vivos
shard1RS  -> 2/3 vivos
shard2RS  -> 2/3 vivos
shard3RS  -> 2/3 vivos
```

Consultar pelo mongos da VM1 ou VM2:

```bash
mongosh --host 192.168.100.101 --port 27017
```

ou:

```bash
mongosh --host 192.168.100.102 --port 27017
```

---

## 14. Observações importantes

Este cluster é didático.

Pontos simplificados de propósito:

```text
Sem autenticação
Sem keyFile
Sem TLS
Sem usuário admin
Sem tuning de WiredTiger
Sem limitação explícita de memória
Sem monitoramento
```

Para produção, seria necessário adicionar pelo menos:

```text
Autenticação
keyFile
TLS
Backup
Monitoramento
Limites de memória
Política de volumes/discos
Firewall
Usuários e permissões
```

---

## 15. Limpeza do ambiente

Em cada VM:

```bash
docker compose -f docker-compose-mongo-vmX.yml down
```

Para apagar os dados também:

```bash
docker compose -f docker-compose-mongo-vmX.yml down -v
```

Substitua `vmX` por:

```text
vm1
vm2
vm3
```

Atenção: `down -v` remove os volumes e apaga os dados do cluster.
