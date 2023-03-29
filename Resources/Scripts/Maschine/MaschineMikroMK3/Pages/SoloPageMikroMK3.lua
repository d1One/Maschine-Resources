------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"

require "Scripts/Maschine/Helper/MuteSoloHelper"
require "Scripts/Maschine/MaschineMikroMK3/Helpers/MuteSoloHelperMikroMK3"
require "Scripts/Maschine/MaschineMikroMK3/Helpers/GroupPadHelperMikroMK3"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SoloPageMikroMK3 = class( 'SoloPageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function SoloPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "SoloPageMikroMK3", Controller)
    self.LastPressedPadIndex = nil

end

------------------------------------------------------------------------------------------------------------------------

function SoloPageMikroMK3:onShow(Show)

    self.LastPressedPadIndex = nil

    PageMikroMK3.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function SoloPageMikroMK3:updateScreen()

    local IsGroup = false
    MuteSoloHelperMikroMK3.setTopLineSound(self, self.LastPressedPadIndex)
    self.Screen:setBottomRowText("")

end

------------------------------------------------------------------------------------------------------------------------

function SoloPageMikroMK3:onPadEvent(PadIndex, Trigger)

    if not Trigger then
        return
    end

    MuteSoloHelper.toggleSoundSoloState(PadIndex)
    self.LastPressedPadIndex = PadIndex

end

------------------------------------------------------------------------------------------------------------------------

function SoloPageMikroMK3:updatePadLEDs()

    MuteSoloHelperMikroMK3.updateSoundPadLeds(self)

end

------------------------------------------------------------------------------------------------------------------------