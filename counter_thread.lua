local timer = require("love.timer")
local class = require 'middleclass'
local CT = class("CounterThread")

function CT:initialize(set)
  for k,v in pairs(set) do
    self[k] = v
  end
  self.memory = {}
end

function CT:start()
  self:pushStats()
  print(self.name .. ": ready")
  
  while true do
    if not self.prio:peek() and not self.queue:peek() then
      timer.sleep(0.001) -- wait for work
    end
    self:handlePrio()
    self:handleQueue()
    self:pushStats()
  end
end

function CT:handleQueue()
  while self.queue:peek() and not self.prio:peek() and self.downward:getCount() < 2000 do
    local request = self.queue:pop()
    self.time = request.time
    
    if self:find(request.id) then
      if (self.memory[request.id].hits * self.memory[request.id].size) / 1024 > self.match then -- 
        self:moveUp(request.id)
      end
      
    -- If this is the last cache, cache the request
    elseif self.down == "none" then
      if not self:cache(request) then
        self:overflow(request)
      end
      
    else
      self.downward:push(request)
    end
    self:pushStats()
  end 
end

function CT:handlePrio()
  while self.prio:peek() do
    local request = self.prio:pop()
    if not self:find(request.id) then
      if not self:cache(request) then
        self:overflow(request)
      end
    end
    self:pushStats()
  end
end

function CT:moveUp(id)
  self.upward:push(self.memory[id])
  while self.queue:peek() do -- Try to avoid cacheing the same request again.
    if self.queue:peek().id == id then
      self.upward:push(self.queue:pop())
    else
      break
    end
  end
  
  -- The request has been moved to another cache, free memory space
  self.used = self.used - 0.1
  self.memory[id] = nil
  self.stored = self.stored - 1
end

function CT:find(id)
  if self.memory[id] then
    self.downloads = self.downloads + 1
    self.memory[id].hits = self.memory[id].hits + 1
    self.hits = self.hits + 1
    return true
  end
  return false
end

function CT:cache(request)
  if self.size > self.used + 0.1 then
    self.memory[request.id] = request
    self.memory[request.id].hits = 1
    self.downloads = self.downloads + 1
    self.used = self.used + 0.1
    self.stored = self.stored + 1
    return true
  end
  return false
end

function CT:overflow(request)
  if self.action == "flush" then
    self.flushes = self.flushes + 1
    self:clear()
    self:cache(request)
  elseif self.action == "timed" and self.flushes <= self.time / self.timer - 1 then
    self.flushes = self.flushes + 1
    self:clear()
    self:cache(request)
  end
end

function CT:clear()
  self.used = 0
  self.stored = 0
  self.memory = {}
end

function CT:pushStats()
  if self.stats:getCount() == 0 then 
    self.stats:push({  
      time       = self.time,
      size       = self.size,
      used       = self.used,
      percent    = self.percent,
      count      = self.count,
      saved      = self.saved,
      savedgb    = self.savedgb,
      downloads  = self.downloads,
      stored     = self.stored,
      flushes    = self.flushes,
      hits       = self.hits
    })
  end
end

ct = CT(love.thread.getChannel("public"):demand())
ct:start()

