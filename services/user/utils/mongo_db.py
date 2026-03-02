from fastapi import HTTPException
from pymongo import MongoClient
from pymongo.errors import PyMongoError

DB_URL = "mongodb://localhost:27017/messenger"

try:
    client = MongoClient(DB_URL)
except PyMongoError as e:
    raise HTTPException(status_code=500, detail=f"DB connection error: {str(e)}")

def get_connection():
    try:
        return client
    except PyMongoError as e:
        raise HTTPException(status_code=500, detail=f"DB access error: {str(e)}")