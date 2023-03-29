------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"
require "Scripts/Maschine/Helper/DuplicateHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
DuplicateSectionPageMikroMK3 = class( 'DuplicateSectionPageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function DuplicateSectionPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "DuplicateSectionPageMikroMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateSectionPageMikroMK3:setupScreen()

    PageMikroMK3.setupScreen(self)
    self.Screen:showParameterInBottomRow()

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateSectionPageMikroMK3:onShow(Show)

    self:reset()
    PageMikroMK3.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateSectionPageMikroMK3:reset()

    self.Mode = DuplicateHelper.SECTION
    self.SourceIndex = -1
    self.SourceGroupIndex = -1

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateSectionPageMikroMK3:updateScreen()

    local Section = NI.DATA.StateHelper.getFocusSection(App)
    self.Screen:setTopRowText(Section and "Dupl. Section "..ArrangerHelper.getFocusedSectionSongPosAsString()
        or "No Section")
    self.Screen:setSectionBankParameter()

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateSectionPageMikroMK3:onPadEvent(PadIndex, Trigger)

    if not Trigger then
        return
    end

    DuplicateHelper.onPadEvent(self, PadIndex)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateSectionPageMikroMK3:updatePadLEDs()

    DuplicateHelper.updatePadLEDs(self, self.Controller.PAD_LEDS, self.SourceIndex >= 0)

end

------------------------------------------------------------------------------------------------------------------------
