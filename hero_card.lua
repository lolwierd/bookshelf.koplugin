-- hero_card.lua
-- Currently-reading detail card: cover thumbnail + an editable right column
-- composed from five region templates (status / title / author / description
-- / progress). All region styling and content is driven by hero_regions.

local FrameContainer  = require("ui/widget/container/framecontainer")
local InputContainer  = require("ui/widget/container/inputcontainer")
local CenterContainer = require("ui/widget/container/centercontainer")
local TopContainer    = require("ui/widget/container/topcontainer")
local BottomContainer = require("ui/widget/container/bottomcontainer")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan  = require("ui/widget/horizontalspan")
local VerticalGroup   = require("ui/widget/verticalgroup")
local VerticalSpan    = require("ui/widget/verticalspan")
local OverlapGroup    = require("ui/widget/overlapgroup")
local LineWidget      = require("ui/widget/linewidget")
local TextBoxWidget   = require("ui/widget/textboxwidget")
local TextWidget      = require("ui/widget/textwidget")
local Geom            = require("ui/geometry")
local GestureRange    = require("ui/gesturerange")
local Size            = require("ui/size")
local Font            = require("ui/font")
local Blitbuffer      = require("ffi/blitbuffer")
local Screen          = require("device").screen
local SpineWidget     = require("spine_widget")
local Tokens          = require("tokens")
local Regions         = require("hero_regions")
local HeroBar         = require("hero_bar")

local HeroCard = InputContainer:extend{
    book         = nil,
    width        = nil,
    height       = nil,
    cover_w      = 116,
    cover_h      = nil,
    pad          = nil,
    device_state = nil,
    on_tap       = nil,
    on_hold      = nil,
}

-- Reads the user's font-scale setting (% of nominal). Applied on top of
-- per-region font_size so the user can dial the whole hero up or down.
local function fontFace(face_name, base)
    local scale = (G_reader_settings:readSetting("bookshelf_font_scale") or 100) / 100
    return Font:getFace(face_name or "infofont", math.max(8, math.floor(base * scale + 0.5)))
end

local BAR_TOKEN_PATTERN = "%%bar"

function HeroCard:init()
    self.cover_h = self.cover_h or self.height
    self.dimen = Geom:new{ w = self.width, h = self.height }
    if not self.book then
        self[1] = self:_renderEmpty()
    else
        self[1] = self:_renderFull()
    end
    self.ges_events = {
        Tap  = { GestureRange:new{ ges = "tap",  range = self.dimen } },
        Hold = { GestureRange:new{ ges = "hold", range = self.dimen } },
    }
end

function HeroCard:_renderEmpty()
    return FrameContainer:new{
        width      = self.width,
        height     = self.height,
        bordersize = Size.border.thin,
        padding    = 0,
        CenterContainer:new{
            dimen = Geom:new{ w = self.width, h = self.height },
            TextBoxWidget:new{
                text      = "Welcome to Bookshelf · Tap a cover to start reading",
                face      = fontFace("infofont", 14),
                width     = self.width - Size.padding.large * 2,
                alignment = "center",
            },
        },
    }
end

-- Build a TextBoxWidget for a single region using the resolved settings.
local function buildText(text, region, width)
    local face = region.font_face
        and Font:getFace(region.font_face,
                math.max(8, math.floor(region.font_size *
                    ((G_reader_settings:readSetting("bookshelf_font_scale") or 100) / 100) + 0.5)))
        or fontFace("infofont", region.font_size)
    local rendered = text
    if region.uppercase then rendered = rendered:upper() end
    return TextBoxWidget:new{
        text      = rendered,
        face      = face,
        bold      = region.bold or false,
        width     = width,
        alignment = region.alignment or "left",
    }
end

