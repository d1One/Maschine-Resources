------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/Pages/SaveDialogPageBase"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SaveDialogPage = class( 'SaveDialogPage', SaveDialogPageBase )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SaveDialogPage:__init(Controller)

    SaveDialogPageBase.__init(self, Controller, "SaveDialogPage")

end

------------------------------------------------------------------------------------------------------------------------

function SaveDialogPage:setupScreen()

    SaveDialogPageBase.setupScreen(self)

    self.LeftLabel:setText("Save Project")
    self.RightLabel:setText("Do you want to save?")

end
