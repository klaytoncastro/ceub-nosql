# Neo4j

Neo4j é um banco de dados NoSQL orientado a grafos, utilizado para armazenar dados estruturados como grafos, ao invés de tabelas, como em bancos de dados relacionais. É ideal para representar relacionamentos complexos entre dados.

## Características

- **Orientado a Grafos**: Neo4j utiliza o modelo de dados de grafo, onde os dados são armazenados como nós e as relações entre eles como arestas.
- **Cypher Query Language**: Neo4j usa uma linguagem de consulta específica para grafos chamada Cypher, que é semelhante ao SQL, mas otimizada para consultas em grafos.
- **Escalabilidade**: Neo4j é projetado para ser escalado horizontalmente, suportando grandes volumes de dados.
- **Integração com outras Ferramentas**: Neo4j se integra facilmente com várias outras ferramentas e frameworks, como Spring Data Neo4j, para facilitar o desenvolvimento de aplicações.

<!--

## Instalação via Docker Compose

A instalação do Neo4j pode ser feita utilizando Docker Compose. Aqui estão os passos para instalar o Neo4j usando Docker Compose:

1. Crie um arquivo `docker-compose.yml` com o seguinte conteúdo:

```yaml
version: '3'

services:
  neo4j:
    image: neo4j:latest
    environment:
      NEO4J_AUTH: neo4j/password
    ports:
      - "7474:7474"
      - "7687:7687"
    volumes:
      - $HOME/neo4j/data:/data

-->

## Práticas


### Desafio 1: Modelagem Astronômica com Grafos

O conjunto de dados que usaremos inclui informações sobre:
- **Exoplanetas**: como nome, massa, raio e temperatura.
- **Estrelas Hospedeiras**: como nome, massa, raio e temperatura.
- **Observatórios**: onde os exoplanetas foram descobertos.

### Colunas Importantes
- `pl_name`: Nome do planeta.
- `hostname`: Nome da estrela hospedeira.
- `discoverymethod`: Método de descoberta.
- `disc_year`: Ano de descoberta.
- `sy_dist`: Distância da Terra ao sistema planetário em parsecs.
- `pl_rade`: Raio do planeta em raios terrestres.
- `pl_masse`: Massa do planeta em massas terrestres.
- `st_teff`: Temperatura efetiva da estrela hospedeira.
- `pl_facility`: Observatório que descobriu o planeta.

Acesse o link a seguir e verifique as colunas úteis para construir seu dataset: `https://exoplanetarchive.ipac.caltech.edu/cgi-bin/TblView/nph-tblView?app=ExoTbls&config=PS`

Há vários outros recursos disponívels para explorar no site ExoPlanetArchive: `https://exoplanetarchive.ipac.caltech.edu/`


### Relacionamentos

- **Nós**:
  - `Planeta`: Representa um exoplaneta.
  - `Estrela`: Representa uma estrela hospedeira.
  - `Observatório`: Representa um observatório.

- **Relações**:
  - `ORBITA`: Relaciona um `Planeta` com uma `Estrela`.
  - `DESCOBERTO_POR`: Relaciona um `Planeta` com um `Observatório`.

### 1. Criação dos Nós
Crie nós para cada planeta, estrela hospedeira e observatório usando as informações extraídas do conjunto de dados.

### 2. Criação das Relações
Estabeleça relações `ORBITA` entre planetas e suas estrelas hospedeiras, e relações `DESCOBERTO_POR` entre planetas e os observatórios onde foram descobertos.

### 3. Importação de dados:

A importação será realizada utilizando um contêiner temporário com a mesma imagem e o mesmo volume de dados do Neo4j principal. O contêiner Neo4j principal deve estar previamente criado com armazenamento persistente em `/data`. Os arquivos CSV devem estar disponíveis no diretório atual.

### 3.1. Identificar o contêiner principal

```bash
docker ps -a
```

Nos exemplos seguintes, consideraremos que o contêiner principal se chama `neo4j`. Caso tenha outro nome, altere a variável:

