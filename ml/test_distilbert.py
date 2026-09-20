from transformers import pipeline

print("Loading DistilBERT...")

classifier = pipeline(
    "sentiment-analysis",
    model="distilbert-base-uncased-finetuned-sst-2-english"
)

result = classifier("This is a great product!")

print(result)