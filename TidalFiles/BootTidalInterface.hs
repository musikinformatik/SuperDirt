:set -XOverloadedStrings
:set prompt ""
:set prompt-cont ""
:set -XDataKinds

import Sound.Tidal.Context
import qualified Control.Monad as CM
import qualified Sound.OSC.FD as O
import qualified Sound.Tidal.Tempo as T
import qualified Data.Map as Map_
-- import P5hs

:{
tidal <- startMulti
               [
                  superdirtTarget {oLatency = 0.1, oAddress = "127.0.0.1", oPort = 57120}
               ] (defaultConfig {cFrameTimespan = 1/20})
:}


:{
let setI = streamSetI tidal
    setF = streamSetF tidal
    setS = streamSetS tidal
    setR = streamSetI tidal
    setB = streamSetB tidal
:}


:{
let p = streamReplace tidal
    hush = streamHush tidal
    list = streamList tidal
    mute = streamMute tidal
    unmute = streamUnmute tidal
    solo = streamSolo tidal
    unsolo = streamUnsolo tidal
    once = streamOnce tidal
    asap = once
    nudgeAll = streamNudgeAll tidal
    all = streamAll tidal
    resetCycles = streamResetCycles tidal
    setcps = asap . cps
    xfade i = transition tidal True (Sound.Tidal.Transition.xfadeIn 4) i
    xfadeIn i t = transition tidal True (Sound.Tidal.Transition.xfadeIn t) i
    histpan i t = transition tidal True (Sound.Tidal.Transition.histpan t) i
    wait i t = transition tidal True (Sound.Tidal.Transition.wait t) i
    waitT i f t = transition tidal True (Sound.Tidal.Transition.waitT f t) i
    jump i = transition tidal True (Sound.Tidal.Transition.jump) i
    jumpIn i t = transition tidal True (Sound.Tidal.Transition.jumpIn t) i
    jumpIn' i t = transition tidal True (Sound.Tidal.Transition.jumpIn' t) i
    jumpMod i t = transition tidal True (Sound.Tidal.Transition.jumpMod t) i
    mortal i lifespan release = transition tidal True (Sound.Tidal.Transition.mortal lifespan release) i
    interpolate i = transition tidal True (Sound.Tidal.Transition.interpolate) i
    interpolateIn i t = transition tidal True (Sound.Tidal.Transition.interpolateIn t) i
    clutch i = transition tidal True (Sound.Tidal.Transition.clutch) i
    clutchIn i t = transition tidal True (Sound.Tidal.Transition.clutchIn t) i
    anticipate i = transition tidal True (Sound.Tidal.Transition.anticipate) i
    anticipateIn i t = transition tidal True (Sound.Tidal.Transition.anticipateIn t) i
    forId i t = transition tidal False (Sound.Tidal.Transition.mortalOverlay t) i
    d1 = p 1 . (|< orbit 0)
    d2 = p 2 . (|< orbit 1)
    d3 = p 3 . (|< orbit 2)
    d4 = p 4 . (|< orbit 3)
    d5 = p 5 . (|< orbit 4)
    d6 = p 6 . (|< orbit 5)
    d7 = p 7 . (|< orbit 6)
    d8 = p 8 . (|< orbit 7)
    d9 = p 9 . (|< orbit 8)
    d10 = p 10 . (|< orbit 9)
    d11 = p 11 . (|< orbit 10)
    d12 = p 12 . (|< orbit 11)
    d13 = p 13
    d14 = p 14
    d15 = p 15
    d16 = p 16
:}




-- if you want to add scMessage functionality to tidal, just copy everything below this line and add it to your own BootTidal.hs

import qualified Data.Map.Strict as Map

:{
scMessage <- startMulti 
                [
                superdirtTarget {oLatency = 0.1,oAddress = "127.0.0.1",
                                 oPort = 57120, oPath = "/scMessage"}
                ] (defaultConfig {cFrameTimespan = 1/20 , cCtrlPort = 6011, cTempoPort = 9611})
:}

:{
let changeFunc' stream list = sendFunc' list
      where toEvent' ws we ps pe v = Event (Sound.Tidal.Context.Context []) (Just $ Sound.Tidal.Context.Arc ws we) (Sound.Tidal.Context.Arc ps pe) v
              -- where [ws',we',ps',pe'] = map toRational [ws,we,ps,pe]
            makeFakeMap list_ = Map_.fromList list_
            makeFuncHelp :: [(String,Value)] -> ControlPattern
            makeFuncHelp y = Pattern $ fakeEvent (makeFakeMap y:: ControlMap)
              where fakeEvent a notARealArgument = [(toEvent' 0 1 0 1) a]
            makeFunc :: [(String,Value)] -> [ControlPattern]
            makeFunc x = [makeFuncHelp x]
            sendFunc' = mapM_ (streamFirst stream) . makeFunc
    loadSoundFiles' stream path = changeFunc' stream list
      where list = [("scMessage",VS "loadSoundFiles"),("filePath",VS path)]
    loadSynthDefs' stream path = changeFunc' stream list
      where list = [("scMessage",VS "loadSoundFileFolder"),("filePath",VS path)]
    loadOnly' stream path = changeFunc' stream list
      where list = [("scMessage",VS "loadOnly"),("filePath",VS path)]
    loadSoundFileFolder' stream path = changeFunc' stream list
      where list = [("scMessage",VS "loadSoundFileFolder"),("filePath",VS path)]
    loadSoundFile' stream path = changeFunc' stream list
      where list = [("scMessage",VS "loadSoundFile"),("filePath",VS path)]
    freeAllSoundFiles' stream = changeFunc' stream list
      where list = [("scMessage",VS "freeAllSoundFiles")]
    freeSoundFiles' stream name = changeFunc' stream list
      where list = [("scMessage",VS "freeSoundFiles"),("filePath",VS name)]
    postSampleInfo' stream = changeFunc' stream list
      where list = [("scMessage",VS "postSampleInfo")]
    initFreqSynthWindow' stream = changeFunc' stream list
      where list = [("scMessage",VS "initFreqSynthWindow")]
:}

:{
-- functions for sending paths to load into superDirt
let loadSoundFiles path = loadSoundFiles' scMessage path 
    loadSynthDefs path = loadSynthDefs' scMessage path
    loadOnly path = loadOnly' scMessage path
    loadSoundFileFolder path = loadSoundFileFolder' scMessage path 
    loadSoundFile path = loadSoundFile' scMessage path
    freeAllSoundFiles = freeAllSoundFiles' scMessage
    freeSoundFiles name = freeSoundFiles' scMessage name
    postSampleInfo = postSampleInfo' scMessage
    initFreqSynthWindow = initFreqSynthWindow' scMessage
:}
