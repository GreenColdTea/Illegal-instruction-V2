function onSongStart()
    fixTimeBar()
end

function fixTimeBar()    
    local dadColR = getProperty('dad.healthColorArray[0]')
    local dadColG = getProperty('dad.healthColorArray[1]')
    local dadColB = getProperty('dad.healthColorArray[2]')

    local dadColFinal = string.format('%02x%02x%02x', dadColR, dadColG, dadColB)

    setProperty('timeBar.color', getColorFromHex(dadColFinal))
end

function onEvent(name, value1, value2)
  if name == 'Change Character' then
    flxTimeBar()
  end
end
