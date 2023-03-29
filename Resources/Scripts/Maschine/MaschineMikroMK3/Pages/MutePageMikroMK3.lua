------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"

require "Scripts/Maschine/Helper/MuteSoloHelper"
require "Scripts/Maschine/MaschineMikroMK3/Helpers/MuteSoloHelperMikroMK3"
require "Scripts/Maschine/MaschineMikroMK3/Helpers/GroupPadHelperMikroMK3"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MutePageMikroMK3 = class( 'MutePageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function MutePageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "MutePageMikroMK3", Controller)
    self.LastPressedPadIndex = nil

end

------------------------------------------------------------------------------------------------------------------------

function MutePageMikroMK3:onShow(Show)

    self.LastPressedPadIndex = nil

    PageMikroMK3.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function MutePageMikroMK3:updateScreen()

    MuteSoloHelperMikroMK3.setTopLineSound(self, self.LastPressedPadIndex)
    self.Screen:setBottomRowText("")

end

------------------------------------------------------------------------------------------------------------------------

function MutePageMikroMK3:onPadEvent(PadIndex, Trigger)

    if not Trigger then
        return
    end

    MuteSoloHelper.toggleSoundMuteState(PadIndex)
    self.LastPressedPadIndex = PadIndex

end

------------------------------------------------------------------------------------------------------------------------

function MutePageMikroMK3:updatePadLEDs()

    MuteSoloHelperMikroMK3.updateSoundPadLeds(self)

end

------------------------------------------------------------------------------------------------------------------------