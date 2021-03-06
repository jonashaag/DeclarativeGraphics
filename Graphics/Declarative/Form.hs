module Graphics.Declarative.Form where

import System.IO.Unsafe (unsafePerformIO)
import Graphics.Rendering.Pango hiding (Color)
import qualified Graphics.Rendering.Cairo as Cairo
import qualified Graphics.Declarative.Internal.Primitive as Prim
import Graphics.Declarative.Envelope
import Graphics.Declarative.Shape

type Position = (Double, Double)
type Color = (Double, Double, Double)

data Form = Form {
  fEnvelope :: Envelope,
  fDraw :: Cairo.Render ()
}

data LineStyle = LineStyle {
  color :: Color,
  lineWidth :: Double,
  cap :: LineCap,
  lineJoin :: LineJoin,
  dash :: [Double],
  dashOffset :: Double
} deriving (Show, Eq)

defaultLineStyle :: LineStyle
defaultLineStyle = LineStyle {
  color = (0, 0, 0),
  lineWidth = 1,
  cap = Padded,
  lineJoin = Sharp,
  dash = [],
  dashOffset = 0
}

data TextStyle = TextStyle {
  textColor :: Color,
  bold :: Bool,
  italic :: Bool,
  fontSize :: Double,
  fontFamily :: String
} deriving (Show, Eq)

defaultTextStyle :: TextStyle
defaultTextStyle = TextStyle {
  textColor = (0, 0, 0),
  bold = False,
  italic = False,
  fontSize = 14,
  fontFamily = "Sans"
}

data LineCap = Flat | Round | Padded deriving (Show, Eq)
data LineJoin = Clipped | Smooth | Sharp deriving (Show, Eq)


emptyForm :: Form
emptyForm = Form {
  fEnvelope = Envelope 0 0 0 0,
  fDraw = return ()
}

filled :: Color -> Shape -> Form
filled (r, g, b) shape = Form {
  fEnvelope = sEnvelope shape,
  fDraw = do
    Cairo.save
    Cairo.setSourceRGB r g b
    Prim.renderPrimitives $ sPrims shape
    Cairo.fill
    Cairo.restore
}

outlined :: LineStyle -> Shape -> Form
outlined style shape = Form {
  fEnvelope = sEnvelope shape,
  fDraw = do
    Cairo.save
    applyLineStyle style
    Prim.renderPrimitives $ sPrims shape
    Cairo.stroke
    Cairo.restore
}

solid :: Color -> LineStyle
solid col = defaultLineStyle { color = col }

applyLineStyle :: LineStyle -> Cairo.Render ()
applyLineStyle style = do
  Cairo.setSourceRGB r g b
  Cairo.setLineWidth $ lineWidth style
  Cairo.setLineCap $ convertLineCap $ cap style
  Cairo.setLineJoin $ convertLineJoin $ lineJoin style
  Cairo.setDash (dash style) (dashOffset style)
  where
    (r, g, b) = color style

convertLineCap :: LineCap -> Cairo.LineCap
convertLineCap Flat = Cairo.LineCapButt
convertLineCap Round = Cairo.LineCapRound
convertLineCap Padded = Cairo.LineCapSquare

convertLineJoin :: LineJoin -> Cairo.LineJoin
convertLineJoin Clipped = Cairo.LineJoinBevel
convertLineJoin Smooth = Cairo.LineJoinRound
convertLineJoin Sharp = Cairo.LineJoinMiter

text :: TextStyle -> String -> Form
text style content = Form {
  fEnvelope = Envelope 0 0 width height,
  fDraw = do
    Cairo.save
    Cairo.setSourceRGB r g b
    showLayout pLayout
    Cairo.restore
} where
  getFontDescription :: IO FontDescription
  getFontDescription = do
    desc <- fontDescriptionNew
    fontDescriptionSetStyle desc $
      if italic style then StyleItalic else StyleNormal
    fontDescriptionSetWeight desc $
      if bold style then WeightBold else WeightNormal
    fontDescriptionSetSize desc $ fontSize style
    fontDescriptionSetFamily desc $ fontFamily style
    return desc
  getContext :: FontDescription -> IO PangoContext
  getContext fontDescription = do
    context <- cairoCreateContext Nothing
    contextSetFontDescription context fontDescription
    return context
  pLayout :: PangoLayout
  pLayout = unsafePerformIO $ do
    pContext <- getContext =<< getFontDescription
    layoutText pContext content
  (_, PangoRectangle _ _ width height) = unsafePerformIO $ layoutGetExtents pLayout
  (r, g, b) = textColor style

-- Used for text drawing:
{-# NOINLINE standardContext #-}
standardContext :: PangoContext
standardContext = unsafePerformIO $ cairoCreateContext Nothing

moved :: (Double, Double) -> Form -> Form
moved dist (Form env rend) = Form {
  fEnvelope = moveEnvelope dist env,
  fDraw = do
    Cairo.save
    uncurry Cairo.translate dist
    rend
    Cairo.restore
}

atop :: Form -> Form -> Form
atop (Form env1 rend1) (Form env2 rend2) = Form {
  fEnvelope = envelopeAtop env1 env2,
  fDraw = rend2 >> rend1
}

paddedWith :: (Double, Double) -> Form -> Form
paddedWith (padX, padY) (Form (Envelope l t r b) rend) = Form {
  fEnvelope = Envelope (l-padX) (t-padY) (r+padX) (b+padY),
  fDraw = rend
}

padded :: Double -> Form -> Form
padded padding = paddedWith (padding, padding)

alignX :: Double -> Form -> Form
alignX relX form@(Form (Envelope l _ r _) _) =
  moved (relX * (l-r), 0) $ moved (-l, 0) form

alignY :: Double -> Form -> Form
alignY relY form@(Form (Envelope _ t _ b) _) =
  moved (0, relY * (t-b)) $ moved (0, -t) form

centered :: Form -> Form
centered = centeredX . centeredY

centeredX :: Form -> Form
centeredX = alignX 0.5

centeredY :: Form -> Form
centeredY = alignY 0.5

invisible :: Form -> Form
invisible (Form env _) = Form env $ return ()

modifiedEnvelope :: (Envelope -> Envelope) -> Form -> Form
modifiedEnvelope modify form = form `withEnvelope` modify (fEnvelope form)

withEnvelope :: Form -> Envelope -> Form
withEnvelope (Form _ rend) envelope = Form envelope rend

noEnvelope :: Form -> Form
noEnvelope form = form `withEnvelope` emptyEnvelope

debugEnvelope :: Form -> Form
debugEnvelope form =
  withEnvelope (outlined (solid (1, 0, 0)) $ circle 2) emptyEnvelope
  `atop`
  outlined (solid (1, 0, 0)) (fromEnvelope $ fEnvelope form)
  `atop`
  form

debugWithSize :: Form -> Form
debugWithSize form@(Form (Envelope left _ _ bottom) _) =
  noEnvelope (moved (left, bottom) $ text monoStyle $ "width : " ++ show w ++ "\nheight: " ++ show h)
  `atop`
  debugEnvelope form
  where
    w = formWidth form
    h = formHeight form
    monoStyle = defaultTextStyle { fontFamily = "Monospace", fontSize = 8 }

measureVert :: Form -> (Double, Double)
measureVert (Form env _) = (envToTop env, envToBottom env)

measureHoriz :: Form -> (Double, Double)
measureHoriz (Form env _) = (envToLeft env, envToRight env)

formHeight :: Form -> Double
formHeight form = uncurry (flip (-)) $ measureVert form

formWidth :: Form -> Double
formWidth form = uncurry (flip (-)) $ measureHoriz form
