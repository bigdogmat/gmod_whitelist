-- Base button panel

local PANEL = {}

function PANEL:Init()

  self:SetTextColor(Color(236, 240, 241))
  self:SetFont "bigdogmat_button_text"

end

function PANEL:Paint(w, h)

  draw.RoundedBox(8, 0, 0, w, h, Color(255, 255, 255))
  draw.RoundedBox(8, 1, 1, w - 2, h - 2, Color(149, 165, 166))

end

vgui.Register("DWhitelistButton", PANEL, "DButton")
