#!/bin/bash

# Configurações
URL="http://localhost:5000/estudantes"
TOTAL=20000

# Lista de cursos de graduação
CURSOS=(
    "Engenharia de Software"
    "Ciência da Computação"
    "Sistemas de Informação"
    "Engenharia da Computação"
    "Análise e Desenvolvimento de Sistemas"
    "Matemática Aplicada"
    "Física Computacional"
    "Inteligência Artificial"
    "Ciência de Dados"
    "Engenharia Elétrica"
    "Engenharia Mecânica"
    "Administração"
    "Economia"
    "Design Digital"
    "Jogos Digitais"
    "Redes de Computadores"
    "Segurança da Informação"
    "Biomedicina"
    "Psicologia"
    "Arquitetura"
)

# Lista de nomes (primeiros nomes)
NOMES=(
    "João" "Maria" "José" "Ana" "Pedro" "Paula" "Lucas" "Mariana" "Felipe" "Carla"
    "Rafael" "Juliana" "Gustavo" "Amanda" "Daniel" "Bruna" "Thiago" "Fernanda"
    "Rodrigo" "Patrícia" "Leonardo" "Camila" "Bruno" "Letícia" "Eduardo" "Beatriz"
    "Vinicius" "Natália" "André" "Vanessa" "Diego" "Larissa" "Matheus" "Gabriela"
    "Renato" "Isabela" "Henrique" "Lorena" "Caio" "Tatiane" "Arthur" "Luciana"
)

# Lista de sobrenomes
SOBRENOMES=(
    "Silva" "Santos" "Oliveira" "Souza" "Rodrigues" "Ferreira" "Alves" "Pereira"
    "Lima" "Gomes" "Costa" "Ribeiro" "Martins" "Carvalho" "Almeida" "Nascimento"
    "Araújo" "Barbosa" "Mendes" "Nunes" "Rocha" "Teixeira" "Machado" "Moraes"
    "Cardoso" "Correia" "Farias" "Cavalcanti" "Dias" "Castro" "Campos" "Freitas"
)

echo "Iniciando inserção de $TOTAL estudantes..."
echo "URL: $URL"
echo ""

# Contadores para feedback
SUCESSO=0
FALHA=0

for i in $(seq 1 $TOTAL); do
    # Gerar idade aleatória entre 17 e 60 anos
    IDADE=$((RANDOM % 44 + 17))
    
    # Escolher curso aleatório
    CURSO_INDEX=$((RANDOM % ${#CURSOS[@]}))
    CURSO="${CURSOS[$CURSO_INDEX]}"
    
    # Gerar nome completo aleatório
    NOME_INDEX=$((RANDOM % ${#NOMES[@]}))
    SOBRENOME_INDEX=$((RANDOM % ${#SOBRENOMES[@]}))
    NOME="${NOMES[$NOME_INDEX]} ${SOBRENOMES[$SOBRENOME_INDEX]}"
    
    # Adicionar sufixo opcional para evitar nomes muito repetidos (em alguns casos)
    if [ $((RANDOM % 10)) -eq 0 ]; then
        SUFIXOS=("Jr" "Filho" "Neto" "Sobrinho")
        SUFIXO_INDEX=$((RANDOM % ${#SUFIXOS[@]}))
        NOME="$NOME ${SUFIXOS[$SUFIXO_INDEX]}"
    fi
    
    # Construir o JSON
    JSON_DATA=$(cat <<EOF
{
  "curso": "$CURSO",
  "idade": $IDADE,
  "nome": "$NOME"
}
EOF
)
    
    # Fazer a requisição POST
    RESPONSE=$(curl -s -X POST "$URL" \
        -H "accept: application/json" \
        -H "Content-Type: application/json" \
        -d "$JSON_DATA" \
        -w "\n%{http_code}")
    
    # Extrair o código HTTP da resposta
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    
    # Verificar se foi bem sucedido (código 200, 201 ou 204)
    if [[ $HTTP_CODE -eq 200 ]] || [[ $HTTP_CODE -eq 201 ]] || [[ $HTTP_CODE -eq 204 ]]; then
        SUCESSO=$((SUCESSO + 1))
        echo "[$i/$TOTAL] ✓ Inserido: $NOME - $CURSO - $IDADE anos"
    else
        FALHA=$((FALHA + 1))
        echo "[$i/$TOTAL] ✗ Falha ao inserir: $NOME - $CURSO - $IDADE anos (HTTP $HTTP_CODE)"
        echo "    Erro: $BODY"
    fi
    
    # Pequena pausa para não sobrecarregar o servidor (opcional)
    # sleep 0.01
    
    # Mostrar progresso a cada 1000 requisições
    if [ $((i % 1000)) -eq 0 ]; then
        echo ""
        echo "--- Progresso: $i/$TOTAL inserções processadas ---"
        echo "Sucessos: $SUCESSO | Falhas: $FALHA"
        echo ""
    fi
done

echo ""
echo "========================================="
echo "Inserção concluída!"
echo "Total processado: $TOTAL"
echo "Sucessos: $SUCESSO"
echo "Falhas: $FALHA"
echo "========================================="