local class = require 'Scripts/Shared/Helpers/classy'
ArpParameterController = class( 'ArpParameterController' )

------------------------------------------------------------------------------------------------------------------------

function ArpParameterController:__init(ArpParameterModel)

    self.ArpParameterModel = ArpParameterModel

end

------------------------------------------------------------------------------------------------------------------------

function ArpParameterController:incrementFocusPage()

    if self.ArpParameterModel:getFocusPageNumber() < self.ArpParameterModel:getFocusPageCount() then
        self.ArpParameterModel.CurrentPageIndex = self.ArpParameterModel.CurrentPageIndex + 1
    end

end

------------------------------------------------------------------------------------------------------------------------

function ArpParameterController:decrementFocusPage()

    if self.ArpParameterModel:getFocusPageNumber() > 1 then
        self.ArpParameterModel.CurrentPageIndex = self.ArpParameterModel.CurrentPageIndex - 1
    end

end