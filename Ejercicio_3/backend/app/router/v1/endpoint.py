from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter()

class SampleModel(BaseModel):
    id: int
    name: str

@router.post('/sample/')
async def create_sample(sample: SampleModel):
    return {"message": "Sample created", "sample": sample}
@router.get('/sample/{sample_id}')
async def get_sample(sample_id: int):
    return {"message": "Sample retrieved", "sample_id": sample_id}