```bash
CONTAINER=neo4j

#Identifique a imagem e confira os volumes utilizados:

IMAGE=$(docker inspect -f '{{.Config.Image}}' "$CONTAINER")
docker inspect -f '{{range .Mounts}}{{println .Destination .Source}}{{end}}' "$CONTAINER"
echo "$IMAGE"
```

### 3.2. Preparar os arquivos CSV

No terminal, acesse o diretório que contém os arquivos:

```bash
cd /opt/ceub-nosql/neo4j/import
ls -lh *.csv
```

Os seguintes arquivos deverão estar presentes:

```text
estrelas.csv
planetas.csv
observatorios.csv
orbitas.csv
descobertas.csv
```

Os CSVs devem seguir o formato de importação administrativa do Neo4j, com identificadores `:ID` para os nós e `:START_ID` e `:END_ID` para os relacionamentos.

### 3.3. Parar o Neo4j principal

A importação administrativa completa exige que o banco de destino esteja desligado. A opção `--overwrite-destination=true` substitui o banco `neo4j` existente: use apenas um volume de laboratório sem dados a preservar.

```bash
docker stop "$CONTAINER"
```

### 3.4. Executar a importação com um contêiner temporário

Execute no diretório que contém os CSVs:

```bash
docker run --rm \
  --volumes-from "$CONTAINER" \
  --mount "type=bind,source=$(pwd),target=/csv,readonly" \
  "$IMAGE" \
  neo4j-admin database import full \
  --overwrite-destination=true \
  --nodes=Estrela=/csv/estrelas.csv \
  --nodes=Planeta=/csv/planetas.csv \
  --nodes=Observatorio=/csv/observatorios.csv \
  --relationships=ORBITA=/csv/orbitas.csv \
  --relationships=DESCOBERTO_POR=/csv/descobertas.csv \
  neo4j
```

O comando `docker run --rm` cria um contêiner temporário, removido após a execução. O parâmetro `--volumes-from` compartilha os volumes do contêiner principal, incluindo `/data`. O `--mount` disponibiliza os arquivos CSV dentro do contêiner temporário em /csv. A definição da variável `$IMAGE` utiliza a mesma imagem do Neo4j principal. O `neo4j-admin database import full` executa a importação, com parâmetros `--overwrite-destination=true`, que substitui o banco de destino eventualmente existente, `--nodes` que importa as entidades e seus respectivos rótulos e `--relationships` importa os relacionamentos. 

### 3.5. Reiniciar o Neo4j

Após confirmar que a importação terminou sem erros:

```bash
docker start "$CONTAINER"
```

Acesse o Neo4j Browser: `http://localhost:7474`

### 3.6. Validar os dados importados

Execute no Neo4j Browser. Faça a contagem de nós por tipo:

```sql
MATCH (n)
RETURN labels(n) AS tipo, count(n) AS quantidade;
```

Contagem de relacionamentos:

```sql
MATCH ()-[r]->()
RETURN type(r) AS tipo, count(r) AS quantidade;
```

Visualização do grafo:

```sql
MATCH (n)-[r]->(m)
RETURN n, r, m
LIMIT 100;
```
Verifique se as entidades Estrela, Planeta e Observatorio foram importadas e se os relacionamentos ORBITA e DESCOBERTO_POR estão presentes. Realize consultas Cypher para explorar os dados. Algumas consultas sugeridas:

- Encontrar todos os planetas descobertos por um determinado observatório.
- Listar planetas com temperaturas acima de um certo limiar.
- Descobrir quais estrelas têm o maior número de planetas orbitando.

```sql
// Encontrar planetas descobertos a partir de um observatório específico:
MATCH (p:Planeta)-[:DESCOBERTO_POR]->(o:Observatorio {nome: 'Kepler'})
RETURN p.nome, p.pl_eqt
```

```sql
//Listar estrelas com mais de três planetas:

MATCH (s:Estrela)<-[:ORBITA]-(p:Planeta)
WITH s, COUNT(p) AS num_planetas
WHERE num_planetas > 3
RETURN s.nome, num_planetas
```

