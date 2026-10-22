-- dates.lua
-- Formats and compares the { year, month, day } dates used in rings.lua.
-- Dates are written US-style, e.g. "September 28th, 2026".

local Dates = {}

local MONTH_NAMES = {
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
}

-- 1 -> "1st", 2 -> "2nd", 3 -> "3rd", 11 -> "11th", 22 -> "22nd" ...
local function ordinal(day)
    local lastTwo = day % 100
    if lastTwo >= 11 and lastTwo <= 13 then
        return day .. "th"
    end
    local last = day % 10
    if last == 1 then return day .. "st" end
    if last == 2 then return day .. "nd" end
    if last == 3 then return day .. "rd" end
    return day .. "th"
end

-- { 2026, 9, 28 } -> "September 28th, 2026"
function Dates.Format(date)
    if date == nil then
        return nil
    end
    return MONTH_NAMES[date[2]] .. " " .. ordinal(date[3]) .. ", " .. date[1]
end

-- Turns a date into a single comparable number, e.g. 20260928.
function Dates.Key(date)
    return date[1] * 10000 + date[2] * 100 + date[3]
end

-- True if `date` is on or after `since`. A missing date counts as old.
function Dates.IsOnOrAfter(date, since)
    if date == nil then
        return false
    end
    return Dates.Key(date) >= Dates.Key(since)
end

return Dates
