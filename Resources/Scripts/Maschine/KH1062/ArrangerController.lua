require "Scripts/Shared/Helpers/ArrangerHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ArrangerController = class( 'ArrangerController' )

function ArrangerController:__init()
end

------------------------------------------------------------------------------------------------------------------------

function ArrangerController:jumpToIdeaSpace()

    NI.DATA.TransportAccess.jumpToSpace(App, true)

end
