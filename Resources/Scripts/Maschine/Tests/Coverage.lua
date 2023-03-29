------------------------------------------------------------------------------------------------------------------------
-- Lua coverage analyzer
------------------------------------------------------------------------------------------------------------------------

--[[
This is a Coverage Analyzer for and in Lua. Derived from luacov (https://github.com/norman/luacov and
https://github.com/keplerproject/luacov) but in 'Maschine' style which guarantees readability.
--]]

------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Tests/Stats"
require "Scripts/Maschine/Tests/Reporter"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
Coverage = class( 'Coverage' )

------------------------------------------------------------------------------------------------------------------------

-- filename to store stats collected
Coverage.STAT_FILE = ""

-- filename to store report
Coverage.REPORT_FILE = ""

-- Patterns for files to include when reporting
-- all will be included if nothing is listed
-- (exclude overrules include, do not include
-- the .lua extension)
Coverage.INCLUDE = {
}

-- Patterns for files to exclude when reporting
-- all will be included if nothing is listed
-- (exclude overrules include, do not include
-- the .lua extension)
Coverage.EXCLUDE = {
  "Scripts/Tests/Coverage$",
  "Scripts/Tests/Reporter$",
  "Scripts/Tests/Stats$",
}

Coverage.Data = {}

Coverage.Skip = {}
Coverage.Booting = true

local STATS_COUNTDOWN = 240

------------------------------------------------------------------------------------------------------------------------

function Coverage:__init(ControllerName)

    Coverage.STAT_FILE = NI.UTILS.getUserHomeDir().."/"..ControllerName..".luacoverage.dat"
    Coverage.REPORT_FILE = NI.UTILS.getUserHomeDir().."/"..ControllerName..".luacoverage.txt"


    self.Active = false
    self.Countdown = STATS_COUNTDOWN

    self:loadStatsFromFile()

    if App:getWorkspace():getCoverageActiveParameter():getValue() then
        self:setActive(true)
    end
end

------------------------------------------------------------------------------------------------------------------------

function Coverage:setActive(Active)

    self.Active = Active

    if not self.Active then
        debug.sethook()
        return
    end

    local onLine = function(_, LineNr)

        -- get name of processed file;
        local Name = debug.getinfo(2, "S").source

        if not NI.APP.isDebugVersion() then

            if not Name:match("^Scripts") then
                return
            end
        else
            if not Name:match("^@") then
                return
            end
            Name = Name:sub(2)
        end

        -- skip 'luacov.lua' in coverage report
        if Coverage.Booting then
            Coverage.Skip[Name] = true
            Coverage.Booting = false
        end

        if Coverage.Skip[Name] then
            return
        end

        local File = Coverage.Data[Name]

        if not File then
            File = {max=0}
            Coverage.Data[Name] = File
        end

        if LineNr > File.max then
            File.max = LineNr
        end
        File[LineNr] = (File[LineNr] or 0) + 1

    end

    debug.sethook(onLine, "l")

    -- debug must be set for each coroutine separately
    -- hence wrap coroutine function to set the hook there
    -- as well
    local rawcoroutinecreate = coroutine.create
    coroutine.create = function(...)
        local co = rawcoroutinecreate(...)
        debug.sethook(co, onLine, "l")
        return co
    end
    coroutine.wrap = function(...)
        local co = rawcoroutinecreate(...)
        debug.sethook(co, onLine, "l")
        return function()
            local r = { coroutine.resume(co) }
            if not r[1] then
                error(r[2])
            end
            if _VERSION == "Lua 5.1" then
                return unpack(r, 2)
            else
                return table.unpack(r, 2)
            end
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function Coverage:loadStatsFromFile()

    local File, Error = Stats.open()
    if not Error then
        Coverage.Data = Stats.load()
        Stats.close(File)
    end
end

------------------------------------------------------------------------------------------------------------------------

function Coverage:saveStatsToFile()

    local File, Error = Stats.open()
    if not Error then
        Stats.save(Coverage.Data, File)
        Stats.close(File)

        print("...Updating Coverage Stats File...")
    end
end

------------------------------------------------------------------------------------------------------------------------

function Coverage:purge()

    os.remove(Coverage.STAT_FILE)
    os.remove(Coverage.REPORT_FILE)

    print("Deleted "..Coverage.STAT_FILE)
    print("Deleted "..Coverage.REPORT_FILE)

    Coverage.Data = {}
end

------------------------------------------------------------------------------------------------------------------------

function Coverage:onTimer()

    if not self.Active then
        return
    end

    if self.Countdown == 0 then
        self:saveStatsToFile()
        self.Countdown = STATS_COUNTDOWN
    end

    self.Countdown = self.Countdown - 1
end

------------------------------------------------------------------------------------------------------------------------

function Coverage:generateReport()

    os.remove(Coverage.REPORT_FILE)

    local _, Success, Error = pcall(function() return Reporter.report() end)

    if Success then
        print("Generated: "..Coverage.REPORT_FILE)
    end

end

------------------------------------------------------------------------------------------------------------------------
