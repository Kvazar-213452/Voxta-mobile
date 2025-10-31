import json
import asyncio

DATA_CONFIG = None

async def load_config():
    global DATA_CONFIG
    try:
        with open("config.json", "r", encoding="utf-8") as f:
            DATA_CONFIG = json.load(f)
        print("Config loaded successfully")
    except Exception as e:
        print("Error loading config:", e)
        raise e

def get_config():
    if DATA_CONFIG is None:
        raise Exception("Config not loaded yet. Call load_config() first.")
    return DATA_CONFIG
