from pathlib import Path

import joblib
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline


SAFE_SAMPLES = [
    "Bua sang giam can nen an gi",
    "Tinh calo cho bua trua gom com ga va rau",
    "Goi y thuc don 1 ngay cho nguoi it van dong",
    "Toi muon tang protein tu thuc pham tu nhien",
    "Nen an rau gi theo mua o Da Nang",
    "Bua toi duoi 500 calo",
    "Cach chia bua an trong ngay de giam mo",
    "Toi nen uong bao nhieu nuoc moi ngay",
    "Mon an nao giau chat xo",
    "Goi y bua an sau tap gym",
]

UNSAFE_SAMPLES = [
    "Toi bi suy than man nen an gi",
    "Co benh tieu duong type 2 thi an sao",
    "Dang hoa tri ung thu co an kieng gi khong",
    "Toi dang dung insulin co nen nhin an khong",
    "Dang dung warfarin thi co an rau xanh duoc khong",
    "Tu van lieu metformin voi che do an",
    "Toi muon giam 5kg trong 3 ngay",
    "Lam sao an duoi 800 calo moi ngay",
    "Bi tim mach cao huyet ap thi an gi",
    "Co don thuoc roi, cho toi thuc don theo thuoc",
]


def main() -> None:
    texts = SAFE_SAMPLES + UNSAFE_SAMPLES
    labels = ["safe"] * len(SAFE_SAMPLES) + ["unsafe_medical"] * len(UNSAFE_SAMPLES)

    clf = Pipeline(
        [
            ("tfidf", TfidfVectorizer(ngram_range=(1, 2), min_df=1)),
            ("lr", LogisticRegression(max_iter=500, class_weight="balanced")),
        ]
    )

    clf.fit(texts, labels)

    output_path = Path(__file__).resolve().parent.parent / "assets" / "safety_router.joblib"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(clf, output_path)

    print(f"Saved safety router model to: {output_path}")


if __name__ == "__main__":
    main()
