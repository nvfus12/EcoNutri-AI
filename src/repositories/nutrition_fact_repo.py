import json
import re
import unicodedata
from pathlib import Path
from typing import Any, Dict, List

import pandas as pd


class NutritionFactRepository:
    """Tra cứu số liệu dinh dưỡng có cấu trúc (CSV/JSON) để chống hallucination."""

    def __init__(self, data_dir: str = "data/knowledges"):
        self.data_dir = Path(data_dir)
        self.df = self._load_sources()

    @staticmethod
    def _normalize(text: str) -> str:
        if not text:
            return ""
        text = unicodedata.normalize("NFD", str(text).lower())
        text = "".join(ch for ch in text if unicodedata.category(ch) != "Mn")
        text = re.sub(r"\s+", " ", text).strip()
        return text

    def _load_sources(self) -> pd.DataFrame:
        if not self.data_dir.exists():
            return pd.DataFrame()

        frames: List[pd.DataFrame] = []
        for file in self.data_dir.iterdir():
            name = file.name.lower()
            if not any(k in name for k in ["nutrition", "food", "nin", "usda", "thanh_phan", "thanh-phan"]):
                continue

            try:
                if file.suffix.lower() == ".csv":
                    frames.append(pd.read_csv(file))
                elif file.suffix.lower() == ".json":
                    with open(file, "r", encoding="utf-8") as f:
                        data = json.load(f)
                    if isinstance(data, list):
                        frames.append(pd.DataFrame(data))
                    elif isinstance(data, dict) and isinstance(data.get("data"), list):
                        frames.append(pd.DataFrame(data["data"]))
            except Exception:
                continue

        if not frames:
            return pd.DataFrame()

        df = pd.concat(frames, ignore_index=True)
        if "food_name" not in df.columns:
            for alt in ["name", "food", "dish_name", "ten_mon", "ten_thuc_pham"]:
                if alt in df.columns:
                    df = df.rename(columns={alt: "food_name"})
                    break

        if "food_name" not in df.columns:
            return pd.DataFrame()

        # Chuẩn hóa tên cột phổ biến
        renames = {
            "kcal": "calories",
            "energy": "calories",
            "carbohydrate": "carb",
            "carbs": "carb",
            "lipid": "fat",
        }
        for old, new in renames.items():
            if old in df.columns and new not in df.columns:
                df = df.rename(columns={old: new})

        df = df.fillna("")
        df["food_name_norm"] = df["food_name"].astype(str).map(self._normalize)
        return df

    def search_by_query(self, query: str, limit: int = 5) -> List[Dict[str, Any]]:
        if self.df.empty:
            return []

        qn = self._normalize(query)
        if not qn:
            return []

        # Match theo tên món/thực phẩm có trong query
        mask = self.df["food_name_norm"].map(lambda x: x in qn or qn in x)
        matched = self.df[mask].head(limit)

        if matched.empty:
            # fallback theo token dài >= 4 ký tự
            tokens = [tok for tok in qn.split() if len(tok) >= 4]
            if not tokens:
                return []
            token_mask = self.df["food_name_norm"].map(lambda x: any(tok in x for tok in tokens))
            matched = self.df[token_mask].head(limit)

        cols = [c for c in ["food_name", "calories", "protein", "carb", "fat", "fiber", "source"] if c in matched.columns]
        return matched[cols].to_dict(orient="records")
