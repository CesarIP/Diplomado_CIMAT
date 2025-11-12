from pydantic import BaseModel

class SampleModel(BaseModel):
    id: int
    name: str
    description: str | None = None

    class Config:
        orm_mode = True
