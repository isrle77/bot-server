from flask import Flask, request, jsonify
from flask_cors import CORS
import pandas as pd
import os

app = Flask(__name__)
CORS(app)

SHEET_URL = "https://docs.google.com/spreadsheets/d/e/2PACX-1vSpbLpst0sFzIkzLZi0JwpVdEsysGyBwTTlUp9LwE-I6uvq9jepjwGfHOZGXUHqrmBr8Ex08mrweLIm/pub?output=csv"


def load_rows():
    df = pd.read_csv(SHEET_URL)

    # מצפה לשתי עמודות:
    # keywords | answer
    rows = []
    for _, r in df.iterrows():
        if pd.isna(r[0]) or pd.isna(r[1]):
            continue

        rows.append({
            "keywords": str(r[0]).lower(),
            "answer": str(r[1])
        })

    return rows


def score(question, keywords):
    words = question.lower().split()
    return sum(w in keywords for w in words)


@app.route("/search", methods=["POST"])
def search():
    data = request.get_json() or {}
    q = data.get("question", "").strip()

    if not q:
        return {"error": "no question"}, 400

    rows = load_rows()

    if not rows:
        return {"error": "sheet empty"}, 400

    best = max(rows, key=lambda r: score(q, r["keywords"]))

    return jsonify({
        "match": best["answer"]
    })


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=int(os.environ.get("PORT", 5001))
    )