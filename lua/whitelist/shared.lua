-- Global shared table
-- Shared because it's easier to use
-- whitelist on both client and server

Whitelist = Whitelist or {
  lookup     = {},
  count      = 0,
  kickreason = "You're not whitelisted!",
  ranks      = {["admin"] = true, ["superadmin"] = true},
}
