"""Populate the ledger with one full AgriChain story, for demos.

Walks the whole value proposition against a running server:

    farmer registered -> harvest recorded -> harvest verified
    -> produce listed -> loan approved -> repayment -> score updated

Every step anchors a block, so afterwards the app's Ledger Explorer has a
complete chain to show.

    python seed_demo.py           # create the demo data
    python seed_demo.py --clean   # remove it again

The accounts it creates all use the password below, so you can sign in as any of
them from the app.
"""

import asyncio
import sys

import asyncpg
import httpx

BASE = "http://127.0.0.1:8000/api/v1"
DB = "postgresql://postgres:secretepassword@localhost:5432/agrichain_db"
PASSWORD = "Password123!"

FARMER_PHONE = "+265991000001"
COOP_PHONE = "+265991000002"
BANK_PHONE = "+265991000003"
DEMO_PHONES = [FARMER_PHONE, COOP_PHONE, BANK_PHONE]

DEMO_NATIONAL_ID = "DEMO00000001"
DEMO_PRODUCT_NAME = "Demo Dry White Maize"
DEMO_REFERENCE = "DEMO-MM-000001"


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
        try:
            await client.get("http://127.0.0.1:8000/health")
        except httpx.ConnectError:
            sys.exit("The backend is not running on http://127.0.0.1:8000.")

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
            ("NBS Agri Finance", "FINANCIAL_INSTITUTION", BANK_PHONE),
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

        stats = (await client.get(f"{BASE}/blockchain/chain/stats")).json()
        integrity = (await client.get(f"{BASE}/blockchain/verify")).json()

        print("\ndone.")
        print(f"  lending score : {result['lending_score']}")
        for reason in result["score_reasons"]:
            print(f"     - {reason}")
        print(f"  ledger blocks : {stats['block_count']}")
        print(f"  chain valid   : {integrity['valid']}")
        print(f"  events        : {stats['events']}")
        print(f"\n  sign in as {FARMER_PHONE} / {PASSWORD}")


async def clean() -> None:
    conn = await asyncpg.connect(DB)
    try:
        # Blocks are append-only in normal operation, so the demo's blocks are
        # removed explicitly along with the rows they attest to.
        await conn.execute(
            """
            DELETE FROM ledger_blocks WHERE entity_id IN (
                SELECT id FROM farmers WHERE national_id_number = $2
                UNION SELECT id FROM products WHERE product_name = $3
                UNION SELECT h.id FROM harvests h JOIN users u ON u.id = h.user_id
                       WHERE u.phone_number = ANY($1::text[])
                UNION SELECT l.id FROM loans l JOIN users u ON u.id = l.farmer_user_id
                       WHERE u.phone_number = ANY($1::text[])
                UNION SELECT r.id FROM repayments r JOIN loans l ON l.id = r.loan_id
                       JOIN users u ON u.id = l.farmer_user_id
                       WHERE u.phone_number = ANY($1::text[])
                UNION SELECT id FROM users WHERE phone_number = ANY($1::text[])
            )
            """,
            DEMO_PHONES,
            DEMO_NATIONAL_ID,
            DEMO_PRODUCT_NAME,
        )
        # Everything else cascades from the user rows.
        result = await conn.execute(
            "DELETE FROM users WHERE phone_number = ANY($1::text[])", DEMO_PHONES
        )
        remaining = await conn.fetchval("SELECT count(*) FROM ledger_blocks")
        print(f"removed demo accounts ({result})")
        print(f"ledger blocks remaining: {remaining}")
    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(clean() if "--clean" in sys.argv else seed())
