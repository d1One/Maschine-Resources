------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/ScreenHelper"

------------------------------------------------------------------------------------------------------------------------
-- ScreenBase
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ScreenBase = class( 'ScreenBase' )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ScreenBase:__init(Page)

    -- init page
    self.Page = Page

    -- setup NHL Interface
    self.Controller = Page.Controller

    -- setup screen gui
    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------
-- updateGroupBank
-- make sure GroupBank is not pointing to some outdated value after Groups updates
------------------------------------------------------------------------------------------------------------------------

function ScreenBase:updateGroupBank(Page)

    if Page and Page.Screen and Page.Screen.GroupBank and Page.Screen.GroupBank >= 0 then

        local StateCache = App:getStateCache()
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local Groups = Song and Song:getGroups() or nil

        if NI.DATA.ParameterCache.isValid(App) and StateCache:isFocusGroupChanged() and
            (Groups and Groups:isSizeChanged()) then

            Page.Screen.GroupBank = math.floor(NI.DATA.StateHelper.getFocusGroupIndex(App) / 8)

        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function ScreenBase:update(ForceUpdate)
end

------------------------------------------------------------------------------------------------------------------------

function ScreenBase:onTimer(ForceUpdate)
end

------------------------------------------------------------------------------------------------------------------------

