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

-- Match longest token names first so %book_pct_left wins over %book_pct.
local function compareLengthDesc(a, b) return #a > #b end
local function tokenNamesByLengthDesc()
    local names = {}
    for k in pairs(Tokens.expanders) do names[#names + 1] = k end
    table.sort(names, compareLengthDesc)
    return names
end

function Tokens.expand(format, book, state)
    if not format or format == "" then return "" end
    local names = tokenNamesByLengthDesc()
    local result = format
    for _, name in ipairs(names) do
        local expander = Tokens.expanders[name]
        result = result:gsub("%%" .. name, function()
            return tostring(expander(book, state) or "")
        end)
    end
    return result
end

return Tokens
