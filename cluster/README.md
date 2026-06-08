
## 1. Visão Geral

Este laboratório tem como objetivo demonstrar como bancos de dados NoSQL podem ser implantados em arquitetura de cluster, utilizando múltiplas máquinas virtuais e containers Docker, aplicando os conceitos vistos  em sala de aula sobre Sistemas Distribuídos, High-Performance Computing, Big Data e NoSQL: quando o volume de dados, a taxa de acesso ou a necessidade de disponibilidade ultrapassam a capacidade de uma única máquina, torna-se necessário distribuir processamento, armazenamento e responsabilidade operacional entre vários nós. Em sistemas centralizados, todo o serviço depende de um único servidor. Esse modelo é simples, mas possui limitações claras:

- limite físico de CPU, memória, disco e rede;
- dificuldade de crescimento horizontal;
- maior risco de ponto único de falha;
- menor tolerância a indisponibilidades;
- manutenção mais difícil em ambientes críticos.

Em um cluster, várias máquinas passam a trabalhar de forma coordenada. Cada máquina é chamada de **nó**. Esses nós se comunicam pela rede, dividem responsabilidades e permitem que o sistema cresça por adição de novos servidores, e não apenas pela substituição por máquinas maiores. A ideia central é dividir o problema em partes menores, processar ou armazenar essas partes em paralelo e manter mecanismos de coordenação para que o conjunto se comporte como um sistema coerente. 

## 2. Definição de Cluster

Um cluster é um conjunto de máquinas interconectadas que cooperam para executar uma função comum. Para o usuário ou para a aplicação, esse conjunto pode parecer um único sistema, embora internamente seja composto por vários nós independentes. No contexto deste laboratório, o cluster não será usado para processamento científico clássico, como em HPC, mas para **armazenamento distribuído de dados**. Os princípios são os mesmos:

- distribuição de carga;
- paralelismo;
- replicação;
- tolerância a falhas;
- coordenação entre nós;
- recuperação automática ou semiautomática após falhas;
- escalabilidade horizontal.

A diferença é que, em vez de distribuir jobs de processamento, como ocorre em frameworks de Big Data como Hadoop e Spark, distribuiremos dados e responsabilidades entre instâncias de bancos de dados NoSQL, que foram projetados para cenários em que o modelo relacional tradicional nem sempre é o mais adequado. Isso ocorre especialmente quando há:

- grande volume de dados;
- alta taxa de escrita;
- necessidade de baixa latência;
- dados semiestruturados ou flexíveis;
- necessidade de alta disponibilidade;
- crescimento horizontal do ambiente;
- distribuição geográfica ou lógica dos dados.

## 3. Entendendo as Abordagens de Cluster do MongoDB e Cassandra

MongoDB (família de documentos) e Cassandra (família orientada a colunas) resolvem esses problemas de formas diferentes. Vimos que o **MongoDB** é um banco orientado a documentos. Ele trabalha com documentos BSON, próximos ao modelo JSON, e organiza a escalabilidade horizontal por meio de **sharding**, em que os dados são distribuídos entre diferentes shards. Em um cluster sharded do MongoDB, os principais componentes são shards, config servers e roteadores `mongos`. A documentação oficial recomenda, em produção, config servers como replica set de três membros, shards como replica sets de três membros e um ou mais roteadores `mongos`. 

O **Cassandra** é um banco distribuído baseado em famílias de colunas, projetado desde a origem para operar em múltiplos nós, com arquitetura descentralizada (P2P) e sem nó mestre. Ele distribui dados por partições, replica dados entre nós e permite ajustar o nível de consistência das leituras e escritas. Em Cassandra, quando se usa fator de replicação 3, uma operação em `QUORUM` normalmente exige resposta de 2 das 3 réplicas.

## 4. Conceitos Fundamentais

### Nó

Um nó é uma máquina participante do cluster. Neste laboratório, cada VM executará containers que representam componentes do MongoDB ou Cassandra.

### Replicação

Replicação é a cópia dos dados em mais de um nó. Ela aumenta a disponibilidade, pois permite que o sistema continue funcionando mesmo que uma máquina falhe.

No MongoDB, a replicação ocorre por meio de **replica sets**. Um replica set mantém cópias dos mesmos dados em múltiplos membros e permite eleição de primário em caso de falha. 

No Cassandra, a replicação é configurada por keyspace e controlada pelo fator de replicação. O dado é distribuído e replicado conforme a estratégia definida para o cluster.

### Particionamento

Particionamento é a divisão lógica dos dados em partes menores.

No MongoDB, esse processo é chamado de **sharding**. O sharding distribui dados entre múltiplas máquinas para suportar grandes volumes de dados e alta vazão de operações. 

No Cassandra, os dados são distribuídos pelo cluster com base na chave de partição. A escolha correta dessa chave é fundamental para evitar concentração de carga em poucos nós.

### Coordenação

Todo sistema distribuído precisa de algum mecanismo de coordenação.

No MongoDB, os **config servers** armazenam os metadados do cluster sharded, enquanto os roteadores **mongos** recebem as conexões dos clientes e encaminham as operações para os shards corretos.

No Cassandra, a coordenação é descentralizada. Qualquer nó pode receber uma requisição do cliente e atuar como coordenador daquela operação, encaminhando leituras e escritas para as réplicas responsáveis.

### Consistência

Consistência define o quanto o sistema garante que leituras retornem os dados mais recentes. Em bancos de dados distribuídos, há sempre um compromisso entre consistência, disponibilidade e tolerância a partições de rede. O MongoDB e o Cassandra adotam estratégias diferentes para atender este compromisso.

No MongoDB, a arquitetura com replica sets e sharding permite combinar alta disponibilidade, replicação e distribuição horizontal, mas com papéis bem definidos entre primário, secundários, shards, config servers e `mongos`.

No Cassandra, a consistência é ajustável por operação. O cliente pode escolher níveis como `ONE`, `QUORUM` ou `ALL`, dependendo da necessidade de desempenho ou garantia de leitura/escrita.

## 5. Topologia Geral do Laboratório

Neste laboratório, trabalharemos com uma topologia baseada em três máquinas virtuais com IPs dedicados:

```text
VM1 = 192.168.100.101
VM2 = 192.168.100.102
VM3 = 192.168.100.103

```text
3 VMs
3 Config Servers
3 Shards reais
3 réplicas por shard
3 Mongos
1 Mongo Express na VM1
```

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


### 3.1. Endereçamento

```text
VM1 = 192.168.100.101
VM2 = 192.168.100.102
VM3 = 192.168.100.103
```
---

### 3.2. Topologia

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

### 5.3. Distribuição lógica

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

## 5.4. Arquivo `docker-compose-mongo-vm1.yml`

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

### 5.5 Arquivo `docker-compose-mongo-vm2.yml`

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

### 5.6. Arquivo `docker-compose-mongo-vm3.yml`

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

## 5.7. Subir os containers

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

## 5.8. Script `init-cluster.sh`

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

## 5.9. Habilitar sharding em um banco

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

## 5.10. Inserir dados de teste

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

## 6. Testes úteis

### 6.1. Mongo Express

Acessar pela VM1:

```text
http://192.168.100.101:8081
```

Ele se conecta ao `mongos` da VM1:

```text
mongodb://192.168.100.101:27017/
```

### 6.2. Ver status do sharding

```bash
mongosh --host 192.168.100.101 --port 27017
```

```javascript
sh.status()
```

### 6.3. Ver status dos replica sets

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

### 6.3. Teste de perda de uma VM

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

### 6.4. Observações importantes

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

### 6.5. Limpeza do ambiente

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
