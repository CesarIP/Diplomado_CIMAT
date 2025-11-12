from pydantic import BaseModel
from typing import Optional, List

class SampleSchema(BaseModel):
    id: int
    name: str
    description: Optional[str] = None

class SampleListSchema(BaseModel):
    items: List[SampleSchema]

    
