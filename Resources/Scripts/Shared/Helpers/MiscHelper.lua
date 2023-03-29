
------------------------------------------------------------------------------------------------------------------------

MiscHelper = {}

------------------------------------------------------------------------------------------------------------------------

function MiscHelper.bind1(Function, Value)

    return function (...)
        return Function(Value, ...)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MiscHelper.bind2(Function, Value1, Value2)

    return function (...)
        return Function(Value1, Value2, ...)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MiscHelper.updateTable(Table, Index, Value, Insert)

    Table[Index] = (Insert == true) and Value or nil

end

------------------------------------------------------------------------------------------------------------------------

function MiscHelper.resetTable(Table)

    for Idx, _ in pairs(Table) do
        Table[Idx] = nil
    end

end

------------------------------------------------------------------------------------------------------------------------

function MiscHelper.getTableSize(Table)

    local Count = 0
    for _, TableValue in pairs(Table) do
        if TableValue ~= nil then
            Count = Count + 1
        end
    end

    return Count

end

------------------------------------------------------------------------------------------------------------------------

function MiscHelper.getMinMaxFromTable(Table)

    local Min, Max = nil, nil
    for _, TableValue in pairs(Table) do
        if TableValue ~= nil then
            Min = (Min == nil) and TableValue or math.min(Min, TableValue)
            Max = (Max == nil) and TableValue or math.max(Max, TableValue)
        end
    end

    return Min, Max

end

------------------------------------------------------------------------------------------------------------------------

function ternary(Condition, IfThen, IfElse)

    if Condition then return IfThen else return IfElse end

end

------------------------------------------------------------------------------------------------------------------------
-- math extension, wrap between MinValue .. MaxValue
------------------------------------------------------------------------------------------------------------------------

function math.wrap(Value, MinValue, MaxValue)


    local Range  = MaxValue - MinValue + 1
    local Result = (Value - MinValue) % Range + MinValue

    if Result < MinValue then Result = Result + Range end

    return Result

end

------------------------------------------------------------------------------------------------------------------------

function math.bound(Value, MinValue, MaxValue)

    Value = math.min(Value, MaxValue)
    Value = math.max(Value, MinValue)

    return Value

end

------------------------------------------------------------------------------------------------------------------------

function math.inRange(Value, MinValue, MaxValue)

    return Value >= MinValue and Value <= MaxValue

end

------------------------------------------------------------------------------------------------------------------------

function math.normalizeValue(Value, Max)

    return math.bound(math.floor(Value*Max), 0, Max)

end

------------------------------------------------------------------------------------------------------------------------

function math.round(Value)

    return math.floor(Value + 0.5)

end

------------------------------------------------------------------------------------------------------------------------
function math.toggle(Value, V1, V2)

    return Value == V1 and V2 or V1

end

------------------------------------------------------------------------------------------------------------------------

function math.sgn(Value)

    if Value == 0 then
        return 0
    else
        return Value < 0 and -1 or 1
    end

end

------------------------------------------------------------------------------------------------------------------------

function math.xor(P, Q)

    return (P or Q) and not (P and Q)

end

------------------------------------------------------------------------------------------------------------------------

math.mininteger = -9223372036854775808
math.maxinteger = 9223372036854775807

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

function string.split(str, delim, maxNb)

    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end

    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end

    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos

    for part, pos in string.gmatch(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end

    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end

    return result

end


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

function debug.printCallStack()

    local DebugLines = string.split(debug.traceback(), "\n", 1000)
    for _, DebugLine in pairs(DebugLines) do

        print (DebugLine)

    end

end

------------------------------------------------------------------------------------------------------------------------
-- table helpers
------------------------------------------------------------------------------------------------------------------------

function table.copy(Table)

    if type(Table) ~= "table" then return Table end
    local Meta = getmetatable(Table)
    local Target = {}

    for k, v in pairs(Table) do
        if type(v) == "table" then
            Target[k] = table.copy(v)
        else
            Target[k] = v
        end
    end

    setmetatable(Target, Meta)
    return Target

end

------------------------------------------------------------------------------------------------------------------------
-- see if the table contains an element
------------------------------------------------------------------------------------------------------------------------

function table.contains(Table, Value)

    for _, Element in ipairs(Table) do

        if Element == Value then
            return true
        end

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------
-- find key in table, nil otherwise
------------------------------------------------------------------------------------------------------------------------

function table.findKey(Table, Value)

    for Index, _Value in ipairs(Table) do

        if Value == _Value then
            return Index
        end

    end
end

------------------------------------------------------------------------------------------------------------------------
