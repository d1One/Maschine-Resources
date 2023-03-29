require "Scripts/Shared/KH1062/Pages/KH1062Page"

require "Scripts/Maschine/KH1062/DataController"
require "Scripts/Maschine/KH1062/DataModel"

require "Scripts/Shared/Components/ScreenMikroASeriesBase"
require "Scripts/Shared/Helpers/LedHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
QuickEditPage = class( 'QuickEditPage', KH1062Page )

------------------------------------------------------------------------------------------------------------------------

function QuickEditPage:__init(PageName, ScreenStack, Environment, SwitchHandler)

    KH1062Page.__init(self, ScreenMikroASeriesBase(PageName, ScreenStack, Environment), SwitchHandler)

    self.DataController = Environment.DataController
    self.DataModel = Environment.DataModel
    self.LedController = Environment.LedController

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditPage:setupScreen()

    KH1062Page.setupScreen(self)

    self.Screen:showParameterInBottomRow()
               :setTopRowTextAttribute("bold")

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditPage:onShow(Show)

    KH1062Page.onShow(self, Show)

    if Show then
        self.LedController:setLEDState(NI.HW.LED_LEFT, LEDHelper.LS_OFF)
        self.LedController:setLEDState(NI.HW.LED_RIGHT, LEDHelper.LS_OFF)
    end

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditPage:onWheel(Delta)

    local IsFineIncrement = self.isShiftPressed()
    self.DataController:incrementSongTempo(Delta, IsFineIncrement)

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditPage:updateScreen()

    self.Screen:setTopRowIcon("labelBoldCenter", "M")
    self.Screen:setTopRowText(self.DataModel:getCurrentProjectDisplayName())

    self.Screen:setParameterName("Tempo")
               :setParameterValue(self.DataModel:getSongTempoString())

end
