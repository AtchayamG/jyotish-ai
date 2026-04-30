"""schemas/user_schema.py"""
from typing import Optional
from pydantic import BaseModel, EmailStr, Field


class UserBase(BaseModel):
    email: EmailStr
    full_name: str = Field(..., min_length=2, max_length=100)
    phone: Optional[str] = None


class UserCreate(UserBase):
    password: str = Field(..., min_length=8)
    # Birth details collected at registration
    date_of_birth: Optional[str] = None      # "YYYY-MM-DD"
    time_of_birth: Optional[str] = None      # "HH:MM"
    place_of_birth: Optional[str] = None     # "Chennai, Tamil Nadu, India"
    birth_latitude: Optional[float] = None
    birth_longitude: Optional[float] = None
    birth_timezone: Optional[float] = None   # UTC offset e.g. 5.5 for IST


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
    # Birth details
    date_of_birth: Optional[str] = None
    time_of_birth: Optional[str] = None
    place_of_birth: Optional[str] = None
    birth_latitude: Optional[float] = None
    birth_longitude: Optional[float] = None
    birth_timezone: Optional[float] = None
    moon_sign: Optional[str] = None          # Vedic moon sign (rashi), cached after first kundli
    model_config = {"from_attributes": True}


class UserPublic(UserBase):
    id: str
    is_premium: bool
    is_admin: bool = False
    created_at: str
    # Birth details returned to client
    date_of_birth: Optional[str] = None
    time_of_birth: Optional[str] = None
    place_of_birth: Optional[str] = None
    birth_latitude: Optional[float] = None
    birth_longitude: Optional[float] = None
    birth_timezone: Optional[float] = None
    moon_sign: Optional[str] = None


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserPublic


class RefreshRequest(BaseModel):
    refresh_token: str


class UpdateFCMToken(BaseModel):
    fcm_token: str


class UpdateProfileRequest(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    date_of_birth: Optional[str] = None
    time_of_birth: Optional[str] = None
    place_of_birth: Optional[str] = None
    birth_latitude: Optional[float] = None
    birth_longitude: Optional[float] = None
    birth_timezone: Optional[float] = None
