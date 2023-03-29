------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Maschine/Pages/SnapshotsPage"
require "Scripts/Maschine/MaschineStudio/Screens/ScreenWithGridStudio"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SnapshotsPageStudio = class( 'SnapshotsPageStudio', SnapshotsPage )

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPageStudio:__init(Controller)

    PageMaschine.__init(self, "SnapshotsPageStudio", Controller)

    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPageStudio:setupScreen()

    self.Screen = ScreenWithGridStudio(self, {"", "", "", "EXT LOCK"}, {"UPDATE", "DELETE", "<<", ">>"},
                                       "HeadButton", "HeadButton")

    local ParamBar = NI.GUI.insertBar(self.Screen.ScreenLeft, "ParamBar")
    ParamBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "ParamBar")
    self.Screen:addParameterBar(ParamBar)

    self.Screen.ScreenButton[4]:setSelected(true)

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPageStudio:updateParameters(ForceUpdate)

    SnapshotsPage.updateParameters(self, ForceUpdate)

    self.Controller.CapacitiveList:assignParametersToCaps(self.ParameterHandler.Parameters)

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPageStudio:updateScreenButtons(ForceUpdate)

    local BankIndex = NI.DATA.ParameterSnapshotsAccess.getFocusSnapshotBankIndex(App)
    self.Screen:setArrowText(1, "BANK "..tostring(BankIndex + 1))

    SnapshotsPage.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPageStudio:updateScreens(ForceUpdate)

    SnapshotsPage.updateScreens(self, ForceUpdate)

    -- iterate over pad Widgets
    for _, Button in ipairs (self.Screen.PadButtons) do
        Button:setPaletteColorIndex(0) -- white
        Button.Label:setPaletteColorIndex(0) -- white
        Button:setInvalid(0) -- This is needed for MAS2-4712
    end

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPageStudio:onPadEvent(PadIndex, Trigger, PadValue)

    if not Trigger then
        return
    end

    self:createOrDeleteSnapshot(PadIndex)

    return true

end

------------------------------------------------------------------------------------------------------------------------
