from fastapi.testclient import TestClient

from backend.config import load_settings
from backend.main import create_app
from evidence.base import EvidenceItem, ProviderAuthError, SourceTier, Stance


def _settings(**env):
    return load_settings(env, load_env_file=False)


def test_verify_uses_mock_classifier_and_fixture_evidence_with_public_contract():
    client = TestClient(create_app(
        settings=_settings(EVIDENCE_PROVIDER="fixture")
    ))

    response = client.post("/verify", json={"claim": "Drinking bleach cures viral infections"})

    assert response.status_code == 200
    body = response.json()
    assert set(body) == {"verdict", "confidence", "summary", "findings", "sources"}
    assert body["verdict"] == "FAKE"
    assert isinstance(body["confidence"], float)
    assert isinstance(body["summary"], str) and body["summary"]
    assert isinstance(body["findings"], list)
    assert body["sources"]
    assert all(set(source) == {"name", "title", "url"} for source in body["sources"])


def test_verify_returns_uncertain_when_no_direct_evidence_is_found():
    client = TestClient(create_app(
        settings=_settings(EVIDENCE_PROVIDER="fixture")
    ))

    response = client.post("/verify", json={"claim": "An unreviewed claim with no matching evidence"})

    assert response.status_code == 200
    assert response.json()["verdict"] == "UNCERTAIN"
    assert response.json()["sources"] == []


class RelatedFalseProvider:
    name = "related_test"

    async def search(self, claim):
        return [EvidenceItem(
            provider=self.name,
            publisher_name="Fact-check source",
            publisher_site="factcheck.org",
            title="Related disinfectant claim",
            url="https://factcheck.org/related",
            stance=Stance.REFUTES,
            raw_rating="False",
            reviewed_claim="MMS chlorine dioxide can prevent coronavirus",
            tier=SourceTier.KNOWN,
        )]


def test_related_evidence_is_returned_as_context_but_cannot_establish_verdict():
    client = TestClient(create_app(
        settings=_settings(), evidence_providers=[RelatedFalseProvider()]
    ))

    response = client.post("/verify", json={"claim": "Drinking bleach cures COVID-19"})

    assert response.status_code == 200
    body = response.json()
    assert body["verdict"] == "UNCERTAIN"
    assert body["sources"][0]["url"] == "https://factcheck.org/related"
    assert any("related context" in finding for finding in body["findings"])


class FailingEvidenceProvider:
    name = "failure_test"

    async def search(self, claim):
        raise ProviderAuthError("private API_KEY_INVALID SECRET_VALUE")


def test_google_style_evidence_failure_is_sanitized_503():
    client = TestClient(create_app(
        settings=_settings(), evidence_providers=[FailingEvidenceProvider()]
    ))

    response = client.post("/verify", json={"claim": "A claim to verify"})

    assert response.status_code == 503
    assert response.json() == {
        "detail": "Verification is temporarily unavailable. Please try again."
    }
    assert "SECRET_VALUE" not in response.text
    assert "API_KEY_INVALID" not in response.text
