module Render where

import Control.Monad
import Data.Array
import Data.Char
import Data.IORef
import Graphics.UI.GLFW
import Graphics.Rendering.OpenGL

import Actor as A
import Game
import GraphUtils
import Level

hudHeight = 0.2

solid :: GLfloat
solid = 1

getAspectRatio level = fromIntegral lh / fromIntegral lw + hudHeight
  where (lw,lh) = levelSize level

render displayText levelState levelCount = do
  let curLevel = level levelState
      (lw,lh) = levelSize curLevel
      height = fromIntegral lh / fromIntegral lw
      magn = 1 / fromIntegral lw

  clear [ColorBuffer]
  loadIdentity

  renderHud height
  preservingMatrix $ do
    translate $ Vector3 0 hudHeight (0 :: GLfloat)
    scale magn magn (1 :: GLfloat)

    renderLevel curLevel
    renderBullets (bullets levelState)
    renderActors (actors levelState)

  displayText 0.03 0.03 0.0028 $ "LEVEL " ++ show levelCount ++ " " ++ map toUpper (levelName curLevel)

  flush
  swapBuffers

renderLevel level = do
  let (lw,lh) = levelSize level
      height = fromIntegral lh / fromIntegral lw

  texture Texture2D $= Disabled
  color $ Color4 0.2 0.5 1 solid
  forM_ (assocs (legalMoves level)) $ \((y,x),ms) -> do
    let xc = fromIntegral x
        yc = fromIntegral (lh-y-1)
    unless (North `elem` ms) $ drawRectangle xc (yc+0.95) 1 0.05
    unless (South `elem` ms) $ drawRectangle xc yc 1 0.05
    unless (East `elem` ms) $ drawRectangle (xc+0.95) yc 0.05 1
    unless (West `elem` ms) $ drawRectangle xc yc 0.05 1

renderActors as = do
  texture Texture2D $= Enabled
  color $ Color4 1 1 1 solid
  forM_ as $ \a -> do
    let V x y = A.position a
        x' = fromIntegral x / fromIntegral fieldSize
        y' = fromIntegral y / fromIntegral fieldSize
    when (not . null . animation $ a) $ drawSprite (head (animation a)) (0.1+x') (0.1+y') 0.8 0.8 (facing a)

renderBullets bs = do
  texture Texture2D $= Disabled
  color $ Color4 1 0.3 0.1 solid
  forM_ bs $ \(V x y) -> do
    let x' = fromIntegral x / fromIntegral fieldSize
        y' = fromIntegral y / fromIntegral fieldSize
    drawRectangle (0.45+x') (0.45+y') 0.1 0.1

renderHud height = do
  texture Texture2D $= Disabled
  color $ Color4 0.6 0.6 0.6 solid
  drawRectangle 0 0 1 hudHeight

drawRectangle :: GLfloat -> GLfloat -> GLfloat -> GLfloat -> IO ()
drawRectangle x y sx sy = renderPrimitive Quads $ mapM_ vertex
  [Vertex3 x y 0, Vertex3 (x+sx) y 0, Vertex3 (x+sx) (y+sy) 0, Vertex3 x (y+sy) 0]

drawSprite :: TextureObject -> GLfloat -> GLfloat -> GLfloat -> GLfloat -> Direction -> IO ()
drawSprite tid x y sx sy dir = do
  let (u1,v1,u2,v2,u3,v3,u4,v4) = case dir of
        North -> (1,1,1,0,0,0,0,1)
        East  -> (1,1,0,1,0,0,1,0)
        South -> (0,1,0,0,1,0,1,1)
        West  -> (0,1,1,1,1,0,0,0)
  textureBinding Texture2D $= Just tid
  renderPrimitive Quads $ do
    texCoord2 u1 v1
    vertex3 x y 0
    texCoord2 u2 v2
    vertex3 (x+sx) y 0
    texCoord2 u3 v3
    vertex3 (x+sx) (y+sy) 0
    texCoord2 u4 v4
    vertex3 x (y+sy) 0
