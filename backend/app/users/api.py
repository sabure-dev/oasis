from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status

from users.schemas import UserRegister, UserLogin, TokenResponse, RefreshTokenRequest
from users.service import UserService
from users.dependencies import get_user_service
from core.dependencies import get_current_user_id

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/register", response_model=TokenResponse)
async def register(
        user_data: UserRegister,
        service: Annotated[UserService, Depends(get_user_service)]
):
    try:
        return await service.register(
            user_data.username,
            user_data.email,
            user_data.password
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Registration failed: {str(e)}"
        )


@router.post("/login", response_model=TokenResponse)
async def login(
        credentials: UserLogin,
        service: Annotated[UserService, Depends(get_user_service)]
):
    try:
        return await service.login(credentials.email, credentials.password)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Login failed: {str(e)}"
        )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_tokens(
    request: RefreshTokenRequest,
    service: Annotated[UserService, Depends(get_user_service)]
):
    try:
        return await service.refresh_tokens(
            request.refresh_token,
            request.password
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Token refresh failed: {str(e)}"
        )


@router.post("/logout")
async def logout(
        user_id: Annotated[int, Depends(get_current_user_id)],
        service: Annotated[UserService, Depends(get_user_service)]
):
    await service.logout(user_id)
    return {"message": "Logged out successfully"}
