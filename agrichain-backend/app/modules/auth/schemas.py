import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, model_validator
from app.modules.farmers.models import UserRole, Gender
from app.modules.products.models import SUPPLY_TYPES, ProductType


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


class SupplierProfileResponse(BaseModel):
    id: uuid.UUID
    business_name: str
    district: Optional[str]
    description: Optional[str]
    services: list[str]

    class Config:
        from_attributes = True


class UserRegisterResponse(BaseModel):
    id: uuid.UUID
    phone_number: str
    display_name: Optional[str] = None
    role: UserRole
    is_verified: bool
    created_at: datetime
    farmer_profile: Optional[FarmerProfileResponse] = None
    supplier_profile: Optional[SupplierProfileResponse] = None

    class Config:
        from_attributes = True


# Roles that register as an organisation rather than an individual farmer.
ORGANIZATION_ROLES = {
    UserRole.FINANCIAL_INSTITUTION,
    UserRole.SUPPLIER,
    UserRole.PRODUCE_BUYER,
    UserRole.COOPERATIVE,
}


class OrganizationRegisterRequest(BaseModel):
    """FR-01: a non-farmer account (institution, supplier, buyer, cooperative).

    Organisations have no KYC profile of their own in this MVP; an administrator
    would verify them out of band before is_verified is set. ADMIN is
    deliberately not registerable through the public API.
    """

    display_name: str = Field(..., example="National Bank")
    role: UserRole = Field(
        UserRole.FINANCIAL_INSTITUTION, example=UserRole.FINANCIAL_INSTITUTION
    )
    phone_number: str = Field(..., example="+265888100200")
    email: Optional[str] = Field(None, example="agri@nbs.mw")
    password: str = Field(..., min_length=6, example="Password123!")
    confirm_password: str = Field(..., example="Password123!")

    # Service providers declare what they supply; this becomes the set of
    # categories they are allowed to list (FR-11).
    services: Optional[list[ProductType]] = Field(
        None, example=[ProductType.SEEDS, ProductType.FERTILIZER]
    )
    district: Optional[str] = Field(None, example="Lilongwe")
    description: Optional[str] = Field(
        None, example="Certified seed and fertilizer supplier since 2014."
    )

    @model_validator(mode="after")
    def verify_request(self):
        if self.password != self.confirm_password:
            raise ValueError("Password and confirm_password do not match.")
        if self.role not in ORGANIZATION_ROLES:
            allowed = ", ".join(sorted(role.value for role in ORGANIZATION_ROLES))
            raise ValueError(
                f"role must be one of: {allowed}. Farmers register at "
                f"/auth/register/farmer."
            )

        if self.role is UserRole.SUPPLIER:
            if not self.services:
                allowed = ", ".join(sorted(t.value for t in SUPPLY_TYPES))
                raise ValueError(
                    f"A service provider must choose at least one service. "
                    f"Options: {allowed}."
                )
            invalid = [t.value for t in self.services if t not in SUPPLY_TYPES]
            if invalid:
                allowed = ", ".join(sorted(t.value for t in SUPPLY_TYPES))
                raise ValueError(
                    f"{', '.join(invalid)} cannot be offered as a service. "
                    f"Options: {allowed}."
                )
        elif self.services:
            raise ValueError("Only service providers declare services.")

        return self


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
