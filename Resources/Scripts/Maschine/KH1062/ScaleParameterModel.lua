local class = require 'Scripts/Shared/Helpers/classy'
ScaleParameterModel = class( 'ScaleParameterModel' )

------------------------------------------------------------------------------------------------------------------------

function ScaleParameterModel:__init()

end

------------------------------------------------------------------------------------------------------------------------

function ScaleParameterModel:getFocusParameters()

    local ScaleEngine = NI.DATA.getScaleEngine(App)
    if not ScaleEngine then
        return {}
    end

    local ShouldShowAdditionalScaleParameters = not ScaleEngine:getChordModeIsChordSet()

    return {
        { Parameter = ScaleEngine:getRootNoteParameter() },
        { Parameter = ShouldShowAdditionalScaleParameters and ScaleEngine:getScaleBankParameter() or nil },
        { Parameter = ShouldShowAdditionalScaleParameters and ScaleEngine:getScaleParameter() or nil },
        { Parameter = ShouldShowAdditionalScaleParameters and NI.HW.getScaleEngineKeyModeParameter(App) or nil },
        { Parameter = ScaleEngine:getChordModeParameter() },
        { Parameter = ScaleEngine:getChordModeParameter():getValue() ~= 0 and ScaleEngine:getChordTypeAutomationParameter() or nil }
    }

end

------------------------------------------------------------------------------------------------------------------------

function ScaleParameterModel:getFocusPageNumber()

    return 1

end

------------------------------------------------------------------------------------------------------------------------

function ScaleParameterModel:getFocusPageCount()

    return 1

end