from flask import Flask, request, jsonify
from pymongo import MongoClient
from flasgger import Swagger
import os

app = Flask(__name__)
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
    responses:
      200:
        description: API online
    """
    return {"status": "API MongoDB local online"}


@app.route("/estudantes", methods=["POST"])
def inserir_estudante():
    """
    Inserir estudante
    ---
    parameters:
      - name: body
        in: body
        schema:
          type: object
          properties:
            nome:
              type: string
            idade:
              type: integer
            curso:
              type: string
    responses:
      200:
        description: Estudante inserido
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
    responses:
      200:
        description: Lista de estudantes
    """

    docs = []

    for doc in colecao.find():
        doc["_id"] = str(doc["_id"])
        docs.append(doc)

    return jsonify(docs)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
