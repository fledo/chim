local class = require 'middleclass'
local ThreadController = class("ThreadController")

function ThreadController:initialize(self, name, size)
  if not name or not size then
    self:error("Parameter name and size required.", name)
  end
end

function ThreadController:save()
  for k,v in pairs(self) do
    if k == "data" then
      self.data = self.data .. "data;"
    elseif type(v) == "string" or type(v) == "number" then 
      self.data = self.data .. tostring(v) .. ";"
    end
  end
  self.data = self.data .. "\r\n"
end

function ThreadController:write()
  love.filesystem.append(self.name .. ".csv", self.data)
end

function ThreadController:start()
  local data = ""
  for k,v in pairs(self) do
    if type(v) == "string" or type(v) == "number" then 
      data = data .. k .. ";"
    end
  end
  data = data .. "\r\n"
  love.filesystem.remove(self.name .. ".csv")
  love.filesystem.write(self.name .. ".csv", data)
  
  local settings = self
  settings.class = nil
  self.thread:start()
  love.thread.getChannel("public"):supply(settings)
end

function ThreadController:status()
      return self.thread:isRunning() and "Thread OK" or self.error(self.thread:getError())
  end
  
function ThreadController:error(error, name)
  name = name or self.name or tostring(self)
  love.errhand(name .. ": " .. error)
  love.event:quit()
end

return ThreadController