-- tokens.lua
-- Homescreen-scoped token expander. Bookends-compatible syntax, scoped
-- vocabulary tied to homescreen-available data sources.

local Tokens = {}

-- Token registry: name → function(book, state) → string
Tokens.expanders = {}

local function metaToken(field)
    return function(book) return book and book[field] or "" end
end

Tokens.expanders.title       = metaToken("title")
Tokens.expanders.author      = metaToken("author")
Tokens.expanders.author_2    = function(book)
    return book and book.authors and book.authors[2] or ""
end
Tokens.expanders.authors     = function(book)
    if not book or not book.authors then return "" end
    return table.concat(book.authors, ", ")
end
Tokens.expanders.series      = metaToken("series")
Tokens.expanders.series_name = metaToken("series_name")
Tokens.expanders.series_num  = metaToken("series_num")
Tokens.expanders.filename    = metaToken("filename")
Tokens.expanders.lang        = metaToken("lang")
Tokens.expanders.format      = metaToken("format")

local function pct(v) return string.format("%d%%", math.floor((v or 0) * 100 + 0.5)) end

Tokens.expanders.page_num   = function(b) return b and b.page_num and tostring(b.page_num) or "" end
Tokens.expanders.page_count = function(b) return b and b.page_count and tostring(b.page_count) or "" end
Tokens.expanders.book_pct       = function(b) return b and b.book_pct and pct(b.book_pct) or "" end
Tokens.expanders.book_pct_left  = function(b) return b and b.book_pct and pct(1 - b.book_pct) or "" end
Tokens.expanders.pages_left     = function(b)
    if not b or not b.page_num or not b.page_count then return "" end
    return tostring(b.page_count - b.page_num)
end

local function timeNow(state)
    return (state and state.now) or os.time()
end
local function fmt(spec, state) return os.date(spec, timeNow(state)) end

Tokens.expanders.time     = function(_b, s) return fmt("%H:%M", s) end
Tokens.expanders.time_24h = function(_b, s) return fmt("%H:%M", s) end
Tokens.expanders.time_12h = function(_b, s)
    local t = fmt("%I:%M %p", s)
    return (t:gsub("^0", ""))
end
Tokens.expanders.date          = function(_b, s) return fmt("%d %b", s):gsub("^0", "") end
Tokens.expanders.date_long     = function(_b, s) return fmt("%d %B %Y", s):gsub("^0", "") end
Tokens.expanders.date_numeric  = function(_b, s) return fmt("%d/%m/%Y", s) end
Tokens.expanders.weekday       = function(_b, s) return fmt("%A", s) end
Tokens.expanders.weekday_short = function(_b, s) return fmt("%a", s) end

local function minutesToHM(m)
    if not m or m <= 0 then return "" end
    local h = math.floor(m / 60); local mm = m % 60
    return string.format("%dh %02dm", h, mm)
end

Tokens.expanders.book_time_left   = function(b) return minutesToHM(b and b.book_time_left_minutes) end
Tokens.expanders.book_read_time   = function(b)
    return b and b.book_read_time_seconds and minutesToHM(math.floor(b.book_read_time_seconds / 60)) or ""
end
Tokens.expanders.pages_today      = function(_b, s) return s and s.pages_today and tostring(s.pages_today) or "" end
Tokens.expanders.time_today       = function(_b, s) return minutesToHM(s and s.time_today_minutes) end
Tokens.expanders.speed            = function(b) return b and b.speed_pph and tostring(b.speed_pph) or "" end
Tokens.expanders.avg_page_time    = function(b)
    if not b or not b.avg_page_time_seconds then return "" end
    local s = b.avg_page_time_seconds
    if s < 60 then return string.format("%ds", s) end
    return string.format("%dm %02ds", math.floor(s / 60), s % 60)
end
Tokens.expanders.book_pages_read    = function(b) return b and b.book_pages_read and tostring(b.book_pages_read) or "" end
Tokens.expanders.days_reading_book  = function(b) return b and b.days_reading_book and tostring(b.days_reading_book) or "" end
Tokens.expanders.pages_per_day      = function(b) return b and b.pages_per_day and tostring(b.pages_per_day) or "" end

Tokens.expanders.highlights   = function(b) return b and b.highlights and tostring(b.highlights) or "" end
Tokens.expanders.notes        = function(b) return b and b.notes and tostring(b.notes) or "" end
Tokens.expanders.bookmarks    = function(b) return b and b.bookmarks and tostring(b.bookmarks) or "" end
Tokens.expanders.annotations  = function(b)
    if not b then return "" end
    local total = (b.highlights or 0) + (b.notes or 0) + (b.bookmarks or 0)
    return total > 0 and tostring(total) or ""
end

Tokens.expanders.batt      = function(_b, s) return s and s.batt and (tostring(s.batt) .. "%") or "" end
Tokens.expanders.batt_icon = function(_b, s)
    if not s or not s.batt then return "" end
    if s.charging then return "⚡" end
    if s.batt < 20 then return "🪫" end
    return "🔋"
end
Tokens.expanders.wifi  = function(_b, s) return s and s.wifi == "on" and "📶" or "" end
Tokens.expanders.light = function(_b, s) return s and s.light or "" end
Tokens.expanders.warmth= function(_b, s) return s and s.warmth and tostring(s.warmth) or "" end
Tokens.expanders.mem   = function(_b, s) return s and s.mem and (tostring(s.mem) .. "%") or "" end
Tokens.expanders.ram   = function(_b, s) return s and s.ram_mib and (tostring(s.ram_mib) .. " MiB") or "" end
Tokens.expanders.disk  = function(_b, s) return s and s.disk_free or "" end

-- Match longest token names first so %book_pct_left wins over %book_pct.
local function compareLengthDesc(a, b) return #a > #b end
local function tokenNamesByLengthDesc()
    local names = {}
    for k in pairs(Tokens.expanders) do names[#names + 1] = k end
    table.sort(names, compareLengthDesc)
    return names
end

local function expandDatetimeBraces(format, state)
    return (format:gsub("%%datetime{(.-)}", function(spec)
        return os.date(spec, timeNow(state))
    end))
end

function Tokens.expand(format, book, state)
    if not format or format == "" then return "" end
    local result = expandDatetimeBraces(format, state)
    local names = tokenNamesByLengthDesc()
    for _, name in ipairs(names) do
        local expander = Tokens.expanders[name]
        result = result:gsub("%%" .. name, function()
            return tostring(expander(book, state) or "")
        end)
    end
    return result
end

return Tokens
