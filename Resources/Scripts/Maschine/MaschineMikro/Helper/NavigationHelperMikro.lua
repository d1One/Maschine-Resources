------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Helper/ViewHelper"
require "Scripts/Maschine/Helper/NavigationHelper"
require "Scripts/Shared/Helpers/PadModeHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
NavigationHelperMikro = class( 'NavigationHelperMikro' )

------------------------------------------------------------------------------------------------------------------------

function NavigationHelperMikro.scrollHorizontally(Fine, Direction, IsArranger, ParameterIndex, ParameterHandler)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    if Group == nil then
        return
    end

    local Increment = 0.04 * Direction      -- 0.04 is arbitrary

    if IsArranger then
        ViewHelper.scrollArranger(Increment, Fine)
        return
    end

    if NavigationHelper.isClipEditorVisible() then
        ViewHelper.scrollClipEditor(Increment, Fine)
    elseif NavigationHelper.isPatternEditorVisible() then
        ViewHelper.scrollPatternEditor(Increment, Fine)
    elseif NavigationHelper.isZoneMapVisible() then
        local Param = ParameterHandler.Parameters[ParameterIndex]
        if Param then
            NI.DATA.ParameterAccess.addParameterWheelDelta(App, Param, Direction * 50, Fine, ParameterHandler.Undoable)
        end
    elseif NavigationHelper.isSamplingVisible() then
        SamplingHelper.scrollWaveForm(Increment, Fine, false)
    end

end

------------------------------------------------------------------------------------------------------------------------

function NavigationHelperMikro.zoomHorizontally(Fine, Direction, IsArranger, ParameterIndex, ParameterHandler)

    local Increment = 0.04 * Direction      -- 0.04 is arbitrary

    if IsArranger then
        ViewHelper.zoomArranger(Increment, Fine)
        return
    end

    if NavigationHelper.isClipEditorVisible() then
        ViewHelper.zoomClipEditor(Increment, Fine)
    elseif NavigationHelper.isPatternEditorVisible() then
        ViewHelper.zoomPatternEditor(Increment, Fine)
    elseif NavigationHelper.isZoneMapVisible() then
        local Param = ParameterHandler.Parameters[ParameterIndex]
        if Param then
            NI.DATA.ParameterAccess.addParameterWheelDelta(App, Param, Direction, Fine, ParameterHandler.Undoable)
        end
    else -- Wave
        SamplingHelper.zoomWaveForm(Increment, Fine, false)
    end

end

------------------------------------------------------------------------------------------------------------------------

function NavigationHelperMikro.scrollVertically(Fine, Direction)

    local Param = (function ()
        if (NavigationHelper.isPatternEditorVisible() or NavigationHelper.isClipEditorVisible())
           and PadModeHelper.getKeyboardMode() then
            local Sound = NI.DATA.StateHelper.getFocusSound(App)
            return Sound and Sound:getPianorollOffsetYParameter() or nil
        elseif NavigationHelper.isZoneMapVisible() then
            local Sampler = NI.DATA.StateHelper.getFocusSampler(App, nil)
            return Sampler and Sampler:getZoneEditorScrollYParameter() or nil
        end
    end)()
    if not Param then
        return
    end

    local ParamMax = Param:getMax()
    local ParamMin = Param:getMin()
    local Value = Param:getValue() + (ParamMax-ParamMin)/Param:getNumSteps() * Direction * (Fine and 0.1 or 1)
    Value = math.bound(Value, ParamMin, ParamMax)
    NI.DATA.ParameterAccess.setSizeTParameter(App, Param, Value)

end

------------------------------------------------------------------------------------------------------------------------
