require "Scripts/Shared/Helpers/ControlHelper"
require "Scripts/Shared/Helpers/ModuleHelper"

local AccessibilityTextHelper = require("Scripts/Shared/Helpers/AccessibilityTextHelper")

local AccessibilityHelper = require("Scripts/Shared/KH1062/AccessibilityHelper")

------------------------------------------------------------------------------------------------------------------------

local ChainAccessHelper = {}

------------------------------------------------------------------------------------------------------------------------

local function getFocusSlotIndexPair(Slots)

    local FocusSlot = Slots and Slots:getFocusObject()
    local FocusSlotIndex = FocusSlot and Slots:calcIndex(FocusSlot) or NPOS
    return FocusSlot, FocusSlotIndex

end

------------------------------------------------------------------------------------------------------------------------

local function createMoveFocusSlotHelper(getFocusChainSlots)

    return function (IsRightMove)

        local Slots = getFocusChainSlots()
        local FocusSlot, FocusSlotIndex = getFocusSlotIndexPair(Slots)

        if FocusSlotIndex == NPOS then
            return false
        end

        local DestIndex = FocusSlotIndex + (IsRightMove and 1 or -1)
        local DestSlot = Slots and Slots:at(DestIndex) or nil
        local CanMoveFocusSlot = ModuleHelper.isSlotFX(FocusSlot) and ModuleHelper.isSlotFX(DestSlot)

        if CanMoveFocusSlot then
            NI.DATA.ChainAccess.moveSlot(App, Slots, FocusSlot, FocusSlotIndex + (IsRightMove and 2 or -1))
            return true
        end
        return false

    end

end

------------------------------------------------------------------------------------------------------------------------

function ChainAccessHelper.createChainController(getFocusChainSlots)

    local moveFocusSlotHelper = createMoveFocusSlotHelper(getFocusChainSlots)

    return {
        shiftSlotFocus = function (DeltaIndex)

            local Slots = getFocusChainSlots()
            if Slots then
                NI.DATA.ChainAccess.shiftSlotFocus(App, Slots, DeltaIndex)
            end

        end,

        removeFocusSlot = function ()

            local Slots = getFocusChainSlots()
            local FocusSlot = Slots and Slots:getFocusObject()

            if Slots and FocusSlot then
                NI.DATA.ChainAccess.removeSlot(App, Slots, FocusSlot)
            end

        end,

        moveFocusSlotLeft = function ()

            local IsRightMove = false
            return moveFocusSlotHelper(IsRightMove)

        end,

        moveFocusSlotRight = function ()

            local IsRightMove = true
            return moveFocusSlotHelper(IsRightMove)

        end,

        setFocusSlotActive = function (NewValue)

            local Slots = getFocusChainSlots()
            local FocusSlot = Slots and Slots:getFocusObject()
            if FocusSlot then
                NI.DATA.ParameterAccess.setBoolParameter(App, FocusSlot:getActiveParameter(), NewValue)
            end

        end
    }

end

------------------------------------------------------------------------------------------------------------------------

function ChainAccessHelper.getFocusSoundSlots()

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    return Sound and Sound:getChain():getSlots() or nil

end

------------------------------------------------------------------------------------------------------------------------

function ChainAccessHelper.createChainModel(SlotAccessors)

    return {
        getFocusedChainSize = function ()

            local Slots = SlotAccessors.getFocusChainSlots()
            return Slots and Slots:size() or 0

        end,

        getFocusSlotIndex = function ()

            local _, FocusSlotIndex = getFocusSlotIndexPair(SlotAccessors.getFocusChainSlots())
            return FocusSlotIndex

        end,

        isFocusSlotActive = function ()

            local FocusSlot = getFocusSlotIndexPair(SlotAccessors.getFocusChainSlots())
            return FocusSlot and FocusSlot:getActiveParameter():getValue() or false

        end,

        getFocusSlotDisplayName = function ()

            local FocusSlot = getFocusSlotIndexPair(SlotAccessors.getFocusChainSlots())
            return NI.DATA.SlotAlgorithms.getDisplayName(FocusSlot)

        end,

        isFocusSlotChanged = function ()

            local Slots = SlotAccessors.getFocusChainSlots()
            return Slots and Slots:isFocusObjectChanged()

        end,

        canToggleFocusSlotActive = SlotAccessors.canToggleFocusSlotActive,

        canRemoveFocusSlot = SlotAccessors.canRemoveFocusSlot

    }

end

------------------------------------------------------------------------------------------------------------------------

function ChainAccessHelper.createChainEditCallbacks(ChainModel,
                                                    ChainController,
                                                    ChainEditAccessibilityFuncs,
                                                    ControllerCallbacks)

    local SlotMoveHandlers = {
        [-1] = function () return ChainController.moveFocusSlotLeft() end,
        [1] = function () return ChainController.moveFocusSlotRight() end
    }

    local OneBasedSlotNumFunc = function()
        return ChainModel.getFocusSlotIndex() + 1
    end

    local GetMoveFocusTrainingTextFunc = function(DeltaIndex)
        return DeltaIndex > 0 and "Next Plug-in" or "Previous Plug-in"
    end

    local GetMovePluginTextFunc = function(Direction)
        return "Move Plug-in " .. (Direction > 0 and "Right" or "Left")
    end

    local GetMoveFocusTextFunc = function()
        return AccessibilityTextHelper.getFocusPluginText(
            ChainModel.getFocusSlotDisplayName(),
            OneBasedSlotNumFunc(),
            function() return ChainModel:getFocusedChainSize() end)
    end

    return {

        onShiftSlotFocus = function (DeltaIndex)
            ChainController.shiftSlotFocus(DeltaIndex) -- Do focus change regardless of accessibility mode
            ChainEditAccessibilityFuncs.sayWithTrainingModeAlternative(
                GetMoveFocusTextFunc(),
                GetMoveFocusTrainingTextFunc(DeltaIndex)
            )
        end,

        onMoveFocusSlot = function (Direction)
            local moveSlot = SlotMoveHandlers[Direction] or function () return false end
            ChainEditAccessibilityFuncs.doWithTrainingModeAlternative(
                function()
                    if moveSlot() then
                        ControllerCallbacks.onFocusSlotMoved(OneBasedSlotNumFunc())
                        ChainEditAccessibilityFuncs.say(AccessibilityTextHelper.getMovedPluginText(ChainModel.getFocusSlotDisplayName(), OneBasedSlotNumFunc()))
                    end
                end,
                GetMovePluginTextFunc(Direction)
            )
        end,

        onRemoveFocusSlot = function ()
            if not ChainModel.canRemoveFocusSlot() then
                return
            end
            ChainEditAccessibilityFuncs.doWithTrainingModeAlternative(
                function()
                    ControllerCallbacks.onUserConfirmsFocusSlotPluginRemoval(
                        function()
                            ChainController.removeFocusSlot()
                            ControllerCallbacks.onFocusSlotRemoved()
                        end
                    )
                end,
                "Remove Plug-in"
            )
       end,

        onToggleFocusSlotActive = function ()
            if not ChainModel.canToggleFocusSlotActive() then
                return
            end
            ChainEditAccessibilityFuncs.doWithTrainingModeAlternative(
                function()
                    local NewSlotActiveState = not ChainModel.isFocusSlotActive()
                    ChainController.setFocusSlotActive(NewSlotActiveState)
                    ControllerCallbacks.onFocusSlotActiveToggled(NewSlotActiveState)
                end,
                "Bypass Plug-in"
            )
        end
    }

end

------------------------------------------------------------------------------------------------------------------------

return ChainAccessHelper