
local class = require 'Scripts/Shared/Helpers/classy'
BrowseUtils = class( 'BrowseUtils' )

function BrowseUtils.advanceIndex(FocusItem, Delta, ItemCount, CanDeselect)

    local LowerLimit = CanDeselect and -1 or 0

    return math.bound(FocusItem + Delta, LowerLimit, ItemCount - 1)

end

------------------------------------------------------------------------------------------------------------------------

function BrowseUtils.splitStringLargerThan8(ValueString)

    local FirstRow = ValueString
    local SecondRow = ""

    if string.len(ValueString) > 8 then
        local VisibleString = ""
        VisibleString = string.sub(ValueString, 1, 8)
        if string.sub(ValueString, 9, 9) == " " then
          FirstRow = VisibleString;
          SecondRow = string.sub(ValueString, 10, -1)
          return FirstRow, SecondRow
        end

        local Index = VisibleString:match'^.*() '
        -- if no space in the 8 long string check the entire string
        if not Index then
            local i = string.find(ValueString, " ", 1, -1)
            if not i then
                -- if no space is found in the string then add the entire string
                FirstRow = ValueString
            else
                FirstRow = string.sub(ValueString, 0, i)
                SecondRow = string.sub(ValueString, i + 1, -1)
            end
            return FirstRow, SecondRow
        end

        FirstRow = string.sub(VisibleString, 1, Index)
        if Index <= 8 then
            SecondRow = string.sub(ValueString, Index + 1, -1)
        end
    end

    return FirstRow, SecondRow

end

---------------------------------------------------------------------------------------------------------------------

function BrowseUtils.getMeterPosition(CurrentValue, MaxValue)

    -- check if provided values are valid
    if MaxValue <= 0 or CurrentValue < 0 or CurrentValue > MaxValue then
        return 0
    else
        return CurrentValue / MaxValue
    end

end