"""schemas/user_schema.py"""
from typing import Optional
from pydantic import BaseModel, EmailStr, Field

class UserBase(BaseModel):
    email: EmailStr
    full_name: str = Field(..., min_length=2, max_length=100)
    phone: Optional[str] = None

class UserCreate(UserBase):
    password: str = Field(..., min_length=8)

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserInDB(UserBase):
    id: str
    is_active: bool = True
    is_premium: bool = False
    is_admin: bool = False
    created_at: str = ""
    updated_at: str = ""
    hashed_password: str = ""
    fcm_token: Optional[str] = None
    google_uid: Optional[str] = None
    model_config = {"from_attributes": True}

class UserPublic(UserBase):
    id: str
    is_premium: bool
    is_admin: bool = False
    created_at: str

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserPublic

class RefreshRequest(BaseModel):
    refresh_token: str

class UpdateFCMToken(BaseModel):
    fcm_token: str
