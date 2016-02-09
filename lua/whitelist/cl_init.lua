-- Base client-side file


-- Include client-side/shared assets
include "cl_manifest.lua"


-- Fonts used by the menu, this'll probably
-- change over time as I change my mind about
-- how they look

surface.CreateFont("bigdogmat_button_text", {
  font = "Trebuchet18",
  size = 18,
  weight = 600,
  antialias = true,
})
