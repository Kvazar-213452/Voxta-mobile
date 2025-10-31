from fastapi import APIRouter
from controllers.config_controller import ConfigController

api_routes = APIRouter()

api_routes.post("/get_config")(ConfigController.config_give)
