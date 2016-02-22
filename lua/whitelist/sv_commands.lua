-- Base file for creating console and chat commands


-- Localize whitelist table
local whitelist = Whitelist

-- base command table
local commands = {
  console = {},
  chat = {},
}

-- Helper functions for adding commands

local function registerConsoleCommand(command, callback, consoleOnly)

  -- consoleOnly defines whether or not he commands can only
  -- be called on the client or from server console

  -- true  = only console can use the command
  -- false = only clients can use the command
  -- nil   = both clients and server console can use command

  if type(callback) == "string" then
    callback = commands.console[callback]
    if not callback then return end
  end

  commands.console[command] = {callback, consoleOnly}

end

local function registerChatCommand(command, callback)

  if type(callback) == "string" then
    callback = commands.chat[callback]
    if not callback then return end
  end

  commands.chat[command] = callback

end

local function message(caller, str)

  if IsValid(caller) then
    caller:ChatPrint(str)
  else
    MsgN(str)
  end

end

local function consoleOnly(ply)

  if not IsValid(ply) then return false end
  message(ply, "This command can only be used by console!")

end

local function playerOnly(ply)

  if IsValid(ply) then return false end
  message(ply, "This command can't be used by our all mighty god")

end


-- Create commands


-- Save whitelist

registerConsoleCommand("save", whitelist.Save)
registerChatCommand("!wsave", whitelist.Save)

-- Reload whitelist
registerConsoleCommand("reload", function(caller)

  if consoleOnly(caller) then return end
  whitelist.Reload()

end, true)

-- Open menu

registerConsoleCommand("menu", whitelist.Menu, false)
registerChatCommand("!whitelist", whitelist.Menu)

-- Add to whitelist

registerConsoleCommand("add", function(caller, args)

  for _, id in ipairs(args) do
    if id:match "^STEAM_%d:%d:%d+$" then
      whitelist.Add(id)
    else
      message(caller, "[Whitelist] Invalid SteamID: " .. id)
    end
  end

end)
registerChatCommand("!wadd", function(caller, _, id)

  if not id:match "^STEAM_%d:%d:%d+$" then
    message(caller, "[Whitelist] Invalid SteamID: " .. id)
    return
  end

  whitelist.Add(id)

end)

-- Remove from whitelist

registerConsoleCommand("remove", function(caller, args)

  for _, id in ipairs(args) do
    if id:match "^STEAM_%d:%d:%d+$" then
      whitelist.Remove(id)
    else
      message(caller, "[Whitelist] Invalid SteamID: " .. id)
    end
  end

end)
registerChatCommand("!wremove", function(caller, _, id)

  if not id:match "^STEAM_%d:%d:%d+$" then
    message(caller, "[Whitelist] Invalid SteamID: " .. id)
    return
  end

  whitelist.Remove(id)

end)

-- Set whitelist kick reason

registerConsoleCommand("reason", function(_, _, reason) whitelist.reason = reason end)
registerChatCommand("!wreason", function(_, _, reason) whitelist.reason = reason end)

-- Add allowed ranks
registerConsoleCommand("addrank", function(caller, args)

  if consoleOnly(caller) then return end
  for _, rank in ipairs(args) do
    whitelist.ranks[rank] = true
  end

end, true)

-- Remove allowed ranks
registerConsoleCommand("removerank", function(caller, args)

  if consoleOnly(caller) then return end
  for _, rank in ipairs(args) do
    whitelist.ranks[rank] = nil
  end

end, true)

-- Rank list

registerConsoleCommand("ranklist", function(caller) message(caller, whitelist.RankList()) end)
registerChatCommand("!wlist", function(caller) message(caller, whitelist.RankList()) end)


-- Load all commands


-- Console commands
concommand.Add("whitelist", function(caller, command, args, text)
  local command = table.remove(args, 1):lower()

  if commands.console[command] then

    local info = commands.console[command]

    if info[2] then

      if consoleOnly(caller) then return end

    else

      if info[2] == false and playerOnly(caller) then return end

      if IsValid(caller) and not whitelist.Allowed(caller:GetUserGroup()) then
        caller:ChatPrint "You aren't allowed to use these commands!"
        return
      end
    end

    commands.console[command][1](caller, args, text:sub(#command + 2))

  end
end)

-- Chat commands
hook.Add("PlayerSay", "bigdogmat_whitelist_commands", function(caller, text)
  local split = text:Split(' ')
  local command = table.remove(split, 1):lower()

  if commands.chat[command] then

    if playerOnly(caller) then return end
    if not whitelist.Allowed(caller:GetUserGroup()) then
      caller:ChatPrint "You aren't allowed to use these commands!"
      return
    end

    commands.chat[command](caller, split, text:sub(#command + 2))
    return ''

  end
end)