```sql
// Encontrar planetas dentro de uma certa faixa de temperatura que transitem sua estrela:

MATCH (p:Planeta)-[:ORBITA]->(s:Estrela)
WHERE p.pl_eqt > 200 AND p.pl_eqt < 300
RETURN p.nome, s.nome, p.pl_eqt
```

```sql
//Estrelas com planetas que têm massa maior que 10 massas terrestres:

MATCH (p:Planeta)-[:ORBITA]->(s:Estrela)
WHERE p.pl_masse > 10
RETURN s.nome, COLLECT(p.nome) AS planetas_pesados
```

```sql
//Observatórios e o número de planetas descobertos por ano:

MATCH (p:Planeta)-[:DESCOBERTO_POR]->(o:Observatorio)
RETURN o.nome, p.disc_year, COUNT(*) AS num_planetas
ORDER BY o.nome, p.disc_year
```

```sql
//Relacionamento entre planetas e estrelas com detalhes sobre as órbitas:

MATCH (p:Planeta)-[r:ORBITA]->(s:Estrela)
RETURN p.nome, s.nome, r.semi_eixo_maior, r.excentricidade
```

```sql
//Encontrar pares de planetas no mesmo sistema com temperaturas similares:

MATCH (p1:Planeta)-[:ORBITA]->(s:Estrela)<-[:ORBITA]-(p2:Planeta)
WHERE p1.pl_eqt >= p2.pl_eqt - 10 AND p1.pl_eqt <= p2.pl_eqt + 10 AND p1 <> p2
RETURN p1.nome, p2.nome, p1.pl_eqt, p2.pl_eqt
```

### Análise e Discussão
Analise os resultados das consultas. Discuta como o modelo de grafos facilitou ou dificultou a representação e consulta dos dados astronômicos.

### Desafio 2: Knowledge Graphs e Recomendação de Cursos

Neste laboratório, vamos aplicar os conceitos de bancos de dados orientados a grafos utilizando o Neo4j.

A atividade utiliza um catálogo fictício de cursos, desenvolvido por Mahdi Habibi no livro *Knowledge Graphs: Semantic Graphs and Property Graphs*.

Ao final, você deverá ser capaz de:

1. Construir um grafo com nós, propriedades e relacionamentos.
2. Consultar dados utilizando Cypher.
3. Percorrer relacionamentos e identificar dependências.
4. Aplicar filtros e agregações.
5. Implementar consultas de recomendação baseadas em regras.
6. Modificar o grafo e analisar o impacto das alterações.

**Importante:** a atividade deverá ser executada individualmente durante a aula, com entrega dos resultados ao final.

---

## Contextualização

Imagine uma plataforma de ensino que precisa recomendar cursos aos estudantes.

Cada estudante possui interesses específicos, já concluiu determinados cursos e somente pode realizar uma disciplina quando seus pré-requisitos forem atendidos.

O sistema precisa responder:

**Qual curso determinado aluno pode realizar agora, considerando seus interesses e os pré-requisitos já concluídos?**

### Modelo de dados

O grafo contém três tipos de entidades:

| Entidade | Descrição |
|---|---|
| `Person` | Estudantes cadastrados |
| `Course` | Cursos disponíveis |
| `Topic` | Assuntos relacionados aos cursos |

Os relacionamentos são:

| Relacionamento | Significado |
|---|---|
| `LIKES_TOPIC` | Um estudante tem interesse em determinado assunto |
| `COMPLETED` | Um estudante concluiu determinado curso |
| `ABOUT` | Um curso aborda determinado assunto |
| `REQUIRES` | Um curso possui outro curso como pré-requisito |

### Catálogo inicial

| ID | Curso | Duração | Assunto | Pré-requisito |
|---|---|---|---|---|
| c1 | Graph Basics | 60 min | Graphs | Nenhum |
| c2 | Graph Search | 90 min | Graphs | c1 |
| c3 | Query Patterns | 75 min | Data | c1 |
| c4 | Data Ethics | 45 min | Ethics | Nenhum |

Os estudantes são:

- **Maya:** gosta de Graphs e concluiu Graph Basics.
- **Leo:** gosta de Data e concluiu Graph Basics.

