module Views.Diagram.Path exposing (view)

import Models.Diagram exposing (Msg(..), Settings)
import Svg exposing (Svg, g, line, path)
import Svg.Attributes exposing (d, stroke, strokeWidth)


type alias Path =
    String


type alias Position =
    ( Float, Float )


type alias Size =
    ( Float, Float )


cornerSize : Float
cornerSize =
    10.0


view : Settings -> ( Position, Size ) -> ( Position, Size ) -> Svg Msg
view settings ( ( fromX, fromY ), ( fromWidth, fromHeight ) ) ( ( toX, toY ), ( toWidth, toHeight ) ) =
    if fromX == toX then
        draw
            settings
            [ start ( fromX + fromWidth / 2, fromY + fromHeight )
            , line ( toX + fromWidth / 2, toY )
            ]

    else if fromY == toY then
        draw
            settings
            [ start ( fromX + fromWidth, fromY + fromHeight / 2 )
            , line ( toX, toY + fromHeight / 2 )
            ]

    else if fromX < toX && fromX < toY then
        let
            interval =
                (toX - (fromY + fromWidth)) / 2

            fromMargin =
                fromHeight / 2

            toMargin =
                toHeight / 2
        in
        draw
            settings
            [ start ( fromX + fromWidth, fromY + fromMargin )
            , line ( fromX + fromWidth + interval - cornerSize, fromY + fromMargin )
            , topRightcorner ( fromX + fromWidth + interval, fromY + fromMargin + cornerSize )
            , line ( fromX + fromWidth + interval, toY + toMargin - cornerSize )
            , bottomLeftcorner ( fromX + fromWidth + interval + cornerSize, toY + toMargin )
            , line ( toX, toY + toMargin )
            ]

    else if fromX < toX && fromX > toY then
        -- TODO
        g [] []

    else if fromX > toX && fromX < toY then
        -- TODO
        g [] []

    else
        -- TODO
        g [] []


draw : Settings -> List Path -> Svg Msg
draw settings pathList =
    path
        [ strokeWidth "1"
        , stroke settings.color.line
        , d <| String.join " " pathList
        ]
        []


start : Position -> Path
start ( posX, posY ) =
    "M" ++ String.fromFloat posX ++ "," ++ String.fromFloat posY


line : Position -> Path
line ( posX, posY ) =
    "L" ++ String.fromFloat posX ++ "," ++ String.fromFloat posY


topRightcorner : Position -> Path
topRightcorner ( posX, posY ) =
    "A8,8,0,0,1," ++ String.fromFloat posX ++ "," ++ String.fromFloat posY


bottomLeftcorner : Position -> Path
bottomLeftcorner ( posX, posY ) =
    "A8,8,0,0,0," ++ String.fromFloat posX ++ "," ++ String.fromFloat posY
