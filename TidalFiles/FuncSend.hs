import P5Render
import P5Expressions
import Sound.Tidal.Context
import qualified Data.Map as Map_

changeFunc' stream list = sendFunc' list
  where toEvent' ws we ps pe v = Event (Sound.Tidal.Context.Context []) (Just $ Sound.Tidal.Context.Arc ws we) (Sound.Tidal.Context.Arc ps pe) v
          -- where [ws',we',ps',pe'] = map toRational [ws,we,ps,pe]
        makeFakeMap list_ = Map_.fromList list_
        makeFuncHelp :: [(JavaScript,Value)] -> ControlPattern
        makeFuncHelp y = Pattern $ fakeEvent (makeFakeMap y:: ControlMap)
          where fakeEvent a notARealArgument = [(toEvent' 0 1 0 1) a]
        makeFunc :: [(JavaScript,Value)] -> [ControlPattern]
        makeFunc x = [makeFuncHelp x]
        sendFunc' = mapM_ (streamFirst stream) . makeFunc
-- 
changeFunc stream func newFunction = changeFunc' stream list
  where list = [(func, VS (render newFunction))]
-- 
resetFunc stream func = changeFunc stream func (makeJSVar "")
-- 
makeDraw stream newFunction = changeFunc stream "draw" newFunction
-- 
makeImageUrlLoader stream imageURL = do
  changeFunc' stream list
  return $ makeJSVar (removePunc imageURL)
    where varName = removePunc imageURL
          imageURLVar = makeJSVar imageURL
          list = [("imageName",VS varName),("imageURL",VS imageURL)]
          -- the imageName is just the imageURL without any punctuation marks
          -- this was done so that you could refer to the image with only one variable
          --    the addition of a name is only for having a key:data pair that can be stored in an object
-- 
makeShader stream (shaderName, shaderVert, shaderFrag) = do
  changeFunc' stream list
  return $ makeJSVar shaderName
    where list = [("shaderName",VS shaderName),("shaderVert",VS shaderVert),("shaderFrag",VS shaderFrag)]
-- 
scMessage = pS "scMessage"

loadSoundFiles' path = changeFunc' tidal list
  where list = [("scMessage",VS (show "loadSoundFiles")),("filePath",VS (show path))]

loadSoundFiles path = changeFunc' tidal list
  where list = [("scMessage",VS "loadSoundFiles"),("filePath",VS path)]