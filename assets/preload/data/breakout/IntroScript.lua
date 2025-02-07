local allowCountDown = false

debugMode = true

function onStartCountDown()
    if not allowCountDown and isStoryMode and not seenCutscene then
        startVideo("breakout_cut")
        allowCountDown = true
        return Function_Stop
    end
    return Function_Continue
end