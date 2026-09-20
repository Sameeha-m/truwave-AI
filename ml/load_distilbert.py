import pandas as pd

# Load our test dataset
df = pd.read_csv("data/mvp_test.csv")

# Show the dataset
print(df)

# Show how many examples we have for each label
print("\nLabel counts:")
print(df["label"].value_counts())