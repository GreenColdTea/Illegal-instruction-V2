local allowTitleCardAnimation = false

function onStartTitleCardAnimation()
    if not allowTitleCardAnimation and isStoryMode and not seenCutscene then
        startVideo("hellspawn_cut")
        allowTitleCardAnimation = true
        return Function_Stop
    end
    return Function_Continue
end