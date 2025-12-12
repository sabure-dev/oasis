from typing import Annotated

from fastapi import APIRouter, Depends

from core.dependencies import get_current_user_id
from users.dependencies import get_user_service
from users.schemas import UserRegister, UserLogin, TokenResponse, RefreshTokenRequest
from users.service import UserService

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/register", response_model=TokenResponse)
async def register(
        user_data: UserRegister,
        service: Annotated[UserService, Depends(get_user_service)]
):
    return await service.register(
        user_data.username,
        user_data.email,
        user_data.password
    )


@router.post("/login", response_model=TokenResponse)
async def login(
        credentials: UserLogin,
        service: Annotated[UserService, Depends(get_user_service)]
):
    return await service.login(credentials.email, credentials.password)


@router.post("/refresh", response_model=TokenResponse)
async def refresh_tokens(
        request: RefreshTokenRequest,
        service: Annotated[UserService, Depends(get_user_service)]
):
    return await service.refresh_tokens(
        request.refresh_token,
        request.password
    )


@router.post("/logout")
async def logout(
        user_id: Annotated[int, Depends(get_current_user_id)],
        service: Annotated[UserService, Depends(get_user_service)]
):
    await service.logout(user_id)
    return {"message": "Logged out successfully"}
