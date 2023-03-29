------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/MaschineHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MacroHelper = class( 'MacroHelper' )

------------------------------------------------------------------------------------------------------------------------

function MacroHelper.leaveMacroPageGroup()

    local PageGroupParam = App:getWorkspace():getPageGroupParameter()
    if PageGroupParam:getValue() > 0 then
        NI.DATA.ParameterAccess.setEnumParameterNoUndo(App, PageGroupParam, PageGroupParam:getValue() - 1)
        App:getWorkspace():savePageGroupState()
    end

    -- Need to clear the page stack before proceeding with Macro page, details here MAS2-7731
    NHLController:getPageStack():pushPage(NI.HW.PAGE_CONTROL)

    local ModsVisibleParam = App:getWorkspace():getModulesVisibleParameter()
    NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, ModsVisibleParam, false)
    App:getWorkspace():saveModulesVisibleState()

end

------------------------------------------------------------------------------------------------------------------------

