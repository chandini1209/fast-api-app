# schemas.py
from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime


class ItemCreate(BaseModel):
    title: str
    description: Optional[str] = None
    is_active: bool = True


class Item(ItemCreate):
    id: int
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)