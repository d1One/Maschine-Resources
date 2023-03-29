------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ScaleArpDataModel = class( 'ScaleArpDataModel' )

------------------------------------------------------------------------------------------------------------------------

function ScaleArpDataModel:__init()
end

------------------------------------------------------------------------------------------------------------------------

function ScaleArpDataModel:getScaleParameterState()

    local ActiveParam = NI.HW.getScaleEngineActiveParameter(App)
    return ActiveParam and ActiveParam:getValue() or false

end

------------------------------------------------------------------------------------------------------------------------

function ScaleArpDataModel:setScaleParameterState(ScaleState)

    local ActiveParam = NI.HW.getScaleEngineActiveParameter(App)
    NI.DATA.ParameterAccess.setBoolParameter(App, ActiveParam, ScaleState)

end

------------------------------------------------------------------------------------------------------------------------

function ScaleArpDataModel:getArpeggiatorParameterState()

    local ActiveParam = NI.HW.getArpeggiatorActiveParameter(App)
    return ActiveParam and ActiveParam:getValue() or false

end

------------------------------------------------------------------------------------------------------------------------

function ScaleArpDataModel:setArpeggiatorParameterState(ArpState)

    local ActiveParam = NI.HW.getArpeggiatorActiveParameter(App)
    NI.DATA.ParameterAccess.setBoolParameter(App, ActiveParam, ArpState)

end

------------------------------------------------------------------------------------------------------------------------
