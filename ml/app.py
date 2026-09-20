from flask import Flask, request, jsonify
from transformers import pipeline

app = Flask(__name__)

classifier = pipeline(
    "zero-shot-classification",
    model="facebook/bart-large-mnli"
)

labels = ["REAL", "FAKE", "UNCERTAIN"]


@app.route("/predict", methods=["POST"])
def predict():
    data = request.get_json()
    claim = data.get("claim", "")

    result = classifier(
        claim,
        candidate_labels=labels
    )

    return jsonify({
        "label": result["labels"][0],
        "confidence": round(result["scores"][0], 2)
    })


if __name__ == "__main__":
    app.run(debug=True)