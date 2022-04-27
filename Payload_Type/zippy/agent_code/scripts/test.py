import asyncio

import websockets


async def consumer_handler(websocket):
    print(websocket.request_headers)
    while True:
        print(await websocket.recv())

async def producer_handler(websocket):
   await websocket.send(b"execute ls")
   await websocket.send(b"exit")

async def handler(websocket):
    await asyncio.gather(
        consumer_handler(websocket),
        producer_handler(websocket),
    )



async def main():
    async with websockets.serve(handler, "127.0.0.1", 3333):
        await asyncio.Future()  # run forever


if __name__ == "__main__":
    asyncio.run(main())
