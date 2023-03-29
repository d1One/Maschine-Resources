------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
FilePageMikroMK3 = class( 'FilePageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function FilePageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "FilePageMikroMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function FilePageMikroMK3:updateScreen()

    local NumFiles = NI.APP.getRecentFilesSize()
    local FocusedItem = NHLController:getContext():mikroMk3():recentProjectsFocusedItem()

    self.Screen
        :setTopRowText("Recent")
        :setBottomRowText(NumFiles > 0 and NI.APP.getRecentFilenameAt(FocusedItem) or "No Projects")
        :updateScrollbar(NumFiles, FocusedItem)

end

------------------------------------------------------------------------------------------------------------------------