-- Build a HorizontalGroup of [text-before, BarWidget, text-after] when the
-- progress template contains %bar. If no %bar, returns a plain TextBoxWidget.
local function buildProgressLine(expanded, region, width, book)
    local has_bar = expanded:find(BAR_TOKEN_PATTERN) ~= nil
    if not has_bar then
        return buildText(expanded, region, width)
    end
    local before, after = expanded:match("^(.-)%%bar(.*)$")
    if not before then before, after = expanded, "" end
    before = before:gsub("%s+$", "")
    after  = after:gsub("^%s+", "")

    local face = region.font_face
        and Font:getFace(region.font_face,
                math.max(8, math.floor(region.font_size *
                    ((G_reader_settings:readSetting("bookshelf_font_scale") or 100) / 100) + 0.5)))
        or fontFace("infofont", region.font_size)

    local used_w = 0
    local b_widget, b_width = nil, 0
    if before and before ~= "" then
        local display = region.uppercase and before:upper() or before
        b_widget = TextWidget:new{ text = display, face = face, bold = region.bold or false }
        b_width = b_widget:getSize().w
        used_w = used_w + b_width
    end
    local a_widget, a_width = nil, 0
    if after and after ~= "" then
        local display = region.uppercase and after:upper() or after
        a_widget = TextWidget:new{ text = display, face = face, bold = region.bold or false }
        a_width = a_widget:getSize().w
        used_w = used_w + a_width
    end

    -- Bar height: explicit setting else font ascent (~font_size * scale).
    local scale = (G_reader_settings:readSetting("bookshelf_font_scale") or 100) / 100
    local default_h = math.max(8, math.floor(region.font_size * scale + 0.5))
    local bar_h = region.bar_height or default_h
    local bar_w = math.max(0, width - used_w
        - (b_widget and Size.padding.small or 0)
        - (a_widget and Size.padding.small or 0))

    local pct = book and book.book_pct or 0

    if bar_w < 1 then
        -- No room for bar. Render text only, joined.
        local joined = before
        if after ~= "" then joined = joined ~= "" and (joined .. " " .. after) or after end
        return buildText(joined ~= "" and joined or "", region, width)
    end

    local bar = HeroBar:new{
        width      = bar_w,
        height     = bar_h,
        percentage = pct,
        style      = region.bar_style or "bordered",
    }

    local hg = HorizontalGroup:new{ align = "center" }
    if b_widget then
        hg[#hg + 1] = b_widget
        hg[#hg + 1] = HorizontalSpan:new{ width = Size.padding.small }
    end
    hg[#hg + 1] = bar
    if a_widget then
        hg[#hg + 1] = HorizontalSpan:new{ width = Size.padding.small }
        hg[#hg + 1] = a_widget
    end
    return hg
end

-- _buildRightColumn(book, regions, state, dimen) — builds the OverlapGroup
-- that lives to the right of the cover. Both _renderFull and the live
-- preview path call this so renders stay structurally identical.
function HeroCard:_buildRightColumn(book, regions, state, dimen)
    local right_w = dimen.w
    local cover_h = dimen.h

    local right_top    = VerticalGroup:new{ align = "left" }
    local right_bottom = VerticalGroup:new{ align = "left" }

    -- Status (with hairline + small gap below if non-empty)
    local status_text = Tokens.expand(regions.status.template, book, state)
    status_text = status_text:gsub("%[/?[biu]%]", "")
    if not Tokens.isEmpty(status_text) then
        right_top[#right_top + 1] = buildText(status_text, regions.status, right_w)
        right_top[#right_top + 1] = LineWidget:new{
            dimen      = Geom:new{ w = right_w, h = Size.line.medium },
            background = Blitbuffer.gray(0.4),
        }
        right_top[#right_top + 1] = VerticalSpan:new{ width = Size.padding.default }
    end

    -- Title
    local title_text = Tokens.expand(regions.title.template, book, state)
    title_text = title_text:gsub("%[/?[biu]%]", "")
    if not Tokens.isEmpty(title_text) then
        right_top[#right_top + 1] = buildText(title_text, regions.title, right_w)
    end

    -- Author
    local author_text = Tokens.expand(regions.author.template, book, state)
    author_text = author_text:gsub("%[/?[biu]%]", "")
    if not Tokens.isEmpty(author_text) then
        right_top[#right_top + 1] = buildText(author_text, regions.author, right_w)
    end

    -- Progress (bottom-anchored)
    local progress_text = Tokens.expand(regions.progress.template, book, state)
    progress_text = progress_text:gsub("%[/?[biu]%]", "")
    if not Tokens.isEmpty(progress_text) then
        right_bottom[#right_bottom + 1] = buildProgressLine(progress_text, regions.progress, right_w, book)
    end

    -- Description (fills the slack between right_top and right_bottom)
    local desc_text = Tokens.expand(regions.description.template, book, state)
    desc_text = desc_text:gsub("%[/?[biu]%]", "")
    if not Tokens.isEmpty(desc_text) then
        right_top[#right_top + 1] = VerticalSpan:new{ width = Size.padding.default }
        local top_used = 0
        for i = 1, #right_top do
            local g = right_top[i]:getSize()
            top_used = top_used + (g and g.h or 0)
        end
        local bottom_h = right_bottom:getSize().h
        local breath   = Size.padding.default
        local available = cover_h - top_used - bottom_h - breath
        if available > Screen:scaleBySize(40) then
            local face = regions.description.font_face
                and Font:getFace(regions.description.font_face,
                        math.max(8, math.floor(regions.description.font_size *
                            ((G_reader_settings:readSetting("bookshelf_font_scale") or 100) / 100) + 0.5)))
                or fontFace("infofont", regions.description.font_size)
            right_top[#right_top + 1] = TextBoxWidget:new{
                text                          = desc_text,
                face                          = face,
                bold                          = regions.description.bold or false,
                width                         = right_w,
                height                        = available,
                alignment                     = regions.description.alignment or "left",
                height_overflow_show_ellipsis = true,
            }
        end
    end

    local rd = Geom:new{ w = right_w, h = cover_h }
    return OverlapGroup:new{
        dimen = rd,
        TopContainer:new{    dimen = rd, right_top },
        BottomContainer:new{ dimen = rd, right_bottom },
    }
end

function HeroCard:_renderFull()
    local cover_h = self.cover_h or self.height

    local cover = SpineWidget:new{
        book   = self.book,
        width  = self.cover_w,
        height = cover_h,
        on_tap = self.on_tap,
        on_hold = self.on_hold,
    }

    local text_padding = self.pad or Size.padding.fullscreen
    local right_w = self.width - self.cover_w - text_padding

    local regions = Regions.read()
    local right = self:_buildRightColumn(
        self.book, regions, self.device_state,
        Geom:new{ w = right_w, h = cover_h })

    -- Stash the outer HorizontalGroup + right slot index so the live
    -- preview path can swap [3] without rebuilding the cover.
    local hg = HorizontalGroup:new{
        align = "top",
        cover,
        HorizontalSpan:new{ width = text_padding },
        right,
    }
    self._right_holder    = hg
    self._right_slot      = 3
    self._right_dimen     = Geom:new{ w = right_w, h = cover_h }
    return hg
end

-- replaceRightColumn(regions) — swaps the right OverlapGroup with a fresh
-- build from the supplied regions table. Returns true on success, false if
-- the holder hasn't been built yet (e.g. empty-state hero).
function HeroCard:replaceRightColumn(regions, book, state)
    if not self._right_holder or not self._right_dimen then return false end
    local fresh = self:_buildRightColumn(book or self.book, regions,
        state or self.device_state, self._right_dimen)
    local old = self._right_holder[self._right_slot]
    self._right_holder[self._right_slot] = fresh
    if self._right_holder.resetLayout then self._right_holder:resetLayout() end
    if old and old.free then
        local UIManager = require("ui/uimanager")
        UIManager:nextTick(function() pcall(function() old:free() end) end)
    end
    return true
end

function HeroCard:onTap()  if self.on_tap  then self.on_tap(self.book)  end; return true end
function HeroCard:onHold() if self.on_hold then self.on_hold(self.book) end; return true end

return HeroCard
