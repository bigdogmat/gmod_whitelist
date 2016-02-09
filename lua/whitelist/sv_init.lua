-- Base server-side file


-- Global server-side table
WHITELIST = WHITELIST or {
  lookup     = {},
  count      = 0,
  kickreason = "You're not whitelisted!",
  ranks      = {["admin"] = true, ["superadmin"] = true},
}


-- Include all server-side assets and
-- add client assets to download list
include "sv_manifest.lua"


-- This is only needed because hook.Add
function WHITELIST:IsValid()

  return true

end


-- Save
-- Args: !
-- Description: Saves whitelist in JSON format
-- Notes: Auto runs on shutdown or map change

function WHITELIST:Save()

  file.Write("bigdogmat_whitelist/whitelist.txt", util.TableToJSON(self))

end
hook.Add("ShutDown", WHITELIST, WHITELIST.Save)


-- Reload
-- Args: !
-- Description: Loads the whitelist
-- Notes: Auto loads on Initialize

function WHITELIST:Reload()

  if not file.Exists("bigdogmat_whitelist", "DATA") then

    file.CreateDir "bigdogmat_whitelist"
    self:Save()

  elseif file.Exists("bigdogmat_whitelist/whitelist.txt", "DATA") then

    local json = file.Read("bigdogmat_whitelist/whitelist.txt", "DATA")

    -- "json" can't be nil here as for the file.Exist check
    -- so we just need to check if it's empty
    if json ~= '' then
      local jsontable = util.JSONToTable(json)

      if jsontable then
        for k, v in pairs(jsontable) do
          self[k] = v
        end
      else
        MsgN "Whitelist: Malformed whitelist file!"
        MsgN "Whitelist: Send file to addon creator if you want a chance to back it up. It's located in data/bigdogmat_whitelist"
        MsgN "Whitelist: Be sure to save backup of file before changing the whitelist as once changed it will overwrite bad file"
      end
    end
  end

  MsgN "Whitelist loaded!"
  MsgN("Whitelist: ", self.count, " player(s) whitelisted")

end
hook.Add("Initialize", WHITELIST, WHITELIST.Reload)


-- Add
-- Args: SteamID:string
-- Description: Adds a SteamID to the whitelist
-- Notes: !

function WHITELIST:Add(SteamID)

  if SteamID == '' then return end
  if self.lookup[SteamID] then return end

  self.lookup[SteamID] = true
  self.count = self.count + 1

end


-- Remove
-- Args: SteamID:string
-- Description: Removes a SteamID from the whitelist
-- Notes: !

function WHITELIST:Remove(SteamID)

  if SteamID == '' then return end
  if not self.lookup[SteamID] then return end

  self.lookup[SteamID] = nil
  self.count = self.count - 1

end


-- Menu
-- Args: Player:entity
-- Description: Send whitelist data to client and
-- opens whitelist menu
-- Notes: I'll probably change the way this function
-- sends data

