------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
GridHelper = class( 'GridHelper' )

------------------------------------------------------------------------------------------------------------------------
-- CONSTS
------------------------------------------------------------------------------------------------------------------------

GridHelper.PERFORM   = 1
GridHelper.ARRANGER   = 2
GridHelper.STEP      = 3

GridHelper.LastPerformGridValue = 1

------------------------------------------------------------------------------------------------------------------------

function GridHelper.getSnapParameter(GridMode)

	local Song = NI.DATA.StateHelper.getFocusSong(App)

	if GridMode == GridHelper.PERFORM then

		return Song and Song:getPerformGridParameter() or nil

	elseif GridMode == GridHelper.ARRANGER then

		return Song and Song:getArrangeGridParameter() or nil

	elseif GridMode == GridHelper.STEP then

		return Song and Song:getPatternEditorSnapParameter() or nil

	end

    return nil

end

------------------------------------------------------------------------------------------------------------------------

function GridHelper.getNudgeSnapParameter()

	local Song = NI.DATA.StateHelper.getFocusSong(App)

	return Song and Song:getPatternEditorNudgeSnapParameter() or nil

end

------------------------------------------------------------------------------------------------------------------------

function GridHelper.isSnapEnabled(GridMode)

	local Song = NI.DATA.StateHelper.getFocusSong(App)

	if GridMode == GridHelper.PERFORM then

		return Song and Song:getPerformGridParameter():getValue() ~= 0 or false

    elseif GridMode == GridHelper.ARRANGER then

        return Song and Song:getArrangeGridSnapParameter():getValue() or false

    elseif GridMode == GridHelper.STEP then

        local SnapEnabledParam = GridHelper.getSnapEnabledParameter(GridMode)
        return SnapEnabledParam and SnapEnabledParam:getValue() or false

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function GridHelper.getSnapEnabledParameter(GridMode)

	local Song = NI.DATA.StateHelper.getFocusSong(App)

	if GridMode == GridHelper.STEP then

		return Song and Song:getPatternEditorSnapEnabledParameter() or nil

	elseif GridMode == GridHelper.ARRANGER then

		return Song and Song:getArrangeGridSnapParameter() or nil
	end

    return nil

end

------------------------------------------------------------------------------------------------------------------------

function GridHelper.toggleSnapEnabled(GridMode)

	local Song = NI.DATA.StateHelper.getFocusSong(App)

	if GridMode == GridHelper.PERFORM then

        if GridHelper.isSnapEnabled(GridMode) then

            GridHelper.LastPerformGridValue = Song:getPerformGridParameter():getValue()
            NI.DATA.ParameterAccess.setEnumParameter(App, Song:getPerformGridParameter(), 0)
        else

            NI.DATA.ParameterAccess.setEnumParameter(
                App, Song:getPerformGridParameter(), GridHelper.LastPerformGridValue)
        end

    else

	    local SnapEnabledParam = GridHelper.getSnapEnabledParameter(GridMode)

	    if SnapEnabledParam then
		    NI.DATA.ParameterAccess.setBoolParameter(
                App, SnapEnabledParam, not SnapEnabledParam:getValue())
	    end

	end

end

------------------------------------------------------------------------------------------------------------------------

function GridHelper.getQuickEnabledParameter()

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    return Song and Song:getPatternLengthQuickParameter() or nil

end

------------------------------------------------------------------------------------------------------------------------

function GridHelper.isQuickEnabled()

    local Quick = GridHelper.getQuickEnabledParameter()

    return Quick and Quick:getValue()

end

------------------------------------------------------------------------------------------------------------------------

function GridHelper.setQuickEnabled(Value)

    local Quick = GridHelper.getQuickEnabledParameter()

    if Quick then
        NI.DATA.ParameterAccess.setBoolParameter(
            App, Quick, Value)
    end

end

------------------------------------------------------------------------------------------------------------------------

function GridHelper.getQuickEnabledAsString(GridMode)

    local Quick = GridHelper.getQuickEnabledParameter()

    if Quick and GridMode == GridHelper.ARRANGER and GridHelper.isSnapEnabled(GridMode) then
        return Quick:getValue() and "On" or "Off"
    end

    return "-"

end


------------------------------------------------------------------------------------------------------------------------

