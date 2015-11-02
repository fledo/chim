local class = require 'middleclass'
local Cache = require 'cache'
local Counter = class("Counter", Cache)

function Counter:initialize(set)
    Cache.initialize(self, set)
    -- Settings
    self.down        = "none"
    
    -- Thread and channels
    self.thread      = love.thread.newThread("counter_thread.lua")
    self.downward    = love.thread.getChannel(self.down .. "queue")
end

return Counter