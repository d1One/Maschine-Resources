------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/Pages/SaveDialogPageBase"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SaveDialogPageStudio = class( 'SaveDialogPageStudio', SaveDialogPageBase )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SaveDialogPageStudio:__init(Controller)

    SaveDialogPageBase.__init(self, Controller, "SaveDialogPageStudio")

end

------------------------------------------------------------------------------------------------------------------------

function SaveDialogPageStudio:setupScreen()

    SaveDialogPageBase.setupScreen(self)

    self.LeftText = "Save Project"
    self.RightText = "The project was modified. Do you want to save it?"

    self.LeftLabel:setText(self.LeftText)
    self.RightLabel:setText(self.RightText)

end

------------------------------------------------------------------------------------------------------------------------

function SaveDialogPageStudio:getAccessiblePageInfo()

    return self.LeftText..", "..self.RightText.." Button 5 Cancel, 7 Discard, 8 Save"

end

------------------------------------------------------------------------------------------------------------------------
