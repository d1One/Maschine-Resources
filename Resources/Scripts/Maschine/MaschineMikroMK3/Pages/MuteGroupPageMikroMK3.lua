------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"

require "Scripts/Maschine/Helper/MuteSoloHelper"
require "Scripts/Maschine/MaschineMikroMK3/Helpers/MuteSoloHelperMikroMK3"
require "Scripts/Maschine/MaschineMikroMK3/Helpers/GroupPadHelperMikroMK3"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MuteGroupPageMikroMK3 = class( 'MuteGroupPageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function MuteGroupPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "MuteGroupPageMikroMK3", Controller)
    self.LastPressedPadIndex = nil

end

------------------------------------------------------------------------------------------------------------------------

function MuteGroupPageMikroMK3:onShow(Show)

    self.LastPressedPadIndex = nil

    PageMikroMK3.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function MuteGroupPageMikroMK3:updateScreen()

    MuteSoloHelperMikroMK3.setTopLineGroup(self, self.LastPressedPadIndex)
    self.Screen:setBottomRowText("")

end

------------------------------------------------------------------------------------------------------------------------

function MuteGroupPageMikroMK3:onPadEvent(PadIndex, Trigger, _)

    if not Trigger then
        return
    end

    local GroupIndex = GroupPadHelperMikroMK3.setFocusGroupByPad(self, PadIndex)

    if GroupIndex == nil then
        return
    end

    local MuteGroupFunction =
    function(_, Group)
        local MuteParameter = Group:getMuteParameter()
        NI.DATA.ParameterAccess.setBoolParameter(App, MuteParameter, not MuteParameter:getValue())
    end

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups() or nil

    MaschineHelper.callFunctionWithObjectVectorAndItemByIndex(Groups, GroupIndex, MuteGroupFunction)
    self.LastPressedPadIndex = GroupIndex

end

------------------------------------------------------------------------------------------------------------------------

function MuteGroupPageMikroMK3:updatePadLEDs()

    MuteSoloHelperMikroMK3.updateGroupPadLeds(self)

end

------------------------------------------------------------------------------------------------------------------------