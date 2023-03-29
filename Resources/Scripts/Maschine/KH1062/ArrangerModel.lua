require "Scripts/Shared/Helpers/ArrangerHelper"
require "Scripts/Shared/Helpers/MaschineHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ArrangerModel = class( 'ArrangerModel' )

function ArrangerModel:__init()
end

------------------------------------------------------------------------------------------------------------------------

function ArrangerModel:isIdeaSpaceFocused()

    return ArrangerHelper.isIdeaSpaceFocused()

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerModel:isIdeaSpaceViewChanged()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local ArrangerState = Song and Song:getArrangerState()
    return ArrangerState and ArrangerState:isViewChanged() or false

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerModel:isIdeaSpaceFocused()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local ArrangerState = Song and Song:getArrangerState()
    return ArrangerState and ArrangerState:isIdeaSpaceFocused() or false

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerModel:isIdeaSpaceFocusChanged()

    return ArrangerHelper.isIdeaSpaceFocusChanged()

end
