from flask import Flask, request, jsonify
from flask_cors import CORS
import pandas as pd
import os

app = Flask(__name__)
CORS(app)

SHEET_URL = "https://docs.google.com/spreadsheets/d/e/2PACX-1vSpbLpst0sFzIkzLZi0JwpVdEsysGyBwTTlUp9LwE-I6uvq9jepjwGfHOZGXUHqrmBr8Ex08mrweLIm/pub?output=csv"


def load_rows():
    df = pd.read_csv(SHEET_URL)

    # מנקה רווחים בשמות עמודות
    df.columns = df.columns.str.strip()

    print("COLUMNS:", df.columns.tolist())

    if "keywords" not in df.columns or "answer" not in df.columns:
        raise Exception("Sheet must have keywords + answer columns")

    rows = []

    for _, r in df.iterrows():
        if pd.isna(r["keywords"]) or pd.isna(r["answer"]):
            continue

        keys = str(r["keywords"]).lower().split()
        ans = str(r["answer"])

        rows.append((keys, ans))

    return rows


def score(question, keywords):
    words = question.lower().split()
    return sum(w in keywords for w in words)


@app.route("/search", methods=["POST"])
def search():
    data = request.get_json() or {}
    q = data.get("question", "").lower()

    rows = load_rows()

    for keys, ans in rows:
        for k in keys:
            if k in q:
                return {"answer": ans}

    return {"answer": "No match"}


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=int(os.environ.get("PORT", 5001))
    )