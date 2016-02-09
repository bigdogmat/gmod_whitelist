-- Load all base files

if SERVER then
  
  include "whitelist/sv_init.lua"

end

if CLIENT then

  include "whitelist/cl_init.lua"

end
