------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SamplePrehearController = class( 'SamplePrehearController' )

------------------------------------------------------------------------------------------------------------------------

function SamplePrehearController:__init()
end

------------------------------------------------------------------------------------------------------------------------

function SamplePrehearController:playLastDatabaseBrowserSelection()

    NI.DATA.SamplePrehearAccess.playLastDatabaseBrowserSelection(App)

end
