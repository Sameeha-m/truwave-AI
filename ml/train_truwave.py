import pandas as pd
from transformers import AutoTokenizer

# Load dataset
df = pd.read_csv("data/mvp_test.csv")

# Convert labels
label_map = {
    "REAL": 0,
    "FAKE": 1,
    "UNCERTAIN": 2
}

df["label_id"] = df["label"].map(label_map)

# Load DistilBERT tokenizer
tokenizer = AutoTokenizer.from_pretrained(
    "distilbert-base-uncased"
)

# Tokenize claims
tokens = tokenizer(
    df["text"].tolist(),
    padding=True,
    truncation=True,
    return_tensors="pt"
)

print("Tokenizer test successful!")

print("\nInput shape:")
print(tokens["input_ids"].shape)

print("\nFirst claim:")
print(df["text"].iloc[0])
print("\nFirst claim token IDs:")
print(tokens["input_ids"][0])