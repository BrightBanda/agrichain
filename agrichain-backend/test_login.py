import asyncio
import httpx

async def test_login():
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "http://127.0.0.1:8000/api/v1/auth/login",
            json={
                "phone_number": "1234",
                "password": "123456"
            }
        )
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")

if __name__ == "__main__":
    asyncio.run(test_login())
