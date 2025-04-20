import json
import os
from flask import Flask, Response, request
from google.cloud import firestore

db = firestore.Client()

# Specify the collection and document
collection_name = "candidates"

# Flask app
candidates_app = Flask(__name__)
instance_id = os.popen("hostname -i").read().strip()

@candidates_app.route("/", methods=["GET"])
def default():
    return {"status": "invalid request"}, 400

@candidates_app.route("/gtg", methods=["GET"])
def gtg():
    details = request.args.get("details")

    if "details" in request.args:
        return {"connected": "true", "instance-id": instance_id}, 200
    else:
        return Response(status=200)

@candidates_app.route("/candidate/<name>", methods=["GET"])
def get_candidate(name):
    try:
        doc_ref = db.collection(collection_name).document(name)
        doc = doc_ref.get()

        if doc.exists:
              return doc.to_dict(), 200
        else:
              return "Not Found", 404
    except:
        return "Not Found", 404

@candidates_app.route("/candidate/<name>", methods=["POST"])
def post_candidate(name):
    try:
        doc_id = name
        data = { "CandidateName" : name }
        doc_ref = db.collection(collection_name).document(doc_id)
        doc_ref.set(data)
        return data, 200
    except:
        return "Not Found", 404

@candidates_app.route("/candidates", methods=["GET"])
def get_candidates():
    try:
        names_array = []
        docs = db.collection(collection_name).stream()

        for doc in docs:
              names_array.append(doc.to_dict())

        return json.dumps(names_array), 200
    except:
        return "Not Found", 404
