-- Base panel

local PANEL = {}

function PANEL:Init()

  self.starttime = SysTime()

end

function PANEL:Paint(w, h)

  Derma_DrawBackgroundBlur(self, self.starttime)

  draw.RoundedBox(8, 0, 0, w, h, Color(40, 80, 80))
  draw.RoundedBox(8, 4, 4, w - 8, h - 8, Color(52, 152, 219, 200))

end

vgui.Register("DWhitelistPanel", PANEL, "DPanel")
