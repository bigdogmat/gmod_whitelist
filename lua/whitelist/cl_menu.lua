-- Whitelist menu


-- Localized functions
local string_gmatch = string.gmatch

-- Create menu variables
local list, reason, count, lookup

-- Create helper functions

local function add_ID(id, initial)

  if id == '' then return end
  if lookup[id] then return end

  lookup[id] = list:AddLine(id):GetID()
  count = count + 1

  if initial then return end

  RunConsoleCommand("whitelist", "add", id)

end

local function remove_ID(id)

  if id == '' then return end
  if not lookup[id] then return end

  list:RemoveLine(lookup[id])
  lookup[id] = nil
  count = count - 1

  RunConsoleCommand("whitelist", "remove", id)

end

-- Receive function for whitelist menu

net.Receive("bigdogmat_whitelist_open", function(len)

  reason = net.ReadString()
  lookup = {}
  count = 0

  local data = util.Decompress(net.ReadData(net.ReadUInt(16)))

  -- coroutine used to slow down the process of filling up the list
  local fill = coroutine.create(function()
    local inside = coroutine.running()

    for SteamID in string_gmatch(data, "STEAM_%d:%d:%d+") do

      add_ID(SteamID, true)

      if count % 25 == 0 then

        timer.Simple(0.1, function()
          if not inside then return end
          coroutine.resume(inside)
        end)
        coroutine.yield()

      end

    end
  end)

  -- Base panel
  local base = vgui.Create "DWhitelistPanel"
    base:SetSize(400, 400)
    base:DockPadding(10, 50, 10, 10)
    base:Center()
    base:MakePopup()

  -- Close base panel
  local close = base:Add "DButton"
    close:SetText 'X'
    close:SetPos(361, 9)
    close:SetSize(30, 30)

    function close:Paint(w, h)

      draw.RoundedBox(8, 0, 0, w, h, Color(149, 165, 166))

    end

    function close:DoClick()

      RunConsoleCommand("whitelist", "save")
      base:Remove()

    end

  local leftbase = base:Add "DPanel"
    leftbase:SetWidth(base:GetWide() / 2 - 15)
    leftbase:Dock(LEFT)

    function leftbase:Paint() end

  -- SteamID list panel
  list = leftbase:Add "DListView"
    --list:SetHeight(FI)
    list:Dock(FILL)
    list:SetMultiSelect(true)
    list:AddColumn "SteamIDs"

    coroutine.resume(fill)

    function list:DoDoubleClick(_, line)

      remove_ID(line:GetValue(1))

    end

  -- Remove all SteamIDs from whitelist. This'll
  -- have a confirmation button for the sake of
  -- sanity
  local list_remove_all = leftbase:Add "DWhitelistButton"
    list_remove_all:SetText "Remove All"
    list_remove_all:DockMargin(0, 2, 0, 0)
    list_remove_all:Dock(BOTTOM)

    function list_remove_all:DoClick()

      base:SetVisible(false)

      -- Base panel
      local query = vgui.Create "DWhitelistPanel"
        query:DockPadding(20, 15, 20, 15)
        query:SetSize(280, 120)
        query:Center()
        query:MakePopup()

      -- Confirmation text
      local message = query:Add "DLabel"
        message:SetFont "ChatFont"
        message:SetText "Are you sure? This can't be undone."
        message:SetTextColor(Color(236, 240, 241))
        message:Dock(TOP)
        message:SetContentAlignment(8)

      local confirm = query:Add "DWhitelistButton"
        confirm:SetText "I'm sure"
        confirm:SetWidth(90)
        confirm:DockMargin(0, 15, 0, 0)
        confirm:Dock(LEFT)

        function confirm:DoClick()

          for k, _ in pairs(lookup) do
            remove_ID(k)
          end

          query:Remove()
          base:SetVisible(true)

        end

      local decline = query:Add "DWhitelistButton"
        decline:SetText "No"
        decline:SetWidth(90)
        decline:DockMargin(0, 15, 0, 0)
        decline:Dock(RIGHT)

        function decline:DoClick()

          query:Remove()
          base:SetVisible(true)

        end

    end

  -- Remove selected IDs from the list
  local list_remove_select = leftbase:Add "DWhitelistButton"
    list_remove_select:SetText "Remove Selected"
    list_remove_select:DockMargin(0, 2, 0, 0)
    list_remove_select:Dock(BOTTOM)

    function list_remove_select:DoClick()

      for _, v in pairs(list:GetSelected()) do
        remove_ID(v:GetValue(1))
      end

    end

end)
