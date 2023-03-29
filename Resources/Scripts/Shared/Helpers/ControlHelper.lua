------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/ModuleHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ControlHelper = class( 'ControlHelper' )


------------------------------------------------------------------------------------------------------------------------

function ControlHelper.setPluginMode(Value)

    local ModulesVisibleParameter = App:getWorkspace():getModulesVisibleParameter()
    NI.DATA.ParameterAccess.setBoolParameter(App, ModulesVisibleParameter, Value)

end

------------------------------------------------------------------------------------------------------------------------

function ControlHelper.setPageParameter(Page)

    local StateCache = App:getStateCache()
    local ParamCache = StateCache:getParameterCache()
    local NumPages = ParamCache:getNumPagesOfFocusParameterOwner()
    local PageParameter = ParamCache:getPageParameter()

    if PageParameter then
        local Value = Page - 1
        if Value < NumPages then
            NI.DATA.ParameterAccess.setSizeTParameter(App, PageParameter, Value)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function ControlHelper.setFocusSlotIndex(SlotIndex)

    local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)
    if Slots then
        -- Focus Slot
        local Slot = Slots:at(SlotIndex - 1)
        if Slot then
            NI.DATA.ChainAccess.setFocusSlot(App, Slots, Slot, false)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function ControlHelper.togglePluginWindow()

    local FocusSlot = NI.DATA.StateHelper.getFocusSlot(App)
    if FocusSlot then
        local Module = FocusSlot:getModule();
        if Module and Module:getInfo():getId() == NI.DATA.ModuleInfo.ID_PLUGINHOST then
            NI.DATA.PluginWindowAccess.togglePluginWindow(App, Module)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function ControlHelper.hasPrevNextSlotOrPageGroup(Next, ToMove, OmitNewSlot)

    local ChannelMode = not MaschineHelper:isShowingPlugins()

    if ChannelMode then

        local PageGroupParameter = App:getWorkspace():getPageGroupParameter()

        if Next then
			return PageGroupParameter:getValue() < PageGroupParameter:getMax()
		else
			return PageGroupParameter:getValue() > 0
		end

    elseif not ToMove then

        local Slots          = NI.DATA.StateHelper.getFocusChainSlots(App)
        local FocusSlotIndex = NI.DATA.StateHelper.getFocusSlotIndex(App)

        if Slots then

        	if Next then
                local MaxValue = OmitNewSlot == true and Slots:size() - 1 or Slots:size()
                return FocusSlotIndex < MaxValue and FocusSlotIndex >= 0
			else
				return Slots:size() > 0 and FocusSlotIndex ~= 0
			end
		end

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function ControlHelper.canMoveFocusSlot(Right)

	local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)
	local FocusSlot = Slots and Slots:getFocusObject()

	local DestIndex = NI.DATA.StateHelper.getFocusSlotIndex(App) + (Right and 1 or -1)
	local DestSlot = Slots and Slots:at(DestIndex) or nil

	return ModuleHelper.isSlotFX(FocusSlot) and ModuleHelper.isSlotFX(DestSlot)

end

------------------------------------------------------------------------------------------------------------------------

function ControlHelper.moveFocusSlot(Right)

	local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)
	local FocusSlot = Slots and Slots:getFocusObject()

	local NewIndex = NI.DATA.StateHelper.getFocusSlotIndex(App) + (Right and 2 or -1)
	NI.DATA.ChainAccess.moveSlot(App, Slots, FocusSlot, NewIndex)

end

------------------------------------------------------------------------------------------------------------------------

function ControlHelper.onPrevNextSlot(Next, Move)


    if ControlHelper.hasPrevNextSlotOrPageGroup(Next, Move) then

        local PluginMode = MaschineHelper:isShowingPlugins()

        if PluginMode then
            local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)
            if Slots then
                NI.DATA.ChainAccess.shiftSlotFocus(App, Slots, Next and 1 or -1)
            end

        else

            local PageGroupParam = App:getWorkspace():getPageGroupParameter()
            local NewValue = math.bound(0, PageGroupParam:getValue() + (Next and 1 or -1), PageGroupParam:getMax())

            NI.DATA.ParameterAccess.setEnumParameter(App, PageGroupParam, NewValue)

        end
    end

end

------------------------------------------------------------------------------------------------------------------------
