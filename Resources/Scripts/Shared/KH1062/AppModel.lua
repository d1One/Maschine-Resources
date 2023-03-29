------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
AppModel = class( 'AppModel' )

------------------------------------------------------------------------------------------------------------------------

function AppModel:__init()
end

------------------------------------------------------------------------------------------------------------------------

function AppModel:getBusyState()

    return App:getBusyState()

end

------------------------------------------------------------------------------------------------------------------------

function AppModel:isBusy()

    return App:isBusy()

end

------------------------------------------------------------------------------------------------------------------------

function AppModel:isStandalone()

    return NI.APP.isStandalone()

end

------------------------------------------------------------------------------------------------------------------------

function AppModel:getDatabaseScanInProgressParameter()

    return App:getWorkspace():getDatabaseScanInProgressParameter()

end

------------------------------------------------------------------------------------------------------------------------

function AppModel:isNoHardwareService()

    return NI.APP.isNoHardwareService()

end
