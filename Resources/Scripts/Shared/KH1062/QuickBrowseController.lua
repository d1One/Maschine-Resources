local class = require 'Scripts/Shared/Helpers/classy'
QuickBrowseController = class( 'QuickBrowseController' )

function QuickBrowseController:__init()
end

------------------------------------------------------------------------------------------------------------------------

function QuickBrowseController:presetUp()

    NI.DATA.QuickBrowseAccess.loadPrevNextPreset(App, true)

end

------------------------------------------------------------------------------------------------------------------------

function QuickBrowseController:presetDown()

    NI.DATA.QuickBrowseAccess.loadPrevNextPreset(App, false)

end
