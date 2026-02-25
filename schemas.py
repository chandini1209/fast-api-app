from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime

class ItemBase(BaseModel):
    title: str
    description: Optional[str] = None
    is_active: bool = True

class ItemCreate(ItemBase):
    pass

class ItemUpdate(BaseModel):
    # All fields are optional for updates
    title: Optional[str] = None
    description: Optional[str] = None
    is_active: Optional[bool] = None

class Item(ItemBase):
    id: int
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)
