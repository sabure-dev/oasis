from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse

from core.exceptions import (
    UserAlreadyExists,
    InvalidCredentials,
    TokenExpired,
    InvalidToken, UpstreamServiceError, UserNotFound
)


async def user_exists_handler(request: Request, exc: UserAlreadyExists) -> JSONResponse:
    return JSONResponse(
        status_code=status.HTTP_409_CONFLICT,
        content={"detail": str(exc) or "User with this email or username already exists"}
    )


async def user_not_found_handler(request: Request, exc: UserNotFound) -> JSONResponse:
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content={"detail": str(exc) or "User not found"}
    )


async def invalid_auth_handler(request: Request, exc: InvalidCredentials) -> JSONResponse:
    return JSONResponse(
        status_code=status.HTTP_401_UNAUTHORIZED,
        content={"detail": str(exc) or "Incorrect email or password"}
    )


async def token_expired_handler(request: Request, exc: TokenExpired) -> JSONResponse:
    return JSONResponse(
        status_code=status.HTTP_401_UNAUTHORIZED,
        content={"detail": str(exc) or "Token expired"}
    )


async def invalid_token_handler(request: Request, exc: InvalidToken) -> JSONResponse:
    return JSONResponse(
        status_code=status.HTTP_401_UNAUTHORIZED,
        content={"detail": str(exc) or "Invalid token"}
    )


async def value_error_handler(request: Request, exc: ValueError) -> JSONResponse:
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content={"detail": str(exc)}
    )


async def global_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    print(f"Global error: {exc}")
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Internal Server Error"}
    )


async def upstream_error_handler(request: Request, exc: UpstreamServiceError) -> JSONResponse:
    return JSONResponse(
        status_code=status.HTTP_502_BAD_GATEWAY,
        content={"detail": str(exc) or "Upstream service unavailable"}
    )


def register_exception_handlers(app: FastAPI):
    app.add_exception_handler(UpstreamServiceError, upstream_error_handler)
    app.add_exception_handler(UserNotFound, user_not_found_handler)
    app.add_exception_handler(UserAlreadyExists, user_exists_handler)
    app.add_exception_handler(InvalidCredentials, invalid_auth_handler)
    app.add_exception_handler(TokenExpired, token_expired_handler)
    app.add_exception_handler(InvalidToken, invalid_token_handler)
    app.add_exception_handler(ValueError, value_error_handler)
    app.add_exception_handler(Exception, global_exception_handler)
