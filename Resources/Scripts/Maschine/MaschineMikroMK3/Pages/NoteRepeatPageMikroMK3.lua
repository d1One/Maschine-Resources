------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
NoteRepeatPageMikroMK3 = class( 'NoteRepeatPageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function NoteRepeatPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "NoteRepeatPageMikroMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function NoteRepeatPageMikroMK3:updateScreen()

    self.Screen
        :setTopRowText("Note Repeat")
        :setBottomRowToFocusedPageParameter()

end

------------------------------------------------------------------------------------------------------------------------
