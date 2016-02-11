-- Whitelist menu

-- Helper functions for drawing panels

local function drawBaseStyle(self, w, h)
  Derma_DrawBackgroundBlur(self, self.starttime)

  draw.RoundedBox(8, 0, 0, w, h, Color(40, 80, 80))
  draw.RoundedBox(8, 4, 4, w - 8, h - 8, Color(52, 152, 219, 200))
end

local function drawButtonStlye(w, h)
  draw.RoundedBox(8, 0, 0, w, h, Color(255, 255, 255))
  draw.RoundedBox(8, 1, 1, w - 2, h - 2, Color(149, 165, 166))
end


-- Receive function for whitelist menu

net.Receive("bigdogmat_whitelist_open", function(len)

  local list
  local reason, count, lookup = net.ReadString(), 0, {}
  local data = util.Decompress(net.ReadData(net.ReadUInt(16)))

  -- Helper functions for adding and removing SteamIDs

  local function add_ID(id, initial)

    if id == '' then return end
    if lookup[id] then return end

    lookup[id] = list:AddLine(id):GetID()
    count = count + 1

    if not initial then
      LocalPlayer():ConCommand("whitelist_add " .. id)
    end

  end

  local function remove_ID(id)

    if id == '' then return end
    if not lookup[id] then return end

    list:RemoveLine(lookup[id])
    lookup[id] = nil
    count = count - 1

    LocalPlayer():ConCommand("whitelist_remove " .. id)

  end

  -- coroutine used to slow down the process of filling up the list
  local fill = coroutine.create(function()
    local inside = coroutine.running()

    for SteamID in string.gmatch(data, "STEAM_[0-9]:[0-9]:[0-9]+") do

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
  local base = vgui.Create "DPanel"
    base:SetSize(400, 400)
    base:DockPadding(10, 50, 10, 10)
    base:Center()
    base:MakePopup()

    base.starttime = SysTime()
    function base:Paint(w, h)

      drawBaseStyle(self, w, h)
      draw.RoundedBoxEx(8, 4, 4, w - 8, 40, Color(21, 108, 150), true, true, false, false)

    end

  -- Close base panel
  local close = base:Add "DButton"
    close:SetText 'X'
    close:SetPos(361, 9)
    close:SetSize(30, 30)

    function close:Paint(w, h)

      draw.RoundedBox(8, 0, 0, w, h, Color(149, 165, 166))

    end

    function close:DoClick()

      RunConsoleCommand("whitelist_save")
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
  local list_remove_all = leftbase:Add "DButton"
    list_remove_all:SetText "Remove All"
    list_remove_all:SetTextColor(Color(236, 240, 241))
    list_remove_all:SetFont "bigdogmat_button_text"
    list_remove_all:DockMargin(0, 2, 0, 0)
    list_remove_all:Dock(BOTTOM)

    function list_remove_all:DoClick()

      base:SetVisible(false)

      -- Base panel
      local query = vgui.Create "DPanel"
        query:DockPadding(20, 15, 20, 15)
        query:SetSize(280, 120)
        query:Center()
        query:MakePopup()

        query.starttime = SysTime()
        function query:Paint(w, h)

          drawBaseStyle(self, w, h)

        end

        timer.Simple(10, function() query:Remove(); base:SetVisible(true) end)

      -- Confirmation text
      local message = query:Add "DLabel"
        message:SetFont "ChatFont"
        message:SetText "Are you sure? This can't be undone."
        message:SetTextColor(Color(236, 240, 241))
        message:Dock(TOP)
        message:SetContentAlignment(8)

      local confirm = query:Add "DButton"
        confirm:SetText "I'm sure"
        confirm:SetFont "bigdogmat_button_text"
        confirm:SetWidth(90)
        confirm:DockMargin(0, 15, 0, 0)
        confirm:Dock(LEFT)

        function confirm:DoClick()

          for k, _ in pairs(Whitelist.lookup) do
            remove_ID(k)
          end

          query:Remove()
          base:SetVisible(true)

        end

        function confirm:Paint(w, h)

          drawButtonStlye(w, h)

        end

      local decline = query:Add "DButton"
        decline:SetText "No"
        decline:SetFont "bigdogmat_button_text"
        decline:SetWidth(90)
        decline:DockMargin(0, 15, 0, 0)
        decline:Dock(RIGHT)

        function decline:DoClick()

          query:Remove()
          base:SetVisible(true)

        end

        function decline:Paint(w, h)

          drawButtonStlye(w, h)

        end




    end

    function list_remove_all:Paint(w, h)

      drawButtonStlye(w, h)

    end

  -- Remove selected IDs from the list
  local list_remove_select = leftbase:Add "DButton"
    list_remove_select:SetText "Remove Selected"
    --list_remove_select:SetTextColor(Color(236, 240, 241))
    list_remove_select:SetFont "bigdogmat_button_text"
    list_remove_select:DockMargin(0, 2, 0, 0)
    list_remove_select:Dock(BOTTOM)

    function list_remove_select:DoClick()

      for _, v in pairs(list:GetSelected()) do
        remove_ID(v:GetValue(1))
      end

    end

    function list_remove_select:Paint(w, h)

      drawButtonStlye(w, h)

    end

end)
