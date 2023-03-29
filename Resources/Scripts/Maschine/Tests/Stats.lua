------------------------------------------------------------------------------------------------------------------------
-- Manages the file with statistics (being) collected.
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
Stats = class( 'Stats' )

------------------------------------------------------------------------------------------------------------------------
-- Loads the stats file.

function Stats.load()

    local Data, MostHits = {}, 0
    local StatsFile = io.open(Coverage.STAT_FILE, "r")
    if not StatsFile then
        return nil
    end
    while true do
        local NLines = StatsFile:read("*n")
        if not NLines then
            break
        end
        local Skip = StatsFile:read(1)
        if Skip ~= ":" then
            break
        end
        local Filename = StatsFile:read("*l")
        if not Filename then
            break
        end
        Data[Filename] = {
            max=NLines
        }
        for Idx = 1, NLines do
           local Hits = StatsFile:read("*n")
           if not Hits then
               break
           end
           local Skip = StatsFile:read(1)
           if Skip ~= " " then
               break
           end
           if Hits > 0 then
               Data[Filename][Idx] = Hits
               MostHits = math.max(MostHits, Hits)
           end
        end
    end
    StatsFile:close()
    return Data, MostHits

end

------------------------------------------------------------------------------------------------------------------------
-- Opens the statfile

function Stats.open()
    return io.open(Coverage.STAT_FILE, "w")
end

------------------------------------------------------------------------------------------------------------------------
-- Closes the statfile

function Stats.close(Statsfile)
    Statsfile:close()
end

------------------------------------------------------------------------------------------------------------------------
-- Saves Data to the statfile

function Stats.save(Data, Statsfile)
    if not Statsfile then
       print "Luacov - Stats: no Statsfile"
       return
    end

    Statsfile:seek("set")
    for Filename, Filedata in pairs(Data) do
        local Max = Filedata.max
        Statsfile:write(Max, ":", Filename, "\n")
        for Idx = 1, Max do
            local Hits = Filedata[Idx]
            if not Hits then
                Hits = 0
            end
            Statsfile:write(Hits, " ")
        end
        Statsfile:write("\n")
    end
    Statsfile:flush()
end

------------------------------------------------------------------------------------------------------------------------
