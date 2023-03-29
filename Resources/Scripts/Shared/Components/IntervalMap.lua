require "Scripts/Shared/Helpers/MiscHelper" -- for math extensions

------------------------------------------------------------------------------------------------------------------------

local function upperBound(Data, Key)

    for Index, Entry in pairs(Data) do
       if Entry[1] > Key then
            return Index
       end
    end

    return #Data + 1

end

------------------------------------------------------------------------------------------------------------------------

local function lowerBound(Data, Key)

    for Index, Entry in pairs(Data) do
       if Entry[1] >= Key then
            return Index
       end
    end

    return #Data + 1

end

------------------------------------------------------------------------------------------------------------------------
--[[
    The IntervalMap maps key intervals to a single value.

    An IntervalMap is never empty and it starts with an initial value that is mapped to the whole key interval. The keys
    are integer values, so the complete key interval is the closed interval [math.mininteger, math.maxinteger].

    By adding further key intervals to the map, existing intervals are replaced, split or extended. For every key
    there's always a value, e.g. when adding a value 'A' for the key interval from [1, 6), every key that is less than
    1 or greater than 5 maps to the initial value of the map. Every key from 1 to 5 maps to the value 'A'.

               ⎧
               ⎜ Initial Value, for Key < 1
               ⎜
    Map(Key) = ⎨ 'A'          , for Key >= 1 and Key < 6
               ⎜
               ⎜ Initial Value, for Key >= 6
               ⎩

    Adjacent intervals never share the same value. Whenever an interval is assigned, so that it shares the same value
    as the previous or next interval in the map, they're joined to a bigger interval.

    Example
    -------

    local map = IntervalMap("Hello")
    map:assign(1, 6, "World")

    print(map:at(0)) -- prints Hello
    for i = 1,5 do
        print(map:at(i)) -- prints World
    end
    print(map:at(6)) -- prints Hello

]]
local class = require 'Scripts/Shared/Helpers/classy'
IntervalMap = class( 'IntervalMap' )

------------------------------------------------------------------------------------------------------------------------

function IntervalMap:__init(InitialValue)

    --[[
        Internal data structure is based on tuples of the start key and the value. The tuples are ordered ascending
        based on the start key.

        Example
        -------

        local map = IntervalMap("Hello")
        map:assign(1, 6, "World")

        leads to the following internal structure:
        {{math.mininteger, "Hello"}, {1, "World"}, {6, "Hello"}}
    ]]
    self.Data = {{math.mininteger, InitialValue}}

end

------------------------------------------------------------------------------------------------------------------------
--[[
    Assign assigns the half-open interval [KeyBegin, KeyEnd) to Value.
]]
function IntervalMap:assign(KeyBegin, KeyEnd, Value)

    if KeyBegin >= KeyEnd then
        return
    end

    local Last = upperBound(self.Data, KeyEnd)
    local PrevVal = self.Data[Last - 1][2]
    if PrevVal ~= Value then
        table.insert(self.Data, Last, {KeyEnd, PrevVal})
    end

    local First = lowerBound(self.Data, KeyBegin)
    for Index = First, Last - 1 do
        table.remove(self.Data, First)
    end

    if First == 1 or self.Data[First - 1][2] ~= Value then
        table.insert(self.Data, First, {KeyBegin, Value})
    end

end

------------------------------------------------------------------------------------------------------------------------
--[[
    At returns the corresponding value for the interval to which the Key belongs.

    Note that there's always a value, because the whole key interval is at least covered by the initial value of the
    map.
]]
function IntervalMap:at(Key)

    return self.Data[upperBound(self.Data, Key) - 1][2]

end

------------------------------------------------------------------------------------------------------------------------