### Regras de recomendação

Um curso somente poderá ser recomendado quando:

1. Seu assunto corresponder ao interesse do estudante.
2. O estudante ainda não tiver concluído o curso.
3. Todos os pré-requisitos registrados estiverem concluídos.

Essas regras serão utilizadas nas próximas atividades.

---

# Construção e exploração do grafo

## Preparação do ambiente

Utilize o ambiente Neo4j disponibilizado ou configurado na aula anterior.

1. Acesse o Neo4j Browser.
2. Conecte-se à sua instância.
3. Utilize uma instância de exercício vazia e individual, separada da utilizada no desafio de astronomia.
4. Execute os comandos Cypher apresentados a seguir, na sequência indicada.

**Atenção:** não utilize o banco do Movie Graph ou qualquer base contendo dados que deseja preservar. Não execute comandos de exclusão indiscriminada.

### Verificar o banco

Execute:

```cypher
MATCH (n)
RETURN count(n) AS total_nos;
```

O resultado esperado é:

```text
total_nos
---------
0
```

Caso o resultado não seja zero, selecione uma base de exercícios vazia antes de continuar.

## Construção do catálogo

Os comandos desta seção foram adaptados do arquivo `lab/catalog.cypher` do repositório original.

**Execute cada bloco separadamente.** Os comandos de carga usam `MERGE`, permitindo repetir a carga sem criar duplicatas no cenário proposto.

### Criar restrições de unicidade

```cypher
CREATE CONSTRAINT person_id IF NOT EXISTS
FOR (p:Person) REQUIRE p.id IS UNIQUE;
```

```cypher
CREATE CONSTRAINT course_id IF NOT EXISTS
FOR (c:Course) REQUIRE c.id IS UNIQUE;
```

```cypher
CREATE CONSTRAINT topic_id IF NOT EXISTS
FOR (t:Topic) REQUIRE t.id IS UNIQUE;
```

### Criar os estudantes

```cypher
UNWIND [
  {id:'maya', name:'Maya'},
  {id:'leo', name:'Leo'}
] AS row

MERGE (p:Person {id:row.id})
SET p.name = row.name;
```

### Criar os assuntos

```cypher
UNWIND [
  {id:'graphs', name:'Graphs'},
  {id:'data', name:'Data'},
  {id:'ethics', name:'Ethics'}
] AS row

MERGE (t:Topic {id:row.id})
SET t.name = row.name;
```

### Criar os cursos

```cypher
UNWIND [
  {id:'c1', title:'Graph Basics', minutes:60},
  {id:'c2', title:'Graph Search', minutes:90},
  {id:'c3', title:'Query Patterns', minutes:75},
  {id:'c4', title:'Data Ethics', minutes:45}
] AS row

MERGE (c:Course {id:row.id})
SET c.title = row.title,
    c.durationMinutes = row.minutes;
```

### Relacionar os interesses

```cypher
UNWIND [
  {person:'maya', topic:'graphs'},
  {person:'leo', topic:'data'}
] AS row

MATCH (p:Person {id:row.person})
MATCH (t:Topic {id:row.topic})

MERGE (p)-[:LIKES_TOPIC]->(t);
```

### Registrar os cursos concluídos

```cypher
UNWIND ['maya', 'leo'] AS personId

MATCH (p:Person {id:personId})
MATCH (c:Course {id:'c1'})

MERGE (p)-[:COMPLETED]->(c);
```

### Relacionar cursos e assuntos

```cypher
UNWIND [
  {course:'c1', topic:'graphs'},
  {course:'c2', topic:'graphs'},
  {course:'c3', topic:'data'},
  {course:'c4', topic:'ethics'}
] AS row

MATCH (c:Course {id:row.course})
MATCH (t:Topic {id:row.topic})

MERGE (c)-[:ABOUT]->(t);
```

### Criar os pré-requisitos

```cypher
UNWIND ['c2', 'c3'] AS courseId

MATCH (c:Course {id:courseId})
MATCH (r:Course {id:'c1'})

MERGE (c)-[:REQUIRES]->(r);
```

## Validar a construção

### Contar os nós

