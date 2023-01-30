Translator = {
  lang = nil,
  file = nil
}

function Translator:init()
  self.lang =  system.getPreference( "locale", "language" )

  if self.lang ~= "en" and self.lang ~= "fr" then self.lang = "en" end
  self.file = require("lang." .. self.lang)
end

function Translator:translate(key)
  return self.file[key]
end

function Translator:parse(key, data)
  local str = self.file[key]
  local idx = 1
  local count = 1

  if str == nil then return end
  idx = string.find(str, "|")
  while idx ~= nil do
    if str:byte(idx + 1) >= 48 and str:byte(idx + 1) <= 57 then
      str = string.sub(str, 0, idx - 1) .. data[count] .. string.sub(str, idx + 2)
      count = count + 1
    end
    idx = string.find(str, "|")
  end
  return str
end
