module TidalInterface where

import P5Render
import P5Expressions
import Sound.Tidal.Context
import qualified Data.Map as Map_

loadSynthDefs' stream path = changeFunc' stream list
   where list = [("scMessage",VS "loadSoundFileFolder"),("filePath",VS path)]

loadOnly' stream path = changeFunc' stream list
   where list = [("scMessage",VS "loadOnly"),("filePath",VS path)]

loadSoundFileFolder' stream path = changeFunc' stream list
   where list = [("scMessage",VS "loadSoundFileFolder"),("filePath",VS path)]

loadSoundFiles' stream path = changeFunc' stream list
   where list = [("scMessage",VS "loadSoundFiles"),("filePath",VS path)]

loadSoundFile' stream path = changeFunc' stream list
   where list = [("scMessage",VS "loadSoundFile"),("filePath",VS path)]

freeAllSoundFiles' stream path = changeFunc' stream list
   where list = [("scMessage",VS "freeAllSoundFiles"),("filePath",VS path)]

freeSoundFiles' stream names = changeFunc' stream list
   where list = [("scMessage",VS "freeSoundFiles"),("filePath",VS names)]

postSampleInfo' stream names = changeFunc' stream list
   where list = [("scMessage",VS "postSampleInfo")]

initFreqSynthWindow' stream = changeFunc' stream
   where list = [("scMessage",VS "initFreqSynthWindow")]