let loadSoundFiles path = changeFunc' tidal list
   where list = [("scMessage",VS "loadSoundFiles"),("filePath",VS path)]