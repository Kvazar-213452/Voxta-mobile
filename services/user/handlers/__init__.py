from .handle_get_user_by_id import handle_get_user_by_id

class UserHandler:
    get_user_by_id = staticmethod(handle_get_user_by_id)