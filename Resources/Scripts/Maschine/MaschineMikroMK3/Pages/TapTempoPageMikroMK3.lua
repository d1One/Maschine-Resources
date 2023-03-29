------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"
require "Scripts/Shared/Helpers/StepHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
TapTempoPageMikroMK3 = class( 'TapTempoPageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function TapTempoPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "TapTempoPageMikroMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function TapTempoPageMikroMK3:updateScreen()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Tempo = Song and Song:getTempoParameter()

    self.Screen
        :setTopRowText("Tempo")
        :setTopRowTextAttribute("boldCenter")
        :setBottomRowText(Tempo and (Tempo:getValueString().." BPM" or ""))
        :setBottomRowTextAttribute("boldCenter")

end

------------------------------------------------------------------------------------------------------------------------