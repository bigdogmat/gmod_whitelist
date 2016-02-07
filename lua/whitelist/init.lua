util.AddNetworkString "bigdogmat_whitelist_open"

-- whitelist_save
-- Args: !
-- Notes: Saves the whitelist in JSON format

local function whitelist_save()
  file.Write("bigdogmat_whitelist/whitelist.txt", util.TableToJSON(Whitelist))
end
hook.Add("ShutDown", "bigdogmat_whitelist_save", whitelist_save)

-- whitelist_reload
-- Args: !
-- Notes: Will reload the server whitelist file

local function whitelist_reload()
  if not file.Exists("bigdogmat_whitelist", "DATA") then

    file.CreateDir "bigdogmat_whitelist"
    whitelist_save()

  elseif file.Exists("bigdogmat_whitelist/whitelist.txt", "DATA") then

    local json = file.Read("bigdogmat_whitelist/whitelist.txt", "DATA")

    -- "json" can't be nil here as for the file.Exist check
    -- so we just need to check if it's empty
    if json ~= '' then
      local jsontable = util.JSONToTable(json)

      if jsontable then
        Whitelist = jsontable
      else
        MsgN "Whitelist: Malformed whitelist file!"
        MsgN "Whitelist: Send file to addon creator if you want a chance to back it up. It's located in data/bigdogmat_whitelist"
        MsgN "Whitelist: Be sure to save backup of file before changing the whitelist as once changed it will overwrite bad file"
      end
    end

    MsgN "Whitelist loaded!"
    MsgN("Whitelist: ", Whitelist.count, " player(s) whitelisted")

  end
end
hook.Add("Initialize", "bigdogmat_whitelist_load", whitelist_reload)

-- whitelist_update
-- Args: SteamID, boolean
-- Notes: SteamID is the players SteamID and boolean decides whether the
-- id will be added or removed from the whitelist

local function whitelist_update(id, mode)
  if id == '' then return end
  if (Whitelist.lookup[id] or false) == mode then return end

  Whitelist.lookup[id] = mode or nil
  Whitelist.count = Whitelist.count + (mode and 1 or -1)
end

-- whitelist_menu
-- Args: Player
-- Notes: Sends the whitelist data to a client. Rank doesn't
-- have to be checked as they can't do anything with this info

local function whitelist_menu(caller)
  net.Start "bigdogmat_whitelist_open"
    net.WriteString(Whitelist.kickreason)

    -- 10 Bits should be enough for this, if not then burn the person who has
    -- over 1024 people on their whitelist
    net.WriteUInt(Whitelist.count, 10)

    for k, _ in pairs(Whitelist.lookup) do
      net.WriteString(k)
    end
  net.Send(caller)
end


-- Actual commands
-- We're using console commands because then we only have to do this check
-- within the command and not within the helper function

-- whitelist_save
-- Args: !
-- Notes: Saves the whitelist to file

concommand.Add("whitelist_save", function(caller)
  if IsValid(caller) and not Whitelist.ranks[caller:GetUserGroup()] then return end

  whitelist_save()
end)

-- whitelist_reload
-- Args: !
-- Notes: Reloads the whitelist from file

concommand.Add("whitelist_reload", function(caller)
  if IsValid(caller) then return end

  whitelist_reload()
end)

-- whitelist_ranks
-- Args: !
-- Notes: Prints the ranks that are allowed to make whitelist changes to
-- console

concommand.Add("whitelist_ranklist", function(caller)
  if IsValid(caller) and not Whitelist.ranks[caller:GetUserGroup()] then return end

  local str = ''

  for k, _ in pairs(Whitelist.ranks) do
    str = str .. k .. ", "
  end

  str = str:sub(1, -3)

  if IsValid(caller) then
    caller:PrintMessage(HUD_PRINTCONSOLE, str)
  else
    MsgN(str)
  end
end)

-- whitelist_rankadd
-- Args: !
-- Notes: Adds a usergroup that is allowed to make whitelist changes.
-- Only allowed to be ran by server console

concommand.Add("whitelist_rankadd", function(caller, command, args)
  if IsValid(caller) then return end

  for _, v in ipairs(args) do
    Whitelist.ranks[v] = true
  end
end)

-- whitelist_rankremove
-- Args: !
-- Notes: Removes a usergroup that is allowed to make whitelist changes.
-- Only allowed to be ran by server console

concommand.Add("whitelist_rankremove", function(caller, command, args)
  if IsValid(caller) then return end

  for _, v in ipairs(args) do
    Whitelist.ranks[v] = nil
  end
end)

-- whitelist_kickreason
-- Args: reason
-- Notes: Sets the kick text for when a player is not whitelisted

concommand.Add("whitelist_kickreason", function(caller, command, args, arg)
  if IsValid(caller) and not Whitelist.ranks[caller:GetUserGroup()] then return end
  if arg == '' then return end

  Whitelist.kickreason = arg
end)

-- whitelist_add
-- Args: SteamID
-- Notes: Adds a SteamID to the whitelist

concommand.Add("whitelist_add", function(caller, command, args, arg)
  if IsValid(caller) and not Whitelist.ranks[caller:GetUserGroup()] then return end
  if arg == '' then return end

  whitelist_update(arg, true)
end)

-- whitelist_remove
-- Args: SteamID
-- Notes: Removes a SteamID from the whitelist

concommand.Add("whitelist_remove", function(caller, command, args, arg)
  if IsValid(caller) and not Whitelist.ranks[caller:GetUserGroup()] then return end
  if arg == '' then return end

  whitelist_update(arg, false)
end)

-- whitelist_menu
-- Args: !
-- Notes: Opens the whitelist menu

concommand.Add("whitelist_menu", function(caller)
  if not IsValid(caller) then return end
  if not Whitelist.ranks[caller:GetUserGroup()] then return end

  whitelist_menu(caller)
end)


-- Chat commands
-- We're only gonna have one to make it easier to open
-- the whitelist

-- !whitelist
-- Args: !
-- Notes: Opens the whitelist menu

hook.Add("PlayerSay", "bigdogmat_whitelist_chat_commands", function(caller, text)
  if not IsValid(caller) then return end
  if not Whitelist.ranks[caller:GetUserGroup()] then return end

  if string.lower(text) == "!whitelist" then
    whitelist_menu(caller)
    return ''
  end
end)


-- Now here is the actual hook that checks to see if
-- a connecting player is on the whitelist

hook.Add("CheckPassword", "bigdogmat_whitelist_kick", function(steamID)
  if not (Whitelist.lookup[util.SteamIDFrom64(steamID)] or game.SinglePlayer()) and Whitelist.count > 0 then
    return false, Whitelist.kickreason
  end
end)

-- And with that I believe we're done here :D
