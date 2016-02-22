-- Base server-side file


-- Global server-side table
Whitelist = Whitelist or {
  lookup     = {},
  count      = 0,
  kickreason = "You're not whitelisted!",
  ranks      = {["admin"] = true, ["superadmin"] = true},
}


-- Include all server-side a/////////////////ssets and
-- add client assets to download list
include "sv_manifest.lua"


-- Now lets create all of our global helper functions


-- Save
-- Args: !
-- Description: Saves whitelist in JSON format
-- Notes: Auto runs on shutdown or map change
function Whitelist.Save()

  file.Write("bigdogmat_whitelist/whitelist.txt", util.TableToJSON(Whitelist))

end
hook.Add("ShutDown", "bigdogmat_whitelist_save", Whitelist.Save)

-- Reload
-- Args: !
-- Description: Loads the whitelist
-- Notes: Auto loads on Initialize
function Whitelist.Reload()

  if not file.Exists("bigdogmat_whitelist", "DATA") then

    file.CreateDir "bigdogmat_whitelist"
    Whitelist.Save()

  elseif file.Exists("bigdogmat_whitelist/whitelist.txt", "DATA") then

    local json = file.Read("bigdogmat_whitelist/whitelist.txt", "DATA")

    -- "json" can't be nil here as for the file.Exist check
    -- so we just need to check if it's empty
    if json ~= '' then
      local jsontable = util.JSONToTable(json)

      if jsontable then
        for k, v in pairs(jsontable) do
          Whitelist[k] = v
        end
      else
        MsgN "Whitelist: Malformed whitelist file!"
        MsgN "Whitelist: Send file to addon creator if you want a chance to back it up. It's located in data/bigdogmat_whitelist"
        MsgN "Whitelist: Be sure to save backup of file before changing the whitelist as once changed it will overwrite bad file"
      end
    end
  end

  MsgN "Whitelist loaded!"
  MsgN("Whitelist: ", Whitelist.count, " player(s) whitelisted")

end
hook.Add("Initialize", "bigdogmat_whitelist_load", Whitelist.Reload)

-- Add
-- Args: SteamID:string
-- Description: Adds a SteamID to the whitelist
-- Notes: !
function Whitelist.Add(SteamID)

  if SteamID == '' then return end
  if Whitelist.lookup[SteamID] then return end

  Whitelist.lookup[SteamID] = true
  Whitelist.count = Whitelist.count + 1

end

-- Remove
-- Args: SteamID:string
-- Description: Removes a SteamID from the whitelist
-- Notes: !
function Whitelist.Remove(SteamID)

  if SteamID == '' then return end
  if not Whitelist.lookup[SteamID] then return end

  Whitelist.lookup[SteamID] = nil
  Whitelist.count = Whitelist.count - 1

end

-- Menu
-- Args: Player:entity
-- Description: Send whitelist data to client and
-- opens whitelist menu
-- Notes: I'll probably change the way this function
-- sends data
util.AddNetworkString "bigdogmat_whitelist_open"
function Whitelist.Menu(caller)

  net.Start "bigdogmat_whitelist_open"
    net.WriteString(Whitelist.kickreason)

    local list = ''

    if Whitelist.count > 0 then
      for id in pairs(Whitelist.lookup) do
        list = list .. id
      end

      list = util.Compress(list)
    end

    net.WriteUInt(#list, 16)
    net.WriteData(list, #list)
  net.Send(caller)

end

-- RankList
-- Args: !
-- Description: Returns a formatted string of all
-- usergroups allowed to make whitelist changes
-- Notes: !
function Whitelist.RankList()

  local str = ''

  for k, _ in pairs(Whitelist.ranks) do
    str = str .. k .. ", "
  end

  return str:sub(1, -3)

end

-- Allowed
-- Args: Player:entity
-- Description: Returns true if player is allowed to
-- make changes to the whitelist, false if not
-- Notes: Returns true for console
function Whitelist.Allowed(ply)

  if game.SinglePlayer() then return true end
  if not IsValid(ply) then return true end

  return Whitelist.ranks[ply:GetUserGroup()] == true

end


-- Now here is the actual hook that checks to see if
-- a connecting player is on the whitelist
hook.Add("CheckPassword", "bigdogmat_whitelist_kick", function(steamID)
  if not (Whitelist.lookup[util.SteamIDFrom64(steamID)] or game.SinglePlayer()) and Whitelist.count > 0 then
    return false, Whitelist.kickreason
  end
end)


-- And with that I believe we're done here :D
