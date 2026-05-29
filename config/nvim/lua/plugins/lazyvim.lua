-- LazyVim framework spec overrides (version channel + colorscheme).
-- Must live in lua/plugins/: this fragment merges AFTER the lazyvim.plugins
-- import, so it overrides LazyVim's own spec. The same keys on the import line
-- in lua/config/lazy.lua lose to the import's fragment and silently do nothing.
return {
  "LazyVim/LazyVim",
  -- Track main HEAD, not the latest release tag. LazyVim hardcodes version = "*"
  -- in its own spec, which overrides defaults.version; this re-overrides it so
  -- fixes that land on main before a tagged release are picked up.
  version = false,
  opts = {
    colorscheme = "catppuccin-mocha",
  },
}
