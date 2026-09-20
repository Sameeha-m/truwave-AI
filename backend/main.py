from fastapi import FastAPI
app = FastAPI()
@app.get("/verify")
def verify():
   return {"verified":True,"result":"mock verification"}
