from pydantic import BaseModel, EmailStr, field_validator


class UserRegister(BaseModel):
    username: str
    email: EmailStr
    password: str

    @field_validator('username')
    @classmethod
    def validate_username(cls, v: str) -> str:
        if len(v) < 3:
            raise ValueError('Username must be at least 3 characters')
        if len(v) > 50:
            raise ValueError('Username must be at most 50 characters')
        if not v.replace('_', '').replace('-', '').isalnum():
            raise ValueError('Username can only contain letters, numbers, _ and -')
        return v


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class UserRead(BaseModel):
    id: int
    username: str
    email: EmailStr
    is_active: bool
    is_verified: bool

    class Config:
        from_attributes = True


class VerificationRequest(BaseModel):
    code: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str | None = None
    token_type: str = "bearer"


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    code: str
    new_password: str
