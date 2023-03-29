local StyleHelper = {}

------------------------------------------------------------------------------------------------------------------------

function StyleHelper.enableFlexFor(Bar, Label)

    Bar:setFlex(Label)

end

------------------------------------------------------------------------------------------------------------------------

function StyleHelper.enableAutoResizeFor(Label)

    Label:setAutoResize(true)

end

------------------------------------------------------------------------------------------------------------------------

return StyleHelper
