------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/PadModeHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
InfoBarHelper = class( 'InfoBarHelper' )

------------------------------------------------------------------------------------------------------------------------

function InfoBarHelper.getRootNote()

    local ScaleEngine = NI.DATA.getScaleEngine(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local RootNoteParam = Group and Group:getRootNoteParameter() or nil

    if not RootNoteParam or not ScaleEngine then

        return ""

    end

    return ScaleEngine:getRootNoteName(RootNoteParam:getValue())

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarHelper.getBaseKey()

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local BaseKeyString = ""

    if Sound and NI.DATA.StateHelper.getIsBaseKeyMultiSelection(App) then

        BaseKeyString = "MULTI"

    elseif Sound then

        BaseKeyString = Sound:getBaseKeyParameter():getValueString()

    end

    return BaseKeyString

end

------------------------------------------------------------------------------------------------------------------------

function InfoBarHelper.getBaseKeyOffset()

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local BaseKeyOffsetString = ""

    if not Sound then

        return BaseKeyOffsetString

    end

    local BaseKeyParam = Sound:getBaseKeyParameter()
    local Value = BaseKeyParam:getValue()

    if Value < BaseKeyParam:getMax() and Value > BaseKeyParam:getMin() then

        BaseKeyOffsetString = string.format("%+d", PadModeHelper.BaseKeyOffset)

    else

        PadModeHelper.BaseKeyOffset = 0

    end

    return BaseKeyOffsetString

end

------------------------------------------------------------------------------------------------------------------------

