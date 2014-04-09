module Main where

import Graphics.UI.Gtk hiding (eventSent)
import Graphics.UI.Gtk.Gdk.Events (Event, eventSent)
import Graphics.Rendering.Cairo hiding (rectangle)
import Graphics.Declarative.Form hiding (Color)
import Graphics.Declarative.Shape
import Graphics.Declarative.Combinators
import Graphics.Declarative.Envelope

main :: IO ()
main = do
  initGUI
  window <- windowNew
  set window windowProperties

  canvas <- drawingAreaNew
  containerAdd window canvas

  widgetModifyBg canvas StateNormal white
  widgetShowAll window

  onExpose canvas (handleExpose canvas)
  onDestroy window mainQuit
  mainGUI 

handleExpose :: WidgetClass w => w -> Event -> IO Bool
handleExpose canvas event = do
  (w, h) <- widgetGetSize canvas
  drawin <- widgetGetDrawWindow canvas
  renderWithDrawable drawin (myDraw (fromIntegral w) (fromIntegral h))
  return (eventSent event)

white :: Color
white = Color 65535 65535 65535

windowProperties :: [AttrOp Window]
windowProperties = [
  windowTitle          := "Hello Cairo",
  windowDefaultWidth   := 800, 
  windowDefaultHeight  := 600,
  containerBorderWidth := 0 ]

myDraw :: Double -> Double -> Render ()
myDraw w h = do
  let pict = picture0
  fDraw $ moved (w / 2, h / 2) $ {-debugEnvelope $-} pict
  --liftIO $ print $ fEnvelope pict

picture0 :: Form
picture0 = centered $
  besides downAttach [
    centered $ text "besides rightAttach:",
    debugEnvelope $ padded $ besides rightAttach [ formA, formB ],
    centered $ text "besides leftAttach:",
    debugEnvelope $ padded $ besides leftAttach [ formA, formB ] ]
  where
    formA = outlined defaultLineStyle { color = (1, 0.5, 0), lineWidth = 2 } $ circle 40
    formB = outlined (solid (0, 1, 0)) $ rectangle 80 80

picture1 :: Form
picture1 = outlined defaultLineStyle { color = (1, 0.5, 0), lineWidth = 2 } $ circle 40

picture2 :: Form
picture2 = besides downAttach [
  outlined defaultLineStyle { color = (1, 0.5, 0), lineWidth = 2 } $ circle 40,
  outlined (solid (0, 1, 0)) $ rectangle 50 50 ]

picture3 :: Form
picture3 = centered $
  besides downAttach [
    outlined defaultLineStyle { color = (1, 0.5, 0), lineWidth = 2 } $ circle 40,
    outlined (solid (0, 1, 0)) $ rectangle 50 50 ]