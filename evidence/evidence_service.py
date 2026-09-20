import requests
from bs4 import BeautifulSoup
from urllib.parse import quote


def search_web(claim):
    url = "https://www.google.com/search?q=" + quote(claim)

    headers = {
        "User-Agent": "Mozilla/5.0"
    }

    response = requests.get(
        url,
        headers=headers,
        timeout=10
    )

    soup = BeautifulSoup(response.text, "html.parser")

    results = []

    for link in soup.find_all("a"):
        href = link.get("href")
        text = link.get_text(" ", strip=True)

        if href and text and href.startswith("http"):
            # Skip Google internal pages
            if "google.com/search" in href:
                continue

            results.append({
                "name": text,
                "title": text,
                "url": href
            })

        if len(results) >= 5:
            break

    return results


def get_page_text(url):
    try:
        response = requests.get(
            url,
            headers={"User-Agent": "Mozilla/5.0"},
            timeout=10
        )

        soup = BeautifulSoup(response.text, "html.parser")

        for tag in soup(["script", "style", "noscript"]):
            tag.decompose()

        text = soup.get_text(" ", strip=True)

        return text[:2000]

    except Exception:
        return ""


def classify_evidence(claim, evidence_text):
    if not evidence_text:
        return "INSUFFICIENT"

    claim_words = set(claim.lower().split())
    evidence_words = set(evidence_text.lower().split())

    common_words = claim_words.intersection(evidence_words)

    if len(common_words) >= 2:
        return "SUPPORTING"

    return "INSUFFICIENT"


def build_evidence(claim, results):
    evidence = []

    for result in results:
        page_text = get_page_text(result["url"])

        classification = classify_evidence(
            claim,
            page_text
        )

        evidence.append({
            "name": result["name"],
            "title": result["title"],
            "url": result["url"],
            "evidence": page_text[:500],
            "classification": classification
        })

    return evidence


if __name__ == "__main__":

    claim = input("Enter your claim: ")

    results = search_web(claim)

    print("\nEvidence Results:\n")

    if not results:
        print("No web results found.")

    else:
        evidence = build_evidence(claim, results)

        for item in evidence:

            print("Title:", item["title"])
            print("URL:", item["url"])
            print("Classification:", item["classification"])

            if item["evidence"]:
                print("Evidence:", item["evidence"])
            else:
                print("Evidence: Could not fetch page")

            print("-" * 60)