local CreateGroupUtil = {}

------------------------------------------------------------------------------------------------------------------------

function CreateGroupUtil.selectOrCreateNextGroup(OpenConfirmActionOverlayFunc, DataModel, DataController)

    if not DataModel:isFocusGroupIndexValid() then
        return
    end

    if DataModel:isOnLastGroup() then
        OpenConfirmActionOverlayFunc(
            "New Group",
            NI.HW.BUTTON_WHEEL_LEFT,
            function() DataController:createGroup() end
        )
    else
        DataController:setFocusGroup(DataModel:getOneBasedFocusGroupIndex() + 1)
    end

end

------------------------------------------------------------------------------------------------------------------------

return CreateGroupUtil
