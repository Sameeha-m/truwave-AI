from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class VerifyRequest(BaseModel):
   claim: str = Field(min_length=1)


class Source(BaseModel):
   name: str
   title: str
   url: str


class VerifyResponse(BaseModel):
   verdict: str
   confidence: float
   summary: str
   findings: list[str]
   sources: list[Source]


@app.post("/verify", response_model=VerifyResponse)
def verify(request: VerifyRequest) -> VerifyResponse:
   return VerifyResponse(
      verdict="REAL",
      confidence=0.85,
      summary="Mock verification result for the MVP.",
      findings=["Mock finding for demonstration."],
      sources=[
         Source(
            name="Example Source",
            title="Example verification source",
            url="https://example.com",
         )
      ],
   )
