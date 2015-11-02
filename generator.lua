local class = require 'middleclass'
local ThreadController = require 'thread_controller'
local Generator = class("Generator", ThreadController)

function Generator:initialize(set)
  -- Required settings
  self.name           = set.name or self.error("Parameter 'name' required.")
  self.cache          = set.cache or self.error("Parameter 'cache' required.")
  
  -- Optional settings
  self.run            = set.run or 3600 * 24 * 7
  self.delay          = set.delay or 1
  self.seed           = set.seed or os.time()
  self.high           = set.high or 1000000
  self.low            = set.low or 1000
  self.chance         = set.chance or 5
  self.limit          = set.limit or 1024
  self.generator      = love.math.newRandomGenerator(set.seed or os.time())
  
  -- Thread & Channels
  self.thread         = love.thread.newThread("generator_thread.lua")
  self.queue          = love.thread.getChannel(self.cache .. "queue")
  self.stats          = love.thread.getChannel(self.name .. "stats")
  
  -- Stats
  self.bandwidth      = 0
  self.bandwidthMB    = 0
  self.bandwidthGB    = 0
  self.time           = 0
  self.seconds        = 0
  self.minutes        = 0
  self.hours          = 0
  self.days           = 0
  self.requests       = 0
  self.data           = ""
end

-- retreive and calculate new stats if available
function Generator:update(dt)
  local stats = self.stats:pop()
  if stats then   
    self.bandwidth    = stats.bandwidth
    self.bandwidthMB  = math.floor(stats.bandwidth / 1024)
    self.bandwidthGB  = math.floor(stats.bandwidth / 1024 / 1024)
    self.time         = stats.time
    self.days         = math.floor(self.time / 86400)
    self.hours        = math.floor((self.time % 86400) / 3600)
    self.minutes      = math.floor(((self.time % 86400) % 3600) / 60)
    self.seconds      = math.floor(((self.time % 86400) % 3600) % 60)
    self.requests     = stats.requests
    self:save()
  end
end

function Generator:draw(x,y)
  love.graphics.print("Generation run time: Day " .. self.days .. ", time " .. self.hours .. ":" .. self.minutes, 10, 240)
  love.graphics.print("Generated bandwidth: " .. self.bandwidthGB .. " GB", 10, 260)
  love.graphics.print("Number of requests: " .. self.requests, 10, 280)
end

return Generator