#!/bin/bash

# Script para inserir 1000 estudantes aleatórios via API
# URL base da API
BASE_URL="http://localhost:5000/estudantes"

# Arrays de dados para gerar combinações aleatórias
nomes=("Ana" "João" "Maria" "Pedro" "Paulo" "Lucas" "Mariana" "Beatriz" "Rafael" "Julia" 
       "Gabriel" "Camila" "Felipe" "Amanda" "Bruno" "Isabela" "Diego" "Larissa" "Thiago" "Carla"
       "Vinícius" "Fernanda" "Rodrigo" "Patrícia" "Eduardo" "Aline" "Gustavo" "Vanessa" "Leonardo" "Tatiana"
       "Ricardo" "Priscila" "Marcelo" "Renata" "André" "Sandra" "Alexandre" "Michele" "Fernando" "Daniela"
       "Roberto" "Cristina" "Antônio" "Cláudia" "Carlos" "Adriana" "José" "Simone" "Francisco" "Natália")

cursos=("Engenharia" "Medicina" "Direito" "Administração" "Ciência da Computação" 
        "Arquitetura" "Psicologia" "Odontologia" "Economia" "Farmácia"
        "Enfermagem" "Veterinária" "Jornalismo" "Publicidade" "Design"
        "Matemática" "Física" "Química" "Biologia" "História"
        "Geografia" "Letras" "Filosofia" "Sociologia" "Artes"
        "Educação Física" "Música" "Teatro" "Cinema" "Gastronomia")

# Cores para output
VERDE='\033[0;32m'
VERMELHO='\033[0;31m'
AMARELO='\033[1;33m'
AZUL='\033[0;34m'
SEM_COR='\033[0m'

# Contadores
sucessos=0
falhas=0

echo -e "${AZUL}========================================${SEM_COR}"
echo -e "${AZUL}INICIANDO INSERÇÃO DE 1000 ESTUDANTES${SEM_COR}"
echo -e "${AZUL}========================================${SEM_COR}\n"

# Loop para inserir 1000 estudantes
for i in {1..1000}; do
    # Selecionar nome aleatório
    nome_aleatorio=${nomes[$RANDOM % ${#nomes[@]}]}
    
    # Adicionar sobrenome numérico para evitar duplicatas
    numero=$((RANDOM % 1000))
    nome_completo="${nome_aleatorio}${numero}"
    
    # Gerar idade aleatória entre 18 e 60 anos
    idade_aleatoria=$((RANDOM % 43 + 18))
    
    # Selecionar curso aleatório
    curso_aleatorio=${cursos[$RANDOM % ${#cursos[@]}]}
    
    # Criar payload JSON
    json_data=$(cat <<EOF
{
    "nome": "$nome_completo",
    "idade": $idade_aleatoria,
    "curso": "$curso_aleatorio"
}
EOF
)
    
    # Fazer a requisição POST
    response=$(curl -s -X POST "$BASE_URL" \
        -H "Content-Type: application/json" \
        -d "$json_data" \
        -w "\n%{http_code}" \
        --output /dev/null)
    
    # Extrair código HTTP da última linha
    http_code=$(echo "$response" | tail -n1)
    
    # Verificar se a requisição foi bem sucedida (códigos 2xx)
    if [[ $http_code -ge 200 && $http_code -lt 300 ]]; then
        ((sucessos++))
        echo -e "${VERDE}[$i] ✓ Inserido: $nome_completo, $idade_aleatoria anos, $curso_aleatorio (HTTP $http_code)${SEM_COR}"
    else
        ((falhas++))
        echo -e "${VERMELHO}[$i] ✗ Falha ao inserir: $nome_completo (HTTP $http_code)${SEM_COR}"
    fi
    
    # Pequena pausa para não sobrecarregar a API (opcional)
    # sleep 0.1
    
done

echo -e "\n${AZUL}========================================${SEM_COR}"
echo -e "${AZUL}RESUMO DA OPERAÇÃO${SEM_COR}"
echo -e "${AZUL}========================================${SEM_COR}"
echo -e "${VERDE}Inserções bem sucedidas: $sucessos${SEM_COR}"
echo -e "${VERMELHO}Falhas: $falhas${SEM_COR}"
echo -e "${AMARELO}Total processado: $((sucessos + falhas))${SEM_COR}"

if [[ $falhas -eq 0 ]]; then
    echo -e "\n${VERDE}✓ TODOS OS 1000 ESTUDANTES FORAM INSERIDOS COM SUCESSO!${SEM_COR}"
else
    echo -e "\n${VERMELHO}✗ ALGUMAS INSERÇÕES FALHARAM. VERIFIQUE A API.${SEM_COR}"
fi