module Views.Diagram.Path exposing (Position, Size, docs, view)

import ElmBook.Chapter as Chapter exposing (Chapter)
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr


type alias Position =
    ( Float, Float )


type alias Size =
    ( Float, Float )


view : String -> ( Position, Size ) -> ( Position, Size ) -> Svg msg
view colour ( ( fromX, fromY ), ( fromWidth, fromHeight ) ) ( ( toX, toY ), ( toWidth, toHeight ) ) =
    if fromX == toX && fromY < toY then
        draw
            colour
            [ start ( fromX + fromWidth / 2, fromY + fromHeight )
            , line ( toX + fromWidth / 2, toY )
            ]

    else if fromX == toX && fromY > toY then
        draw
            colour
            [ start ( fromX + fromWidth / 2, toY + toHeight )
            , line ( toX + fromWidth / 2, fromY )
            ]

    else if abs (fromY - toY) <= 15 && fromX < toX then
        let
            y : Float
            y =
                fromY + fromHeight / 2
        in
        draw
            colour
            [ start ( fromX + fromWidth, y )
            , line ( toX, y )
            ]

    else if abs (fromY - toY) <= 15 && fromX > toX then
        let
            y : Float
            y =
                fromY + fromHeight / 2
        in
        draw
            colour
            [ start ( fromX + fromWidth, y )
            , line ( toX, y )
            ]

    else if fromX < toX then
        draw
            colour
            (drawLines
                ( ( fromX, fromY ), ( fromWidth, fromHeight ) )
                ( ( toX, toY ), ( toWidth, toHeight ) )
            )

    else
        draw
            colour
            (drawLines
                ( ( toX, toY ), ( toWidth, toHeight ) )
                ( ( fromX, fromY ), ( fromWidth, fromHeight ) )
            )


bottomLeftcorner : Position -> Path
bottomLeftcorner ( posX, posY ) =
    "A8,8,0,0,0," ++ String.fromFloat posX ++ "," ++ String.fromFloat posY


cornerSize : Float
cornerSize =
    8.0


draw : String -> List Path -> Svg msg
draw colour pathList =
    Svg.path
        [ SvgAttr.strokeWidth "3"
        , SvgAttr.stroke colour
        , SvgAttr.d <| String.join " " pathList
        , SvgAttr.fill "transparent"
        ]
        []


drawLines : ( Position, Size ) -> ( Position, Size ) -> List Path
drawLines ( ( fromX, fromY ), ( fromWidth, fromHeight ) ) ( ( toX, toY ), ( _, toHeight ) ) =
    if fromY < toY then
        let
            fromMargin : Float
            fromMargin =
                fromHeight / 2

            interval : Float
            interval =
                (toX - (fromX + fromWidth)) / 2

            toMargin : Float
            toMargin =
                toHeight / 2
        in
        [ start ( fromX + fromWidth, fromY + fromMargin )
        , line ( fromX + fromWidth + interval - cornerSize, fromY + fromMargin )
        , topRightcorner ( fromX + fromWidth + interval, fromY + fromMargin + cornerSize )
        , line ( fromX + fromWidth + interval, toY + toMargin - cornerSize )
        , bottomLeftcorner ( fromX + fromWidth + interval + cornerSize, toY + toMargin )
        , line ( toX, toY + toMargin )
        ]

    else
        let
            fromMargin : Float
            fromMargin =
                fromHeight / 2

            interval : Float
            interval =
                (toX - (fromX + fromWidth)) / 2

            toMargin : Float
            toMargin =
                toHeight
                    / 2
        in
        [ start ( fromX + fromWidth, fromY + fromMargin )
        , line ( fromX + fromWidth + interval - cornerSize, fromY + fromMargin )
        , bottomLeftcorner ( fromX + fromWidth + interval, fromY + fromMargin - cornerSize )
        , line ( fromX + fromWidth + interval, toY + toMargin + cornerSize )
        , topRightcorner ( fromX + fromWidth + interval + cornerSize, toY + toMargin )
        , line ( toX, toY + toMargin )
        ]


line : Position -> Path
line ( posX, posY ) =
    "L" ++ String.fromFloat posX ++ "," ++ String.fromFloat posY


type alias Path =
    String


start : Position -> Path
start ( posX, posY ) =
    "M" ++ String.fromFloat posX ++ "," ++ String.fromFloat posY


topRightcorner : Position -> Path
topRightcorner ( posX, posY ) =
    "A8,8,0,0,1," ++ String.fromFloat posX ++ "," ++ String.fromFloat posY


docs : Chapter x
docs =
    Chapter.chapter "Path"
        |> Chapter.renderComponent
            (Svg.svg
                [ SvgAttr.width "100%"
                , SvgAttr.height "100%"
                , SvgAttr.viewBox "0 0 2048 2048"
                ]
                [ view "#000000" ( ( 0, 0 ), ( 100, 100 ) ) ( ( 100, 100 ), ( 10, 10 ) ) ]
                |> Svg.toUnstyled
            )
