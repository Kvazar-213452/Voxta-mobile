from fastapi import APIRouter
from models import GetUserById
from handlers import UserHandler

main_router = APIRouter()

@main_router.post("/get_user_by_id")
async def register(data: GetUserById):
    return await UserHandler.get_user_by_id(data)