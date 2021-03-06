module Main where

import Demos.DemoUtilities
import Graphics.Declarative.Form
import Graphics.Declarative.Shape
import Graphics.Declarative.Combinators
import Graphics.Declarative.Util.Svg

main :: IO ()
main = do
  source <- readFile "Demos/DemoSvg.hs"
  svg <- svgFormFile "Ghostscript_Tiger.svg"
  openGTK $ showSourceAndProduct source svg
