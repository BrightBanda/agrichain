"""Populate the ledger with one full AgriChain story, for demos.

Walks the whole value proposition against a running server:

    farmer registered -> harvest recorded -> harvest verified
    -> produce listed -> loan approved -> repaid in full -> score updated
    -> second loan approved -> part paid

Every step anchors a block, so afterwards the app's Ledger Explorer has a
complete chain to show, and the home screen has both a completed loan and a
live one with a balance outstanding.

    python seed_demo.py           # create the demo data
    python seed_demo.py --clean   # remove it again

The accounts it creates all use the password below, so you can sign in as any of
them from the app.
"""

import asyncio
import os
import sys

import asyncpg
import httpx

from app.core.config import settings

# Where to seed. Defaults to a local server; point it at a deployment with:
#   AGRICHAIN_API=https://agrichain-api.onrender.com python seed_demo.py
# The database URL must match that API's database, so override DATABASE_URL too.
HOST = os.environ.get("AGRICHAIN_API", "http://127.0.0.1:8000").rstrip("/")
BASE = f"{HOST}/api/v1"
# Credentials come from .env; nothing sensitive is hardcoded in this file.
DB = settings.sync_database_url
PASSWORD = settings.DEMO_ACCOUNT_PASSWORD

FARMER_PHONE = "+265991000001"
COOP_PHONE = "+265991000002"
BANK_PHONE = "+265991000003"
# Two extra accounts backing the in-app demo picker: a farmer with no
# activity (score stays at the 300 floor, so most loans are out of reach)
# and a service provider.
NEW_FARMER_PHONE = "+265991000004"
SUPPLIER_PHONE = "+265991000005"
DEMO_PHONES = [
    FARMER_PHONE,
    COOP_PHONE,
    BANK_PHONE,
    NEW_FARMER_PHONE,
    SUPPLIER_PHONE,
]

DEMO_NATIONAL_ID = "DEMO00000001"
NEW_FARMER_NATIONAL_ID = "DEMO00000002"
DEMO_PRODUCT_NAME = "Demo Dry White Maize"
DEMO_REFERENCE = "DEMO-MM-000001"
DEMO_REFERENCE_PARTIAL = "DEMO-MM-000002"


async def _login(client: httpx.AsyncClient, phone: str) -> str:
    response = await client.post(
        f"{BASE}/auth/login", json={"phone_number": phone, "password": PASSWORD}
    )
    response.raise_for_status()
    return response.json()["access_token"]


