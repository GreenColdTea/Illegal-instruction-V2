-- thanks bacon for the script im a fucking dumbass   
function onCreate()
	if dadName == 'dukep3-legacy' then
		makeAnimatedLuaSprite('kapowf', 'icons/legacy/icon-duke3', getProperty('iconP2.x'), getProperty('iconP2.y'))
		addAnimationByPrefix('kapowf', 'normal', 'neutralbozo', 24, true)
		addAnimationByPrefix('kapowf', 'losing', 'guh', 24, true)
		setScrollFactor('kapowf', 0, 0)
		setObjectCamera('kapowf', 'other')
		addLuaSprite('kapowf', true)
		setObjectOrder('kapowf', 99)
		objectPlayAnimation('kapowf', 'normal', false)
	end
end

function onUpdate(elapsed)
	if dadName == 'dukep3-legacy' then
		setProperty('iconP2.alpha', 0)
		if getProperty('health') > 1.6 then
            setProperty('kapowf.x', getProperty('iconP2.x'))
            setProperty('kapowf.y', getProperty('iconP2.y'))
			objectPlayAnimation('kapowf', 'losing', false)
		else
			objectPlayAnimation('kapowf', 'normal', false)
		end
	end
	setProperty('camOther.zoom', getProperty('camHUD.zoom'))
	setProperty('kapowf.y', getProperty('iconP2.y') + 50)
	setProperty('kapowf.angle', getProperty('iconP2.angle'))
	setProperty('kapowf.scale.x', getProperty('iconP2.scale.x'))
	setProperty('kapowf.scale.y', getProperty('iconP2.scale.y'))
	setProperty('camOther.zoom', getProperty('camHUD.zoom'))
end