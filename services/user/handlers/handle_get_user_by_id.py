from fastapi import HTTPException
from models import GetUserById
from utils.mongo_db import get_connection

async def handle_get_user_by_id(data: GetUserById):
    user_id = data.id.strip() if data.id else None

    if not user_id:
        raise HTTPException(status_code=400, detail="ID is required")

    client = get_connection()
    db = client.users

    try:
        user = db.users.find_one({"_id": user_id})

        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        config = db[user_id].find_one({"_id": "config"})

        if not config:
            raise HTTPException(status_code=404, detail="Config not found")

    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail=f"DB error: {str(e)}")

    return config