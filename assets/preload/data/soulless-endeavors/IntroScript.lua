local allowCountDown = false

function onStartCountDown()
    if not allowCountDown and isStoryMode and not seenCutscene then
        startVideo("hellspawn_cut")
        allowCountDown = true
        return Function_Stop
    end
    return Function_Continue
end