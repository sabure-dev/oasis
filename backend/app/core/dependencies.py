from typing import Annotated

from fastapi import Depends
from fastapi.security import HTTPBearer

from core.exceptions import InvalidToken
from core.security import decode_token

security = HTTPBearer()


async def get_current_user_id(
        credentials: Annotated[str, Depends(security)]
) -> int:
    token = credentials.credentials
    payload = decode_token(token)

    if not payload:
        raise InvalidToken("Invalid token")

    user_id = payload.get("sub")
    if not user_id:
        raise InvalidToken("Invalid token payload")

    return int(user_id)
