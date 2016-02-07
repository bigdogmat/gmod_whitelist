-- Load all of our files

if SERVER then
  AddCSLuaFile "whitelist/cl_init.lua"
  AddCSLuaFile "whitelist/shared.lua"

  include "whitelist/init.lua"
end

if CLIENT then
  include "whitelist/cl_init.lua"
end

include "whitelist/shared.lua"
