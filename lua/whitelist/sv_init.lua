-- Global whitelist table
Whitelist = Whitelist or {
  list = {},
  count = 0,
  reason = "You're not whitelisted!",
}

--[[---------------------------------------------------------------------------
Args; ::
Return; ::
Description; Saves the whitelist to file in JSON format
Notes;
-----------------------------------------------------------------------------]]
function Whitelist.Save()
  file.Write("bigdogmat_whitelist/whitelist.txt", util.TableToJSON(Whitelist))
end

--[[---------------------------------------------------------------------------
Args; ::
Return; ::
Description; Loads the whitelist from disk
Notes;
-----------------------------------------------------------------------------]]
function Whitelist.Reload()
  if not file.Exists("bigdogmat_whitelist", "DATA") then
    file.CreateDir "bigdogmat_whitelist"

    -- Save file template
    Whitelist.Save()
  elseif file.Exists("bigdogmat_whitelist/whitelist.txt", "DATA") then
    local json = file.Read("bigdogmat_whitelist/whitelist.txt", "DATA")

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

        return
      end
    end
  end

  MsgN "Whitelist loaded!"
  MsgN("Whitelist: ", Whitelist.count, " player(s) whitelisted")
end

--[[---------------------------------------------------------------------------
Args; SteamID::string
Return; ::
Description; Adds the SteamID to the whitelist
Notes;
-----------------------------------------------------------------------------]]
function Whitelist.Add(SteamID)
  if SteamID == '' then return end
  if Whitelist.list[SteamID] then return end

  Whitelist.list[SteamID] = true
  Whitelist.count = Whitelist.count + 1
end

--[[---------------------------------------------------------------------------
Args; SteamID::string
Return; ::
Description; Removes the SteamID from the whitelist
Notes;
-----------------------------------------------------------------------------]]
function Whitelist.Remove(SteamID)
  if SteamID == '' then return end
  if not Whitelist.list[SteamID] then return end

  Whitelist.list[SteamID] = nil
  Whitelist.count = Whitelist.count - 1
end

--[[---------------------------------------------------------------------------
Args; Caller::player
Return; ::
Description; Sends the whitelist data to the client and opens the menu
Notes;
-----------------------------------------------------------------------------]]
function Whitelist.Menu(Caller)
  net.Start "bigdogmat_whitelist_open"
    net.WriteString(Whitelist.reason)
    net.WriteUInt(Whitelist.count, 16)

    for id in pairs(Whitelist.list) do
      net.WriteString(id)
    end
  net.Send(Caller)
end

--[[---------------------------------------------------------------------------
Args; SteamID::string
Return; Allowed::boolean
Description; Returns whether the SteamID is whitelisted
Notes;
-----------------------------------------------------------------------------]]
function Whitelist.Allowed(SteamID)
  return Whitelist.list[SteamID] == true
end

--[[---------------------------------------------------------------------------
Args; ::
Return; Reason::string
Description; Returns the kick reason
Notes;
-----------------------------------------------------------------------------]]
function Whitelist.KickReason()
  return Whitelist.reason
end

--[[---------------------------------------------------------------------------
Args; Steam64::string
Return; (Kick::boolean & KickReason::string)
Description; The function used within the CheckPassword hook
Notes; If the player is whitelisted, nothing is returned. This also returns
nothing while in singleplayer, or while the whitelist is empty
-----------------------------------------------------------------------------]]
function Whitelist.KickFunction(Steam64)
  if not (Whitelist.list[util.SteamIDFrom64(Steam64)] or game.SinglePlayer()) and Whitelist.count > 0 then
    return false, Whitelist.reason
  end
end

--[[---------------------------------------------------------------------------
Args; Reason::string
Return; ::
Description; Sets the kick reason
Notes;
-----------------------------------------------------------------------------]]
function Whitelist.SetKickReason(Reason)
  Whitelist.reason = Reason
end

--[[---------------------------------------------------------------------------
Helper function to check permissions from net messages
-----------------------------------------------------------------------------]]
local function receive(name, callback)
  net.Receive(name, function(len, ply)
    CAMI.PlayerHasAccess(ply, "Whitelist", function(allowed)
      if not allowed then return end

      callback(len, ply)
    end)
  end)
end

-- Add hooks
hook.Add("Initialize", "bigdogmat_whitelist_load", Whitelist.Reload)
hook.Add("ShutDown", "bigdogmat_whitelist_save", Whitelist.Save)
hook.Add("CheckPassword", "bigdogmat_whitelist_kick", Whitelist.KickFunction)

-- Chat command
hook.Add("PlayerSay", "bigdogmat_whitelist_command", function(ply, text)
  if text:lower() == "-whitelist" then
    CAMI.PlayerHasAccess(ply, "Whitelist", function(allowed)
      if not allowed then return end

      Whitelist.Menu(ply)
    end)
  end
end)

-- Net messages
receive("bigdogmat_whitelist_open", function(_, ply)
  Whitelist.Menu(ply)
end)

receive("bigdogmat_whitelist_kickreason", function()
  Whitelist.SetKickReason(net.ReadString())
end)

receive("bigdogmat_whitelist_add", function()
  Whitelist.Add(net.ReadString())
end)

receive("bigdogmat_whitelist_remove", function()
  Whitelist.Remove(net.ReadString())
end)
