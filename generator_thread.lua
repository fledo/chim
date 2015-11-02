local math = require("love.math")
local class = require 'middleclass'
local GT = class("GeneratorThread")

function GT:initialize(set)
  for k,v in pairs(set) do
    self[k] = v
  end
end

function GT:start()
  local request = {}
  generator = self.generator
  
  
  while self.time < self.run do
    -- Generate request
    request.id = self:generateID()
    request.size = self:calculateSize(request.id)
    request.time = self:forwardTime()
    -- Send the request to the chosen queue
    self.queue:push(request)

    -- Update stats
    self.bandwidth = self.bandwidth + request.size
    self.requests = self.requests + 1

    -- Send new stats if they have been retreived from the stats channel
    if self.stats:getCount() == 0 then
      self:pushStats()
    end
  end
  print(self.name .. " done!")
end

function GT:generateID()
  return generator:random(self.chance) == self.chance 
    and generator:random(self.low) 
    or generator:random(self.high)
end

function GT:calculateSize(id)
  local calculator = math.newRandomGenerator(id)
  calculator:random(self.limit)
  return calculator:random(self.limit)
end

function GT:forwardTime()
  self.time = self.time + (generator:random() * self.delay)
  return self.time
end

function GT:pushStats()
  self.stats:push({
    time = self.time,
    bandwidth = self.bandwidth,
    requests = self.requests
  })
end



local gt = GT(love.thread.getChannel("public"):demand())
gt:start()
gt:pushStats()