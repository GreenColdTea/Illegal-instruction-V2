function onStepHit()
    if curStep > 1000 and curStep < 2336 then
        setProperty("timeBar.visible", true);
        setProperty("timeBarBG.visible", true);
        setProperty("timeTxt.visible", true);
    end
    if curStep == 2848 then
        setProperty("timeBar.visible", true);
        setProperty("timeBarBG.visible", true);
        setProperty("timeTxt.visible", true);
    end
end