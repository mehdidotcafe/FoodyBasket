return {
  player1 = {
    categoryBits = 1,
    maskBits = (1024 + 256 + 64 + 32 + 16 + 2)
  },
  player2 = {
    categoryBits = 2,
    maskBits = (1024 + 256 + 64 + 32 + 16 + 1)
  },
  player1Hands = {
    categoryBits = 4,
    maskBits = (0)
  },
  player2Hands = {
    categoryBits = 8,
    maskBits = (0)
  },
  ball = {
    categoryBits = 16,
    maskBits = (1 + 2 + 4 + 8 + 16 + 32 + 64 + 256 + 2048)
  },
  worldLimit = {
    categoryBits = 32,
    maskBits = (1 + 2 + 16 + 32 + 64 + 512)
  },
  worldLimitBall = {
    categoryBits = 2048,
    maskBits = (16 + 32 + 64)
  },
  worldLimitPlayer = {
    categoryBits = 1024,
    maskBits = (1 + 2 + 512)
  },
  basket = {
    categoryBits = 64,
    maskBits = (1 + 2 + 4 + 8 + 16 + 32 + 512 + 2048)
  },
  basketNet = {
    categoryBits = 128,
    maskBits = (1 + 2 + 512)
  },
  basketNetLim = {
    categoryBits = 256,
    maskBits = (1 + 2 + 16 + 512)
  },
  playerShoes = {
    categoryBits = 512,
    maskBits = (256 + 64 + 32 + 16  + 1024)
  }
}
