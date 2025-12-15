from typing import Annotated

from fastapi import APIRouter, Depends, BackgroundTasks, status

from core.dependencies import get_current_user_id
from users.dependencies import get_user_service, get_current_user
from users.models import User
from users.schemas import UserRegister, UserLogin, TokenResponse, RefreshTokenRequest, UserRead, VerificationRequest, \
    ForgotPasswordRequest, ResetPasswordRequest
from users.service import UserService

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(
        background_tasks: BackgroundTasks,
        user_data: UserRegister,
        service: Annotated[UserService, Depends(get_user_service)]
):
    return await service.register(
        user_data.username,
        user_data.email,
        user_data.password,
        background_tasks
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
    )


@router.post("/logout")
async def logout(
        user_id: Annotated[int, Depends(get_current_user_id)],
        service: Annotated[UserService, Depends(get_user_service)]
):
    await service.logout(user_id)
    return {"message": "Logged out successfully"}


@router.get("/me", response_model=UserRead)
async def read_users_me(
        current_user: Annotated[User, Depends(get_current_user)]
):
    return current_user


@router.post("/verify/request")
async def request_verification_code(
        background_tasks: BackgroundTasks,
        current_user: Annotated[User, Depends(get_current_user)],
        service: Annotated[UserService, Depends(get_user_service)]
):
    return await service.request_verification(current_user.id, background_tasks)


@router.post("/verify/confirm")
async def confirm_email(
        data: VerificationRequest,
        current_user: Annotated[User, Depends(get_current_user)],
        service: Annotated[UserService, Depends(get_user_service)]
):
    return await service.verify_email(current_user.id, data.code)


@router.post("/forgot-password")
async def forgot_password(
        data: ForgotPasswordRequest,
        background_tasks: BackgroundTasks,
        service: Annotated[UserService, Depends(get_user_service)]
):
    return await service.forgot_password(data.email, background_tasks)


@router.post("/reset-password")
async def reset_password(
        data: ResetPasswordRequest,
        service: Annotated[UserService, Depends(get_user_service)]
):
    return await service.reset_password(data.email, data.code, data.new_password)
