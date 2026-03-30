from flask import Flask, request, jsonify
from pymongo import MongoClient
from flasgger import Swagger
from joblib import load
import os

app = Flask(__name__)

# Configuração do Swagger
app.config['SWAGGER'] = {
    'title': 'API de Previsão com MongoDB',
    'version': '1.0.0',
    'description': 'API para gerenciamento de estudantes e previsão de qualidade de vinhos'
}

Swagger(app)

MONGO_URI = "mongodb://root:mongo@mongo_service:27017"

client = MongoClient(MONGO_URI)

db = client["AulaDemo"]
colecao = db["Estudantes"]

@app.route("/")
def status():
    """
    Status da API
    ---
    tags:
      - Status
    responses:
      200:
        description: API online
        schema:
          type: object
          properties:
            status:
              type: string
              example: "API MongoDB local online"
    """
    return {"status": "API MongoDB local online"}


@app.route("/estudantes", methods=["POST"])
def inserir_estudante():
    """
    Inserir estudante
    ---
    tags:
      - Estudantes
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          properties:
            nome:
              type: string
              example: "João Silva"
            idade:
              type: integer
              example: 20
            curso:
              type: string
              example: "Engenharia de Software"
    responses:
      200:
        description: Estudante inserido com sucesso
        schema:
          type: object
          properties:
            msg:
              type: string
            id:
              type: string
    """

    data = request.json
    result = colecao.insert_one(data)

    return jsonify({
        "msg": "Estudante inserido",
        "id": str(result.inserted_id)
    })


@app.route("/estudantes", methods=["GET"])
def listar_estudantes():
    """
    Listar estudantes
    ---
    tags:
      - Estudantes
    responses:
      200:
        description: Lista de estudantes
        schema:
          type: array
          items:
            type: object
            properties:
              _id:
                type: string
              nome:
                type: string
              idade:
                type: integer
              curso:
                type: string
    """

    docs = []

    for doc in colecao.find():
        doc["_id"] = str(doc["_id"])
        docs.append(doc)

    return jsonify(docs)

# Obter o caminho completo para o arquivo modelo.pkl na pasta models
modelo_path = os.path.join('models', 'modelo_v1.pkl')

# Carregar o modelo
modelo = load(modelo_path)

# Dados fictícios de exemplo
exemplo = {
    "fixed acidity": 7.0,
    "volatile acidity": 0.27,
    "citric acid": 0.36,
    "residual sugar": 20.7,
    "chlorides": 0.045,
    "free sulfur dioxide": 45.0,
    "total sulfur dioxide": 170.0,
    "density": 1.0010,
    "pH": 3.00,
    "sulphates": 0.45,
    "alcohol": 8.8,
    "color": 1
}

@app.route('/example', methods=['GET'])
def example():
    """
    Exemplo de previsão com dados fixos
    ---
    tags:
      - Machine Learning
    responses:
      200:
        description: Retorna uma previsão de exemplo usando dados fixos
        schema:
          type: array
          items:
            type: string
          example: ["bom"]
      500:
        description: Erro interno ao processar a previsão
        schema:
          type: object
          properties:
            error:
              type: string
    """
    try:
        # Fazer uma previsão de exemplo
        previsao = modelo.predict([list(exemplo.values())])
        resultado = ['ruim' if pred == 1 else 'bom' for pred in previsao]
        return jsonify(resultado)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/predict', methods=['POST'])
def predict():
    """
    Previsão de qualidade do vinho
    ---
    tags:
      - Machine Learning
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          required:
            - fixed acidity
            - volatile acidity
            - citric acid
            - residual sugar
            - chlorides
            - free sulfur dioxide
            - total sulfur dioxide
            - density
            - pH
            - sulphates
            - alcohol
            - color
          properties:
            fixed acidity:
              type: number
              format: float
              description: Acidez fixa (g/dm³)
              example: 7.0
            volatile acidity:
              type: number
              format: float
              description: Acidez volátil (g/dm³)
              example: 0.27
            citric acid:
              type: number
              format: float
              description: Ácido cítrico (g/dm³)
              example: 0.36
            residual sugar:
              type: number
              format: float
              description: Açúcar residual (g/dm³)
              example: 20.7
            chlorides:
              type: number
              format: float
              description: Cloretos (g/dm³)
              example: 0.045
            free sulfur dioxide:
              type: number
              format: float
              description: Dióxido de enxofre livre (mg/dm³)
              example: 45.0
            total sulfur dioxide:
              type: number
              format: float
              description: Dióxido de enxofre total (mg/dm³)
              example: 170.0
            density:
              type: number
              format: float
              description: Densidade (g/cm³)
              example: 1.0010
            pH:
              type: number
              format: float
              description: pH
              example: 3.00
            sulphates:
              type: number
              format: float
              description: Sulfatos (g/dm³)
              example: 0.45
            alcohol:
              type: number
              format: float
              description: Teor alcoólico (% vol)
              example: 8.8
            color:
              type: integer
              description: Cor do vinho (1 = tinto, 0 = branco)
              example: 1
    responses:
      200:
        description: Retorna a previsão da qualidade do vinho
        schema:
          type: array
          items:
            type: string
          example: ["bom"]
      400:
        description: Dados inválidos ou campos faltando na requisição
        schema:
          type: object
          properties:
            error:
              type: string
      500:
        description: Erro interno ao processar a previsão
        schema:
          type: object
          properties:
            error:
              type: string
    """
    try:
        # Receber dados JSON da requisição
        data = request.get_json()

        # Validar se os dados foram enviados
        if not data:
            return jsonify({"error": "Nenhum dado foi enviado"}), 400

        # Lista de campos obrigatórios
        campos_obrigatorios = [
            'fixed acidity', 'volatile acidity', 'citric acid', 
            'residual sugar', 'chlorides', 'free sulfur dioxide',
            'total sulfur dioxide', 'density', 'pH', 'sulphates', 
            'alcohol', 'color'
        ]

        # Validar se todos os campos obrigatórios estão presentes
        for campo in campos_obrigatorios:
            if campo not in data:
                return jsonify({"error": f"Campo obrigatório ausente: {campo}"}), 400

        # Extrair os valores do JSON
        fixed_acidity = data['fixed acidity']
        volatile_acidity = data['volatile acidity']
        citric_acid = data['citric acid']
        residual_sugar = data['residual sugar']
        chlorides = data['chlorides']
        free_sulfur_dioxide = data['free sulfur dioxide']
        total_sulfur_dioxide = data['total sulfur dioxide']
        density = data['density']
        pH = data['pH']
        sulphates = data['sulphates']
        alcohol = data['alcohol']
        color = data['color']

        # Fazer a previsão usando o modelo
        predicao = modelo.predict([[
            fixed_acidity, volatile_acidity, citric_acid, 
            residual_sugar, chlorides, free_sulfur_dioxide, 
            total_sulfur_dioxide, density, pH, sulphates, 
            alcohol, color
        ]])

        # Mapear o resultado da previsão para uma resposta legível
        resultado = ['ruim' if pred == 1 else 'bom' for pred in predicao]

        # Retornar o resultado como JSON
        return jsonify(resultado)
    
    except KeyError as e:
        return jsonify({"error": f"Campo não encontrado: {str(e)}"}), 400
    except Exception as e:
        return jsonify({"error": f"Erro ao processar a previsão: {str(e)}"}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)