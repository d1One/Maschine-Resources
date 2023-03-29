------------------------------------------------------------------------------------------------------------------------
-- The base page that displays parameter values.
------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/KompleteKontrolS/Pages/ParameterPageBase"

local class = require 'Scripts/Shared/Helpers/classy'
ParameterPageSound = class( 'ParameterPageSound', ParameterPageBase )


------------------------------------------------------------------------------------------------------------------------
-- Init
------------------------------------------------------------------------------------------------------------------------

function ParameterPageSound:__init(Controller)

    ParameterPageBase.__init(self, Controller)

end

------------------------------------------------------------------------------------------------------------------------
-- (ParameterPageBase)
------------------------------------------------------------------------------------------------------------------------

function ParameterPageSound:updateScreen()

    self.NumPages = MaschineHelper.getFocusedSoundSlotNumParameterPages()

    self:setFocusPage(MaschineHelper.getFocusedSoundSlotParameterPage() + 1)

    HELPERS.resetCachedParameters(App)

    local FocusSlot = MaschineHelper.getFocusedSoundSlot()
    if FocusSlot then
        for Index = 0, 7 do
            HELPERS.setCachedParameter(App, Index, MaschineHelper.getFocusedSoundSlotParameter(Index))
        end
    else
        local Screen = NHLController:getScreen()

        self:clearScreen()

        Screen:setText(4, SCREEN.DISPLAY_FIRST_ROW, "PRESS")
        Screen:setTextAlignment(4, 0, SCREEN.ALIGN_RIGHT)
        Screen:setText(5, SCREEN.DISPLAY_FIRST_ROW, "BROWSE")
        Screen:setTextAlignment(5, 0, SCREEN.ALIGN_LEFT)
    end

    ParameterPageBase.updateScreen(self)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageSound:isAutoWriting()

    return NI.DATA.WORKSPACE.isAutoWriteEnabledFromKompleteKontrol(App) and
        MaschineHelper.isPlaying()

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageSound:onPageButton(Pressed, Next)

    ParameterPageBase.onPageButton(self, Pressed, Next)

    if Pressed and not self.Controller:isShiftPressed() then
        MaschineHelper.offsetFocusedSoundSlotParameterPage(Next)
    end

end