def _auth(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


async def seed() -> None:
    async with httpx.AsyncClient(timeout=60) as client:
        print(f"seeding {HOST}")
        try:
            # A cold-started free instance can take a while to answer the first
            # request, so this waits rather than failing immediately.
            await client.get(f"{HOST}/health", timeout=90)
        except httpx.HTTPError as error:
            sys.exit(f"Cannot reach {HOST}: {error}")

        print("1/7  registering accounts")
        farmer = await client.post(
            f"{BASE}/auth/register/farmer",
            json={
                "full_name": "Kondwani Banda",
                "national_id_number": DEMO_NATIONAL_ID,
                "gender": "MALE",
                "district": "Lilongwe",
                "traditional_authority": "T/A Kalolo",
                "village": "Msinja Village",
                "phone_number": FARMER_PHONE,
                "password": PASSWORD,
                "confirm_password": PASSWORD,
            },
        )
        if farmer.status_code == 400:
            sys.exit(
                "The demo data already exists. Run `python seed_demo.py --clean` "
                "first."
            )
        farmer.raise_for_status()

        for display_name, role, phone in (
            ("Kalolo Farmers Cooperative", "COOPERATIVE", COOP_PHONE),
            ("National Bank", "FINANCIAL_INSTITUTION", BANK_PHONE),
        ):
            response = await client.post(
                f"{BASE}/auth/register/organization",
                json={
                    "display_name": display_name,
                    "role": role,
                    "phone_number": phone,
                    "password": PASSWORD,
                    "confirm_password": PASSWORD,
                },
            )
            response.raise_for_status()

        # A farmer with nothing recorded: demonstrates the "not yet eligible"
        # path, since a 300 score fails most products' minimum.
        response = await client.post(
            f"{BASE}/auth/register/farmer",
            json={
                "full_name": "Tadala Phiri",
                "national_id_number": NEW_FARMER_NATIONAL_ID,
                "gender": "OTHER",
                "district": "Lilongwe",
                "traditional_authority": "T/A Kalolo",
                "village": "Not yet provided",
                "phone_number": NEW_FARMER_PHONE,
                "password": PASSWORD,
                "confirm_password": PASSWORD,
            },
        )
        response.raise_for_status()

        response = await client.post(
            f"{BASE}/auth/register/organization",
            json={
                "display_name": "Farmers World Malawi",
                "role": "SUPPLIER",
                "phone_number": SUPPLIER_PHONE,
                "password": PASSWORD,
                "confirm_password": PASSWORD,
                "district": "Lilongwe",
                "description": "Certified seed and fertilizer supplier.",
                "services": ["SEEDS", "FERTILIZER"],
            },
        )
        response.raise_for_status()

        farmer_token = await _login(client, FARMER_PHONE)
        coop_token = await _login(client, COOP_PHONE)
        bank_token = await _login(client, BANK_PHONE)

        print("2/7  recording a harvest")
        response = await client.post(
            f"{BASE}/harvests",
            headers=_auth(farmer_token),
            json={
                "crop_name": "Dry White Hybrid Maize",
                "quantity": 120,
                "unit_type": "BAG_50KG",
                "harvest_date": "2026-05-14",
                "season": "2025/2026",
                "district": "Lilongwe",
            },
        )
        response.raise_for_status()
        harvest_id = response.json()["harvest"]["id"]

        print("3/7  cooperative verifying the harvest")
        response = await client.post(
            f"{BASE}/harvests/{harvest_id}/verify",
            headers=_auth(coop_token),
            json={"approve": True, "note": "Confirmed against cooperative records."},
        )
        response.raise_for_status()

        print("4/7  listing produce for sale")
        response = await client.post(
            f"{BASE}/products",
            headers=_auth(farmer_token),
            json={
                "product_type": "CROPS_PRODUCE",
                "product_name": DEMO_PRODUCT_NAME,
                "unit_type": "BAG_50KG",
                "district": "Lilongwe",
                "price_per_unit": 45000,
                "quantity_available": 100,
                "description": "Verified farm produce, direct from the farm.",
            },
        )
        response.raise_for_status()

        print("5/7  institution publishing a loan product")
        response = await client.post(
            f"{BASE}/loan-products",
            headers=_auth(bank_token),
            json={
                "name": "Seasonal Input Loan",
                "loan_type": "INPUT_FINANCING",
                "max_amount": 500000,
                "interest_rate": 18.5,
                "repayment_period_months": 9,
                "min_lending_score": 310,
                "description": "Finance seed and fertilizer for the season.",
            },
        )
        response.raise_for_status()
        loan_product_id = response.json()["id"]

        print("6/7  applying for and approving a loan")
        response = await client.post(
            f"{BASE}/loans/apply",
            headers=_auth(farmer_token),
            json={"loan_product_id": loan_product_id, "amount_requested": 200000},
        )
        response.raise_for_status()
        loan_id = response.json()["id"]

        response = await client.post(
            f"{BASE}/loans/{loan_id}/decision",
            headers=_auth(bank_token),
            json={
                "approve": True,
                "amount_approved": 200000,
                "note": "Approved on verified harvest history.",
            },
        )
        response.raise_for_status()
        total_payable = response.json()["total_payable"]

        print("7/7  repaying the loan in full")
        response = await client.post(
            f"{BASE}/loans/{loan_id}/repayments",
            headers=_auth(farmer_token),
            json={
                "amount": total_payable,
                "method": "MOBILE_MONEY",
                "transaction_reference": DEMO_REFERENCE,
            },
        )
        response.raise_for_status()
        result = response.json()

        # A second loan, left part-paid, so the home screen has a live active
        # loan to show alongside the completed one.
        print("8/9  taking a second loan for the current season")
        response = await client.post(
            f"{BASE}/loans/apply",
            headers=_auth(farmer_token),
            json={"loan_product_id": loan_product_id, "amount_requested": 200000},
        )
        response.raise_for_status()
        second_loan_id = response.json()["id"]

        response = await client.post(
            f"{BASE}/loans/{second_loan_id}/decision",
            headers=_auth(bank_token),
            json={
                "approve": True,
                "amount_approved": 200000,
                "note": "Approved on improved score after full repayment.",
            },
        )
        response.raise_for_status()

        print("9/9  making a part payment on it")
        response = await client.post(
            f"{BASE}/loans/{second_loan_id}/repayments",
            headers=_auth(farmer_token),
            json={
                "amount": 52000,
                "method": "MOBILE_MONEY",
                "transaction_reference": DEMO_REFERENCE_PARTIAL,
            },
        )
        response.raise_for_status()
        result = response.json()

        stats = (await client.get(f"{BASE}/blockchain/chain/stats")).json()
        integrity = (await client.get(f"{BASE}/blockchain/verify")).json()

        print("\ndone.")
        print(f"  lending score : {result['lending_score']}")
        for reason in result["score_reasons"]:
            print(f"     - {reason}")
        print(f"  still owed    : MWK {result['loan']['outstanding_balance']}")
        print(f"  ledger blocks : {stats['block_count']}")
        print(f"  chain valid   : {integrity['valid']}")
        print(f"  events        : {stats['events']}")
        print("\n  demo accounts (all share the same password):")
        print(f"    farmer, established   {FARMER_PHONE}")
        print(f"    farmer, no score      {NEW_FARMER_PHONE}")
        print(f"    service provider      {SUPPLIER_PHONE}")
        print(f"    cooperative           {COOP_PHONE}")
        print(f"    bank admin            {BANK_PHONE}")
        print(f"    password              {PASSWORD}")


async def clean() -> None:
    """Remove the demo rows, leaving the ledger untouched.

    The blocks are deliberately kept. A hash chain cannot have history removed
    without invalidating every block that follows, and deleting from the middle
    would break the chain permanently. Leaving them is also the truthful
    behaviour: `verify-record` then reports "anchored, but the record has been
    deleted", which is exactly what happened.

    Use --reset-ledger when you want a genuinely empty chain.
    """
    conn = await asyncpg.connect(DB)
    try:
        # Harvests, loans, repayments and the farmer profile all cascade from
        # the user rows.
        result = await conn.execute(
            "DELETE FROM users WHERE phone_number = ANY($1::text[])", DEMO_PHONES
        )
        await conn.execute(
            "DELETE FROM products WHERE product_name = $1", DEMO_PRODUCT_NAME
        )
        remaining = await conn.fetchval("SELECT count(*) FROM ledger_blocks")
        print(f"removed demo accounts ({result})")
        print(f"ledger blocks kept: {remaining} (the chain stays valid)")
        print(
            "  Their blocks now attest to deleted records, which verify-record\n"
            "  reports honestly. Run --reset-ledger for an empty chain."
        )
    finally:
        await conn.close()


async def reset_ledger() -> None:
    """Wipe the whole chain. Genesis is recreated on the next ledger read.

    Destructive and development-only: every anchored attestation is lost, so any
    record previously anchored becomes unverifiable.
    """
    conn = await asyncpg.connect(DB)
    try:
        before = await conn.fetchval("SELECT count(*) FROM ledger_blocks")
        await conn.execute("DELETE FROM ledger_blocks")
        print(f"deleted {before} block(s); the chain is now empty")
        print("  A fresh genesis block is mined on the next ledger request.")
    finally:
        await conn.close()


if __name__ == "__main__":
    if "--reset-ledger" in sys.argv:
        asyncio.run(reset_ledger())
    elif "--clean" in sys.argv:
        asyncio.run(clean())
    else:
        asyncio.run(seed())
