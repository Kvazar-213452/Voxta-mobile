from pydantic import BaseModel

class GetUserById(BaseModel):
    id: str
