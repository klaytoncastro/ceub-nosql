from flask import Flask, request, jsonify
from pymongo import MongoClient
import os

app = Flask(__name__)

MONGO_URI = os.getenv(
    "MONGO_URI",
    "mongodb://root:mongo@mongo:27017"
)

client = MongoClient(MONGO_URI)

db = client["AulaDemo"]
colecao = db["Estudantes"]


@app.route("/")
def status():
    return {"status": "API MongoDB local online"}


@app.route("/estudantes", methods=["POST"])
def inserir_estudante():

    data = request.json

    result = colecao.insert_one(data)

    return jsonify({
        "msg": "Estudante inserido",
        "id": str(result.inserted_id)
    })


@app.route("/estudantes", methods=["GET"])
def listar_estudantes():

    docs = []

    for doc in colecao.find():
        doc["_id"] = str(doc["_id"])
        docs.append(doc)

    return jsonify(docs)


@app.route("/estudantes/curso/<curso>", methods=["GET"])
def buscar_por_curso(curso):

    docs = []

    for doc in colecao.find({"curso": curso}):
        doc["_id"] = str(doc["_id"])
        docs.append(doc)

    return jsonify(docs)


@app.route("/estudantes/<nome>", methods=["DELETE"])
def deletar(nome):

    result = colecao.delete_one({"nome": nome})

    return jsonify({
        "removidos": result.deleted_count
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)