```cypher
MATCH (n)
RETURN labels(n)[0] AS tipo,
       count(n) AS quantidade
ORDER BY tipo;
```

Resultado esperado:

| Tipo | Quantidade |
|---|---:|
| Course | 4 |
| Person | 2 |
| Topic | 3 |

**Total: 9 nós.**

### Contar os relacionamentos

```cypher
MATCH ()-[r]->()
RETURN type(r) AS tipo,
       count(r) AS quantidade
ORDER BY tipo;
```

Resultado esperado:

| Tipo | Quantidade |
|---|---:|
| ABOUT | 4 |
| COMPLETED | 2 |
| LIKES_TOPIC | 2 |
| REQUIRES | 2 |

**Total: 10 relacionamentos.**

### Visualizar o grafo

```cypher
MATCH (n)-[r]->(m)
RETURN n, r, m;
```

Selecione a visualização **Graph** no Neo4j Browser.

Observe as entidades, os relacionamentos, suas direções e os agrupamentos formados:

- O grafo construído.
- A consulta com 9 nós.
- A consulta com 10 relacionamentos.

## Explorando os dados

A partir deste ponto, você deverá construir e executar consultas Cypher.

Considere o exemplo:

```cypher
MATCH (c:Course)
RETURN c.id AS codigo,
       c.title AS curso
ORDER BY codigo;
```

O comando identifica todos os nós `Course` e retorna os atributos selecionados.

### Desafio — Consultas básicas

Escreva consultas para responder:

1. Quais cursos estão cadastrados?
2. Quais cursos têm duração de até 75 minutos?
3. Quais cursos pertencem ao assunto Graphs?
4. Quantos cursos existem em cada assunto?
5. Quais cursos possuem pré-requisitos e quais são esses pré-requisitos?

**Dicas:** utilize `MATCH`, `WHERE`, `RETURN`, `count()`, `ORDER BY` e padrões de relacionamento.

Resultados para conferência:

- Existem 4 cursos cadastrados.
- Existem 3 cursos com duração de até 75 minutos.
- O assunto Graphs possui 2 cursos.
- Os cursos c2 e c3 exigem c1.

## Explorando relacionamentos entre estudantes e cursos

### Desafio — Travessia de grafos

Construa consultas para identificar:

1. Quais assuntos interessam à Maya?
2. Quais cursos Maya concluiu?
3. Quais cursos Leo concluiu?
4. Quais estudantes concluíram Graph Basics?
5. Quais cursos estão relacionados aos interesses de Leo?

Para começar, observe o padrão:

```cypher
MATCH (p:Person)-[:COMPLETED]->(c:Course)
RETURN p.name AS estudante,
       c.title AS curso;
```

Altere os padrões e filtros conforme necessário para resolver as demais questões.

## Sistema de recomendação

Agora vamos construir uma consulta que aplica as regras de elegibilidade definidas anteriormente.

### Recomendação para Maya

Execute:

```cypher
MATCH (m:Person {id:'maya'})-[:LIKES_TOPIC]->(t)
      <-[:ABOUT]-(c:Course)

WHERE c.id IS NOT NULL
  AND c.title IS NOT NULL

  AND NOT EXISTS {
    MATCH (m)-[:COMPLETED]->(c)
  }

  AND NOT EXISTS {
    MATCH (c)-[:REQUIRES]->(required)
    WHERE NOT EXISTS {
      MATCH (m)-[:COMPLETED]->(required)
    }
  }

RETURN DISTINCT
       c.id AS id,
       c.title AS title
ORDER BY id;
```

**Resultado esperado:**

| id | title |
|---|---|
| c2 | Graph Search |

### Entendendo a consulta

Responda:

1. O que o primeiro `MATCH` identifica?
2. Por que utilizamos `NOT EXISTS` para verificar cursos concluídos?
3. Qual a finalidade do segundo `NOT EXISTS`?
4. Por que utilizamos `DISTINCT`?
5. O que aconteceria se Maya não tivesse concluído Graph Basics?

### Desafio — Recomendação para Leo

