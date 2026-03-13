from pydantic import BaseModel, Field
from typing import Optional


class UserProfile(BaseModel):
    """
    Schema đại diện cho hồ sơ người dùng EcoNutri
    """

    user_id: Optional[int] = None

    name: str = Field(..., description="User full name")

    age: int = Field(..., ge=0, le=120)

    gender: str = Field(..., description="male / female / other")

    height_cm: float = Field(..., gt=0)

    weight_kg: float = Field(..., gt=0)

    body_fat_percent: Optional[float] = Field(None, ge=0, le=100)

    activity_level: str = Field(
        ..., description="low / medium / high"
    )

    location: Optional[str] = Field(
        None, description="User region or city"
    )

    season: Optional[str] = Field(
        None, description="Current season"
    )

    bmr: Optional[float] = None

    tdee: Optional[float] = None