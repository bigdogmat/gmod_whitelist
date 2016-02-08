-- Load all base files

if SERVER then

  AddCSLuaFile "whitelist/cl_init.lua"
  include "whitelist/sv_init.lua"

end

if CLIENT then

  include "whitelist/cl_init.lua"

end
