local generator = {}
local cache = {}

function love.load()
  local class = require 'middleclass'
  local Generator = require 'generator'
  local Cache = require 'cache'
  local Counter = require 'counter'
  cache[1] = Cache({
    name = "cache[1]",
    down = "cache[2]",
    size = 1024 * 6,
    match = 1000000,
  })
cache[2] = Cache({
    name = "cache[2]",
    up = "cache[1]",
    down = "cache[3]",
    action = "timed",
    timer = 60 * 60 * 6,
    size = 1024 * 8,
    match = 2,
  })
  cache[3] = Counter({
    name = "cache[3]",
    up = "cache[2]",
    action = "flush",
    size = 1024,
    match = 1,
  })
  
  generator[1] = Generator({
    name = "C1", 
    cache = "cache[1]",
    seed = 1,
    run = 3600 * 12,
    delay = 0.01,
    chance = 10,
    low = 10000,      
    high = 1000000 * 100
  })
  
  for i,cache in pairs(cache) do
    cache:start()
  end
  for i,generator in pairs(generator) do
    generator:start()
  end
  love.graphics.setBackgroundColor(120, 120, 120, 255)
end


function love.update(dt)
  -- Update caches
  saved = 0
  for i,cache in pairs(cache) do
    cache:update(dt)
    saved = saved + cache.saved
  end
  saved = math.floor(saved / 1024)
  
  -- Update generators
  for i,generator in pairs(generator) do
    generator:update(dt)
  end
  
end

function love.draw()
  -- Draw caches
  local x = 10
  for i=#cache, 1, -1 do
    cache[i]:draw(x, 10)
    x = x + 190
  end
  
  -- Draw generators
  local x = 10
  for i=#generator, 1, -1 do
    generator[i]:draw(x, 240)
    x = x + 190
  end
  
  -- Draw total stats
  love.graphics.setColor(255,255, 255, 250)
  love.graphics.print("Saved:",10,200 )
  love.graphics.print(saved, 60, 200)
  love.graphics.print("GB",90,200 )
end

function love.keypressed(key)
  if key == "s" then
    for i,generator in pairs(generator) do
      generator:write()
    end
    for i,cache in pairs(cache) do
      cache:write()
    end
  end
end