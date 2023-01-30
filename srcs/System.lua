System = {}

function System.isMobile()
  local p = system.getInfo("platform")

  if p == nil then p = system.getInfo("platformName") end
  return system.getInfo( "environment" ) == "simulator" or (p ~= "Win" and p ~= "Mac OS X" and p ~= "macos" and p ~= "win32")
end
