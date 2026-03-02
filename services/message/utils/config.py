import os
import requests
from dotenv import load_dotenv

load_dotenv()

CONFIG = None
CONFIG_MAIN = None
CONFIG_DB = None
CONFIG_API = None

def load_config(name: str = None):
    global CONFIG_MAIN, CONFIG_DB, CONFIG_API

    if name is None:
        name = os.getenv("NAME", "")

    try:
        response = requests.post(
            f"{os.getenv('API_MAIN')}api/get_config",
            json={"name": name},
            headers={"Content-Type": "application/json"}
        )
        response.raise_for_status()
        data = response.json()

        if data.get("status") != 1:
            raise ValueError("Failed to load config: invalid status")

        if name == "GLOBAL_DB":
            CONFIG_DB = data.get("config")
        elif name == "GLOBAL_URL":
            CONFIG_API = data.get("config")
        else:
            CONFIG_MAIN = data.get("config")

    except Exception as e:
        print(f"Error loading config for {name}: {e}")
        raise e
    
def GET_CONFIG():
    return CONFIG


def rebuild_config():
    global CONFIG
    CONFIG = {**(CONFIG_MAIN or {}), **(CONFIG_DB or {}), **(CONFIG_API or {})}