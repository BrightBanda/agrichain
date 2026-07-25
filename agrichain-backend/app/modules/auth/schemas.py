import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, model_validator
from app.modules.farmers.models import UserRole, Gender


class FarmerRegisterRequest(BaseModel):
    # Personal Details
    full_name: str = Field(..., example="Kondwani Banda")
    national_id_number: str = Field(..., example="MW12345678ABCD")
    gender: Gender = Field(..., example=Gender.MALE)

    # Location
    district: str = Field(..., example="Lilongwe")
    traditional_authority: str = Field(..., example="T/A Kalolo")
    village: str = Field(..., example="Msinja Village")

    # Optional Document URLs (or paths after upload service handles them)
    profile_photo_url: Optional[str] = Field(
        None, example="https://storage.agrichain.mw/profiles/photo1.jpg"
    )
    id_front_photo_url: Optional[str] = Field(
        None, example="https://storage.agrichain.mw/kyc/id_front.jpg"
    )
    id_back_photo_url: Optional[str] = Field(
        None, example="https://storage.agrichain.mw/kyc/id_back.jpg"
    )

    # Authentication Credentials
    phone_number: str = Field(..., example="+265999123456")
    password: str = Field(..., min_length=6, example="Password123!")
    confirm_password: str = Field(..., example="Password123!")

    @model_validator(mode="after")
    def verify_password_match(self):
        if self.password != self.confirm_password:
            raise ValueError("Password and confirm_password do not match.")
        return self


class FarmerProfileResponse(BaseModel):
    id: uuid.UUID
    full_name: str
    national_id_number: str
    gender: Gender
    district: str
    traditional_authority: str
    village: str
    profile_photo_url: Optional[str]
    id_front_photo_url: Optional[str]
    id_back_photo_url: Optional[str]
    lending_score: int

    class Config:
        from_attributes = True


class UserRegisterResponse(BaseModel):
    id: uuid.UUID
    phone_number: str
    role: UserRole
    is_verified: bool
    created_at: datetime
    farmer_profile: Optional[FarmerProfileResponse] = None

    class Config:
        from_attributes = True


class UserListResponse(BaseModel):
    users: list[UserRegisterResponse]
    total: int


class LoginRequest(BaseModel):
    phone_number: str = Field(..., example="+265999123456")
    password: str = Field(..., min_length=6, example="Password123!")


class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserRegisterResponse
