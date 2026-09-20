from transformers import pipeline

classifier = pipeline(
    "sentiment-analysis",
    model="distilbert-base-uncased-finetuned-sst-2-english"
)

def predict_claim(text):
    result = classifier(text)[0]

    if result["label"] == "POSITIVE":
        label = "REAL"
    else:
        label = "FAKE"

    return {
        "label": label,
        "confidence": round(result["score"], 2)
    }


claim = input("Enter claim: ")

print(predict_claim(claim))