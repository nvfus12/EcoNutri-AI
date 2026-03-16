import re
import unicodedata
from typing import Optional, Tuple


def normalize_for_intent(text: str) -> str:
    if not text:
        return ""
    text = unicodedata.normalize("NFD", text.lower())
    return "".join(ch for ch in text if unicodedata.category(ch) != "Mn")


def extract_weight_goal_kg(query: str) -> Tuple[Optional[float], Optional[float]]:
    if not query:
        return None, None

    text = normalize_for_intent(query).replace(",", ".")
    patterns = [
        r"\btu\s*(\d+(?:\.\d+)?)\s*(?:kg|kilo|can)?\s*(?:xuong|ve|->|to)\s*(\d+(?:\.\d+)?)\s*(?:kg|kilo|can)?\b",
        r"\b(\d+(?:\.\d+)?)\s*(?:kg|kilo|can)\s*(?:xuong|ve|->|to)\s*(\d+(?:\.\d+)?)\s*(?:kg|kilo|can)\b",
    ]

    for pattern in patterns:
        match = re.search(pattern, text)
        if match:
            return float(match.group(1)), float(match.group(2))

    return None, None


def should_trigger_weekly_plan(query: str) -> bool:
    intent_text = normalize_for_intent(query)
    has_plan_intent = bool(re.search(r"\b(ke\s*hoach|lap\s*ke\s*hoach|plan|lo\s*trinh)\b", intent_text))
    has_weight_loss_intent = bool(re.search(r"\b(giam\s*can|giam\s*mo)\b", intent_text))
    has_week_month_horizon = bool(
        re.search(r"\b(tuan|theo\s*tuan|tung\s*tuan|4\s*tuan|thang|1\s*thang|mot\s*thang|month|week)\b", intent_text)
    )

    start_w, target_w = extract_weight_goal_kg(query)
    has_explicit_weight_goal = (
        start_w is not None and target_w is not None and start_w > target_w
    )

    return has_weight_loss_intent and (
        has_explicit_weight_goal or (has_week_month_horizon and has_plan_intent)
    )


def get_intro_reply(query: str) -> Optional[str]:
    text = normalize_for_intent(query)
    if not text:
        return None
    if re.search(r"\b(xin\s*chao|chao|hello|hi|hey)\b", text) and re.search(r"\b(ban\s*la\s*ai|ban\s*giup\s*gi|ban\s*lam\s*duoc\s*gi)\b", text):
        return "Xin chao! Minh la EcoNutri AI. Minh giup ban lap ke hoach dinh duong, goi y bua an va theo doi muc tieu can nang."
    if re.search(r"\b(ban\s*la\s*ai|ban\s*giup\s*gi|ban\s*lam\s*duoc\s*gi)\b", text):
        return "Minh la EcoNutri AI, tro ly dinh duong ca nhan hoa. Minh co the goi y bua an, lap ke hoach theo tuan va phan tich muc tieu can nang cho ban."
    return None


def sanitize_output(text: str) -> str:
    if not text:
        return ""
    # Strip Chinese chars
    cleaned = re.sub(r"[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF]", "", text)
    # Collapse excessive spaces/newlines
    cleaned = re.sub(r"\s{2,}", " ", cleaned)
    cleaned = re.sub(r"\n{3,}", "\n\n", cleaned)
    return cleaned.strip()
