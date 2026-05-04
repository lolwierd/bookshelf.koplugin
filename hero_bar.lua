-- hero_bar.lua
-- Progress-bar backend chooser. When bookends is installed we use its
-- BarWidget (seven styles). Otherwise we fall back to KOReader's stock
-- ProgressWidget (flat/bordered only).
--
-- All callers see a single `:new{ width, height, percentage, style }`
-- constructor and a paintable widget with `getSize / paintTo / free`.

local HeroBar = {}

local function loadBookendsBar()
    local ok, mod = pcall(require, "bookends_overlay_widget")
    if not ok or type(mod) ~= "table" or type(mod.BarWidget) ~= "table" then
        return nil
    end
    return mod.BarWidget
end

-- Style sets exposed in the line editor's bar-style cycle button. The
-- bookends list is a superset; the fallback keeps it to two real styles.
HeroBar.BOOKENDS_STYLES = {
    "bordered", "solid", "rounded", "metro", "wavy", "radial", "radial_hollow",
}
HeroBar.FALLBACK_STYLES = { "bordered", "solid" }

-- Returns the cycle-list applicable for the active backend.
function HeroBar.availableStyles()
    if loadBookendsBar() then return HeroBar.BOOKENDS_STYLES end
    return HeroBar.FALLBACK_STYLES
end

-- new{ width, height, percentage, style } -> a paintable widget.
-- `style` is the user's saved choice; we silently downgrade to "bordered"
-- if bookends isn't available and the saved style isn't in the fallback set.
function HeroBar:new(o)
    o = o or {}
    local width      = o.width or 0
    local height     = math.max(1, o.height or 5)
    local percentage = math.max(0, math.min(1, o.percentage or 0))
    local style      = o.style or "bordered"

    local Bar = loadBookendsBar()
    if Bar then
        return Bar:new{
            width    = width,
            height   = height,
            fraction = percentage,
            ticks    = {},
            style    = style,
        }
    end
    -- Fallback: KOReader ProgressWidget. Only "bordered" and "solid" are
    -- meaningful here; anything else renders as the default bordered look.
    local ProgressWidget = require("ui/widget/progresswidget")
    return ProgressWidget:new{
        width      = width,
        height     = height,
        percentage = percentage,
        margin_h   = 0,
        margin_v   = 0,
    }
end

return HeroBar