Modifique a consulta anterior para recomendar cursos ao estudante Leo. Explique por que Graph Search não é recomendado para Leo, mesmo ele tendo concluído o pré-requisito Graph Basics.


## Alteração das regras de negócio

Imagine que a instituição alterou o currículo.

Agora, para realizar **Graph Search**, o estudante também precisa ter concluído **Data Ethics**.

### Adicionar o novo pré-requisito

Execute:

```cypher
MATCH (c:Course {id:'c2'})
MATCH (r:Course {id:'c4'})

MERGE (c)-[:REQUIRES]->(r);
```

Execute novamente a consulta de recomendação de Maya.

### Desafio — Análise do impacto

Responda:

1. Maya ainda pode realizar Graph Search?
2. Por que o resultado mudou?
3. Quantos relacionamentos existem agora no grafo?
4. Qual é o conjunto atual de pré-requisitos de Graph Search?

**Resultado de conferência:** após a alteração, Maya não possui curso elegível entre os assuntos de seu interesse.

## Criar seu próprio estudante

Agora você deverá cadastrar um estudante individual, utilizando um identificador próprio.

Substitua `aluno_ab12` por um identificador formado a partir de suas iniciais e quatro caracteres escolhidos por você.

Utilize exatamente o mesmo identificador nas consultas seguintes.

### Criar o estudante

```cypher
MERGE (p:Person {id:'aluno_ab12'})
SET p.name = 'Aluno AB12';
```

### Registrar interesses

Seu estudante terá interesse nos assuntos Graphs e Data.

```cypher
MATCH (p:Person {id:'aluno_ab12'})
MATCH (t:Topic)

WHERE t.id IN ['graphs', 'data']

MERGE (p)-[:LIKES_TOPIC]->(t);
```

### Registrar o primeiro curso concluído

Seu estudante já concluiu Graph Basics.

```cypher
MATCH (p:Person {id:'aluno_ab12'})
MATCH (c:Course {id:'c1'})

MERGE (p)-[:COMPLETED]->(c);
```

## Recomendar cursos ao novo estudante

### Desafio — Personalização

Adapte a consulta de recomendação para Maya ao seu próprio estudante.

Observe os resultados e responda:

1. Quais cursos são recomendados?
2. Por que Graph Search não aparece inicialmente?
3. Quais pré-requisitos o estudante já concluiu?
4. Quais pré-requisitos ainda faltam?

**Resultado esperado antes da próxima alteração:** somente `c3 — Query Patterns`.

### Registrar outra conclusão

Agora, considere que seu estudante também concluiu Data Ethics.

Execute:

```cypher
MATCH (p:Person {id:'aluno_ab12'})
MATCH (c:Course {id:'c4'})

MERGE (p)-[:COMPLETED]->(c);
```

### Desafio — Recalcular a recomendação

Execute novamente sua consulta.

Responda:

1. Quais cursos são recomendados agora?
2. O que mudou em relação ao resultado anterior?
3. Qual relacionamento foi responsável pela mudança?
4. Como o sistema garante que todos os pré-requisitos registrados foram atendidos?

**Resultado esperado:** `c2 — Graph Search` e `c3 — Query Patterns`.

## Analisar o plano de execução

O Neo4j permite examinar como uma consulta será processada.

Execute:

```cypher
EXPLAIN
MATCH (c:Course)
WHERE c.id = 'c2'
RETURN c.title;
```

Observe o plano apresentado.

Depois execute:

```cypher
PROFILE
MATCH (c:Course)
WHERE c.id = 'c2'
RETURN c.title;
```

Identifique as operações utilizadas para localizar o curso.

**Questões:**

1. Qual a diferença entre `EXPLAIN` e `PROFILE`?
2. A consulta utilizou um índice ou uma varredura de nós?
3. Qual a importância da restrição de unicidade criada no início do laboratório?
4. Por que bancos de dados orientados a grafos são adequados para aplicações com relacionamentos e regras de dependência, como sistemas de recomendação de cursos?

## Conclusão

Analise os resultados das consultas. Discuta como o modelo de grafos facilitou ou dificultou a representação e consulta dos dados. 
