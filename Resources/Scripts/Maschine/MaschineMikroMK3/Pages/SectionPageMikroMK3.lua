------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"
require "Scripts/Shared/Helpers/ArrangerHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SectionPageMikroMK3 = class( 'SectionPageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function SectionPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "SectionPageMikroMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function SectionPageMikroMK3:onShow(Show)

    if Show then

        NHLController:setPadMode(NI.HW.PAD_MODE_SECTION)
        ArrangerHelper.updatePadLEDsSections(self.Controller.PAD_LEDS)

    else

        ArrangerHelper.resetHoldingPads()

    end

    PageMikroMK3.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function SectionPageMikroMK3:updateScreen()

    local Section = NI.DATA.StateHelper.getFocusSection(App)
    self.Screen:setTopRowText(Section and "Section "..ArrangerHelper.getFocusedSectionSongPosAsString()
        or "No Section")

    local FocusedParameter = NHLController:focusedParameter()

    if not FocusedParameter or NI.DATA.StateHelper.getFocusSection(App) == nil then
        self.Screen:setParameterName("")
        self.Screen:setParameterValue("")
        return
    end

    self.Screen:showParameterInBottomRow()
               :setParameterName(FocusedParameter:name())

    if FocusedParameter:name() == "Position" then

        self.Screen:setParameterValue(ArrangerHelper.getFocusedSectionSongPosAsString())

    elseif FocusedParameter:name() == "Scene" then

        self.Screen:setParameterValue(ArrangerHelper.getSceneReferenceParameterValue())

    elseif FocusedParameter:name() == "Length" then

        self.Screen:setParameterValue(ArrangerHelper.getFocusSectionLengthString())

    elseif FocusedParameter:name() == "Bank" then

        self.Screen:setSectionBankParameter()

    else

        self.Screen:setBottomRowToFocusedPageParameter()

    end

end

------------------------------------------------------------------------------------------------------------------------

function SectionPageMikroMK3:onPadEvent(PadIndex, Trigger, PadValue)

    local DeleteSection = self.Controller:isErasePressed()
    local CreateSectionIfEmpty = true
    ArrangerHelper.onPadEventSections(PadIndex, Trigger, DeleteSection, CreateSectionIfEmpty)

end

------------------------------------------------------------------------------------------------------------------------

function SectionPageMikroMK3:updatePadLEDs()

    ArrangerHelper.updatePadLEDsSections(self.Controller.PAD_LEDS)

end

------------------------------------------------------------------------------------------------------------------------
