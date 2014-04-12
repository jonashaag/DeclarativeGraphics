# Declarative Graphics / Shapes

(Example rendered Image:)
![TitleSVG](https://rawgithub.com/matheus23/DeclarativeGraphics/master/testRender.svg)
(Code to generate this image:
```haskell
picture0 :: Form
picture0 = centered $
  groupBy downAttach [
    centered $ text "groupBy rightAttach:",
    debugEnvelope $ padded 4 $ groupBy rightAttach [ formA, formB ],
    centered $ text "groupBy leftAttach:",
    debugEnvelope $ padded 4 $ groupBy leftAttach [ formA, formB ] ]
  where
    formA = outlined defaultLineStyle { color = (1, 0.5, 0), lineWidth = 2 } $ circle 40
    formB = outlined (solid (0, 1, 0)) $ rectangle 80 80
```
(https://github.com/matheus23/DeclarativeGraphics/blob/master/Main.hs#L59))

The aim is to create a functional, declarative Shape rendering library. It also features Text rendering.

## Libraries used:

* Cairo: Rendering Backend for Shapes
* Pango: Rendering Backend for Text
* Gtk: Backend for rendering to Window.

## Inspirations:

* [Racket Picts](http://docs.racket-lang.org/quick/)
* API Heavily inspired by: [Elm Collages](http://library.elm-lang.org/catalog/evancz-Elm/0.12/Graphics-Collage)

## Similar Projects:

* [Diagrams](http://projects.haskell.org/diagrams/)