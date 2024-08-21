function onStepHit()
   if songName == 'soulless-endeavors' then
      if curStep > 895 and curStep < 1148 then
         setProperty("dadGroup.x", 450)
         setProperty("dadGroup.y", 150)
         setProperty("bfGroup.y", 875)
      end
   end
end