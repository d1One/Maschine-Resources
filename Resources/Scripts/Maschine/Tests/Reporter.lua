------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Tests/Stats"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
Reporter = class( 'Reporter' )

------------------------------------------------------------------------------------------------------------------------

function Reporter.checkLongString(Line, InLongString, LsEquals, Linecount)
    local LongString
    if not Linecount then
        LongString, LsEquals = Line:match("^()%s*[%w_]+%s*=%s*%[(=*)%[[^]]*$")
        if not LongString then
            LongString, LsEquals = Line:match("^()%s*local%s*[%w_]+%s*=%s*%[(=*)%[%s*$")
        end
    end
    LsEquals = LsEquals or ""
    if LongString then
        InLongString = true
    elseif InLongString and Line:match("%]"..LsEquals.."%]") then
        InLongString = false
    end
    return InLongString, LsEquals or ""
end


------------------------------------------------------------------------------------------------------------------------
-- Starts the report generator

function Reporter.report()

    local Data, MostHits = Stats:load()

    if not Data then
        print("Could not load stats file "..Coverage.STAT_FILE..".")
        return false, "Failed to load Stats file!"
    end

    local Report = io.open(Coverage.REPORT_FILE, "w")

    local Names = {}
    for Filename, _ in pairs(Data) do

        local Include = false
        -- normalize paths in patterns
        local Path = Filename:gsub("\\", "/"):gsub("%.lua$", "")

        if not Coverage.INCLUDE[1] then
            Include = true
        else
            Include = false
            for _, P in ipairs(Coverage.INCLUDE) do
                if Path:match(P) then
                    Include = true
                    break
                end
            end
        end

        if Include and Coverage.EXCLUDE[1] then
            for _, P in ipairs(Coverage.EXCLUDE) do
                if Path:match(P) then
                    Include = false
                    break
                end
            end
        end

        if Include then
            table.insert(Names, Filename)
        end
    end

    table.sort(Names)
    local Summary = {}
    local MostHitsLength = ("%d"):format(MostHits):len()
    local EmptyFormat = (" "):rep(MostHitsLength + 1)
    local ZeroFormat = ("*"):rep(MostHitsLength).."0"
    local CountFormat = ("%% %dd"):format(MostHitsLength + 1)

    local Exclusions =
    {
        { false, "^#!" },     -- Unix hash-bang magic line
        { true, "" },         -- Empty line
        { true, "end,?" },    -- Single "end"
        { true, "else" },     -- Single "else"
        { true, "repeat" },   -- Single "repeat"
        { true, "do" },       -- Single "do"
        { true, "local%s+[%w_,%s]+" }, -- "local var1, ..., varN"
        { true, "local%s+[%w_,%s]+%s*=" }, -- "local var1, ..., varN ="
        { true, "local%s+function%s*%([%w_,%s%.]*%)" }, -- "local function(arg1, ..., argN)"
        { true, "local%s+function%s+[%w_]*%s*%([%w_,%s%.]*%)" }, -- "local function f (arg1, ..., argN)"
        { false, "Coverage" }, -- "*Coverage*"
        { false, "function" }, -- "*function*"
    }

    local Hit0Exclusions =
    {
        { true, "[%w_,='\"%s]+%s*," }, -- "var1 var2," multi columns table stuff
        { true, "%[?%s*[\"'%w_]+%s*%]?%s=.+," }, -- "[123] = 23," "[ "foo"] = "asd","
        { true, "[%w_,'\"%s]*function%s*%([%w_,%s%.]*%)" }, -- "1,2,function(...)"
        { true, "local%s+[%w_]+%s*=%s*function%s*%([%w_,%s%.]*%)" }, -- "local a = function(arg1, ..., argN)"
        { true, "[%w%._]+%s*=%s*function%s*%([%w_,%s%.]*%)" }, -- "a = function(arg1, ..., argN)"
        { true, "{%s*" }, -- "{" opening table
        { true, "}" }, -- "{" closing table
    }

    local function excluded(Exclusions, Line)
        for _, Ex in ipairs(Exclusions) do
            if Ex[1] then
                if Line:match("^%s*"..Ex[2].."%s*$") or Line:match("^%s*"..Ex[2].."%s*%-%-") then return true end
            else
                if Line:match(Ex[2]) then return true end
            end
        end
        return false
    end

    for _, Filename in ipairs(Names) do
        local Filedata = Data[Filename]

        local TmpFile

        if not NI.APP.isDebugVersion() then
            TmpFile = io.tmpfile();
            TmpFile:write(NI.UTILS.getScriptFromResource(Filename))
            TmpFile:seek("set", 0)
        else
            local Error
            TmpFile, Error = io.open(Filename, "r")
            if Error then
                print (Error)
            end
        end

        if TmpFile then
            Report:write("\n")
            Report:write("==============================================================================\n")
            Report:write(Filename, "\n")
            Report:write("==============================================================================\n")
            local LineNr = 1
            local FileHits, FileMiss = 0, 0
            local BlockComment, Equals = false, ""
            local InLongString, LsEquals = false, ""
            while true do
                local Line = TmpFile:read("*l")
                if not Line then break end
                local TrueLine = Line

                local NewBlockComment = false
                if not BlockComment then
                    local L, Equals = Line:match("^(.*)%-%-%[(=*)%[")
                    if L then
                        Line = L
                        NewBlockComment = true
                    end
                    InLongString, LsEquals = Reporter.checkLongString(Line, InLongString, LsEquals, Filedata[LineNr])
                else
                    local L = Line:match("%]"..Equals.."%](.*)$")
                    if L then
                        Line = L
                        BlockComment = false
                    end
                end

                local Hits = Filedata[LineNr] or 0
                if BlockComment or InLongString or excluded(Exclusions, Line) or (Hits == 0 and excluded(Hit0Exclusions, Line)) then
                    Report:write(EmptyFormat)
                else
                    if Hits == 0 then
                        FileMiss = FileMiss + 1
                        Report:write(ZeroFormat)
                    else
                        FileHits = FileHits + 1
                        Report:write(CountFormat:format(Hits))
                    end
                end
                Report:write("\t", TrueLine, "\n")
                if NewBlockComment then BlockComment = true end
                LineNr = LineNr + 1
                Summary[Filename] = {
                    Hits = FileHits,
                    Miss = FileMiss
                }
            end
            TmpFile:close()
        end
    end

    Report:write("\n")
    Report:write("==============================================================================\n")
    Report:write("Summary\n")
    Report:write("==============================================================================\n")
    Report:write("\n")

    local function writeTotal(Hits, Miss, Filename)

        Report:write(("%5d/%-5d"):format(Hits, Hits + Miss),
            ("%10.2f%%     "):format(Hits/(Hits + Miss) * 100.0),
            Filename, "\n")
    end

    local TotalHits, TotalMiss = 0, 0
    for _, Filename in ipairs(Names) do
        local S = Summary[Filename]
        if S then
            writeTotal(S.Hits, S.Miss, Filename)
            TotalHits = TotalHits + S.Hits
            TotalMiss = TotalMiss + S.Miss
        end
    end

    Report:write("------------------------\n")
    writeTotal(TotalHits, TotalMiss, "")
    Report:close()
    return true

end

------------------------------------------------------------------------------------------------------------------------