util.AddNetworkString "bigdogmat_whitelist_open"
function WHITELIST:Menu(caller)

  net.Start "bigdogmat_whitelist_open"
    net.WriteString(self.kickreason)

    local list = ''
    for k, _ in pairs(self.lookup) do
      list = list .. k
    end

    list = util.Compress(list)

    net.WriteUInt(#list, 16)
    net.WriteData(list, #list)
  net.Send(caller)

end


-- RankList
-- Args: !
-- Description: Returns a formatted string of all
-- usergroups allowed to make whitelist changes
-- Notes: !

function WHITELIST:RankList()

  local str = ''

  for k, _ in pairs(self.ranks) do
    str = str .. k .. ", "
  end

  return str:sub(1, -3)

end


-- Allowed
-- Args: Player:entity
-- Description: Returns true if player is allowed to
-- make changes to the whitelist, false if not
-- Notes: Returns true for console

function WHITELIST:Allowed(ply)

  if not IsValid(ply) then return true end

  return self.ranks[ply:GetUserGroup()] == true

end


-- Actual commands
-- We're using console commands because then we only have to do this check
-- within the command and not within the helper function

-- whitelist_save
-- Args: !
-- Notes: Saves the whitelist to file

concommand.Add("whitelist_save", function(caller)
  if not WHITELIST:Allowed(caller) then return end

  WHITELIST:Save()
end)

-- whitelist_reload
-- Args: !
-- Notes: Reloads the whitelist from file

concommand.Add("whitelist_reload", function(caller)
  if IsValid(caller) then return end

  WHITELIST:Reload()
end)

-- whitelist_ranks
-- Args: !
-- Notes: Prints the ranks that are allowed to make whitelist changes to
-- console

concommand.Add("whitelist_ranklist", function(caller)
  if not WHITELIST:Allowed(caller) then return end

  if IsValid(caller) then
    caller:PrintMessage(HUD_PRINTCONSOLE, WHITELIST:RankList())
  else
    MsgN(WHITELIST:RankList())
  end
end)

-- whitelist_rankadd
-- Args: !
-- Notes: Adds a usergroup that is allowed to make whitelist changes.
-- Only allowed to be ran by server console

concommand.Add("whitelist_rankadd", function(caller, command, args)
  if IsValid(caller) then return end

  for _, v in ipairs(args) do
    WHITELIST.ranks[v] = true
  end
end)

-- whitelist_rankremove
-- Args: !
-- Notes: Removes a usergroup that is allowed to make whitelist changes.
-- Only allowed to be ran by server console

concommand.Add("whitelist_rankremove", function(caller, command, args)
  if IsValid(caller) then return end

  for _, v in ipairs(args) do
    WHITELIST.ranks[v] = nil
  end
end)

-- whitelist_kickreason
-- Args: reason
-- Notes: Sets the kick text for when a player is not whitelisted

concommand.Add("whitelist_kickreason", function(caller, command, args, arg)
  if arg == '' then return end
  if not WHITELIST:Allowed(caller) then return end

  WHITELIST.kickreason = arg
end)

-- whitelist_add
-- Args: SteamID
-- Notes: Adds a SteamID to the whitelist

concommand.Add("whitelist_add", function(caller, command, args, arg)
  if arg == '' then return end
  if not WHITELIST:Allowed(caller) then return end

  WHITELIST:Add(arg)
end)

-- whitelist_remove
-- Args: SteamID
-- Notes: Removes a SteamID from the whitelist

concommand.Add("whitelist_remove", function(caller, command, args, arg)
  if arg == '' then return end
  if not WHITELIST:Allowed(caller) then return end

  wWHITELIST:Remove(arg)
end)

-- whitelist_menu
-- Args: !
-- Notes: Opens the whitelist menu

concommand.Add("whitelist_menu", function(caller)
  if not IsValid(caller) then return end
  if not WHITELIST:Allowed(caller) then return end

  WHITELIST:Menu(caller)
end)


-- Chat commands
-- We're only gonna have one to make it easier to open
-- the whitelist

-- !whitelist
-- Args: !
-- Notes: Opens the whitelist menu

hook.Add("PlayerSay", "bigdogmat_whitelist_chat_commands", function(caller, text)
  if not IsValid(caller) then return end
  if not WHITELIST:Allowed(caller) then return end

  if string.lower(text) == "!whitelist" then
    WHITELIST:Menu(caller)
    return ''
  end
end)


-- Now here is the actual hook that checks to see if
-- a connecting player is on the whitelist

hook.Add("CheckPassword", "bigdogmat_whitelist_kick", function(steamID)
  if not (WHITELIST.lookup[util.SteamIDFrom64(steamID)] or game.SinglePlayer()) and WHITELIST.count > 0 then
    return false, WHITELIST.kickreason
  end
end)

-- And with that I believe we're done here :D
