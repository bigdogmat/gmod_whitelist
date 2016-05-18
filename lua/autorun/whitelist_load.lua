-- Load files

if SERVER then
  util.AddNetworkString "bigdogmat_whitelist_open"
  util.AddNetworkString "bigdogmat_whitelist_kickreason"
  util.AddNetworkString "bigdogmat_whitelist_add"
  util.AddNetworkString "bigdogmat_whitelist_remove"

  AddCSLuaFile "whitelist/sh_cami.lua"
end

include "whitelist/sh_cami.lua"

CAMI.RegisterPrivilege{
  Name = "Whitelist",
  MinAccess = "superadmin",
}
