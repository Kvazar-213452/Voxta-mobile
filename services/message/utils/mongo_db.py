from fastapi import HTTPException
from pymongo import MongoClient
from pymongo.errors import PyMongoError
from utils.config import GET_CONFIG

client = None

def get_connection():
    global client
    if client is None:
        try:
            config = GET_CONFIG()
            client = MongoClient(config.get("DB_MONGODB_URI", "mongodb://localhost:27017"))
        except PyMongoError as e:
            raise HTTPException(status_code=500, detail=f"DB connection error: {str(e)}")
    return client