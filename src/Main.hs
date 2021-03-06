module Main where

import Control.Applicative
import Control.Monad
import Control.Monad.Fix
import Data.IORef
import Data.List
import FRP.Elerea.Simple
import Graphics.UI.GLFW
import Graphics.Rendering.OpenGL

import Actor
import Game
import HighScore
import Level
import Render
import Sprites
import Text

import Paths_dow (getDataFileName)

main = do
  initialize
  openWindow (Size 640 480) [DisplayRGBBits 8 8 8, DisplayAlphaBits 8, DisplayDepthBits 24] Window
  windowTitle $= "Dungeons of Wor"

  aspectRatio <- newIORef 1
  levels <- loadLevels =<< getDataFileName "data/levels.txt"
  sprites <- loadSprites =<< getDataFileName "data/sprites.txt"
  charset <- loadCharset =<< getDataFileName "data/charset.txt"
  render <- getRenderFunctions aspectRatio charset

  let skins = createSkins sprites
      newActor = mkActor skins

  windowSizeCallback $= setViewport aspectRatio

  closed <- newIORef False
  let closeAction = writeIORef closed True >> return True
  windowCloseCallback $= closeAction

  clearColor $= Color4 0 0 0 1
  blend $= Enabled
  blendFunc $= (SrcAlpha,OneMinusSrcAlpha)
  textureFilter Texture2D $= ((Linear',Just Nearest),Linear')
  textureFunction $= Combine4

  let noKeys = (False,False,False,False,False)
  (keyPressGen,keySink) <- external (noKeys,noKeys)
  (highScoreGen,highScoreSink) <- external =<< loadScore
  let storeScore scores = do
        oldScore <- loadScore
        let newScore = maximum (oldScore:scores)
        saveScore newScore
        highScoreSink newScore

  renderAction <- start $ do
    keyPress <- keyPressGen
    highScore <- highScoreGen
    game highScore storeScore render closeAction newActor levels keyPress

  fix $ \loop -> do
    readKeys keySink
    join renderAction
    sleep 0.02
    stop <- readIORef closed
    esc <- getKey ESC
    when (not stop && esc /= Press) loop

  closeWindow

loadLevels file = unfoldr parseLevel . lines <$> readFile file

loadSprites file = do
  dat <- lines <$> readFile file
  parseSprites dat

readKeys sink = do
  let pr = (==Press)
  kn1 <- getKey UP
  ks1 <- getKey DOWN
  kw1 <- getKey LEFT
  ke1 <- getKey RIGHT
  kt1a <- getKey RCTRL
  kt1b <- getKey ENTER
  kn2 <- getKey 'W'
  ks2 <- getKey 'S'
  kw2 <- getKey 'A'
  ke2 <- getKey 'D'
  kt2 <- getKey LCTRL
  sink ((pr kn1, pr ks1, pr kw1, pr ke1, pr kt1a || pr kt1b),
        (pr kn2, pr ks2, pr kw2, pr ke2, pr kt2))
