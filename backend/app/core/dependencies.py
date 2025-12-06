from typing import Annotated
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer

from core.security import decode_token

security = HTTPBearer()


async def get_current_user_id(
    credentials: Annotated[str, Depends(security)]
) -> int:
    token = credentials.credentials
    payload = decode_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )
    
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload"
        )
    return user_id
