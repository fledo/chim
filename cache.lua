local class = require 'middleclass'
local ThreadController = require 'thread_controller'
local Cache = class("Cache", ThreadController)

function Cache:initialize(set)
    ThreadController:initialize(self, set.name, set.size)
    -- Settings
    self.name        = set.name
    self.size        = set.size * 1024
    self.up          = set.up or "none"
    self.down        = set.down or "none"
    self.match       = set.match or 100
    self.action      = set.action or "none"
    self.timer       = set.timer or 3600
    
    -- Thread and channels
    self.thread      = love.thread.newThread("cache_thread.lua")
    self.queue       = love.thread.getChannel(self.name .. "queue")
    self.prio        = love.thread.getChannel(self.name .. "prio")
    self.stats       = love.thread.getChannel(self.name .. "stats")
    self.upward      = love.thread.getChannel(self.up .. "prio")
    self.downward    = love.thread.getChannel(self.down .. "queue")
    
    -- Stats
    self.used        = 0
    self.percent     = 0
    self.saved       = 0
    self.savedgb     = 0
    self.percent     = 0
    self.count       = 0
    self.downloads   = 0
    self.stored      = 0
    self.time        = 0
    self.seconds     = 0
    self.minutes     = 0
    self.hours       = 0
    self.days        = 0
    self.flushes     = 0 
    self.data        = ""
    self.hits        = 0
end
  
  -- Retreive cache values from the stats channel
  -- Return false if no new stats where found.
  -- Call this from love.update()
function Cache:update(dt)
  local stats = self.stats:pop()
  if stats then   
    self.time       = math.floor(stats.time)
    self.days       = math.floor(self.time / 86400)
    self.hours      = math.floor((self.time % 86400) / 3600)
    self.minutes    = math.floor(((self.time % 86400) % 3600) / 60)
    self.seconds    = math.floor(((self.time % 86400) % 3600) % 60)
    self.size       = math.ceil(stats.size / 1024)
    self.used       = math.ceil(stats.used / 1024)
    self.percent    = math.ceil((self.used / self.size) * 100)
    self.count      = self.queue:getCount()
    self.saved      = math.ceil(stats.saved / 1024)
    self.savedgb    = math.ceil(stats.saved / 1024 / 1024)
    self.downloads  = stats.downloads
    self.stored     = stats.stored
    self.flushes    = stats.flushes
    self.hits       = stats.hits
    self:save()
  end
end
  
function Cache:draw(x, y)
  -- text
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.print("Queue count: " .. self.count, x, y+10)
  love.graphics.print("Name: " .. self.name, x, y+30)
  love.graphics.print("Saved bandwidth: " .. self.savedgb, x, y+50)
  love.graphics.print(self.percent .. "% (" .. self.used .. "MB of " .. self.size  .. "MB)", x, y+70)
  love.graphics.print("Runtime: Day " .. self.days .. ", time " .. self.hours .. ":" .. self.minutes, x, y+90)
  love.graphics.print("Stored requests: " .. self.stored, x, y+110)
  love.graphics.print("Total hits: " .. self.hits, x, y+130)
  love.graphics.print("Status: " .. self:status(), x, y+150)
  
  -- bar
  love.graphics.rectangle("fill", x+5, y+170, 100, 20)  
  love.graphics.setColor(255, 0, 0, 250)
  love.graphics.rectangle("fill", x+5, y+170, self.percent, 20)
  love.graphics.setColor(255, 255, 255, 255)
end

return Cache