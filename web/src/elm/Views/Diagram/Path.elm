module Views.Diagram.Path exposing (view)

import Models.Diagram exposing (Msg(..))
import Svg exposing (Svg, line, path)
import Svg.Attributes exposing (d, fill, stroke, strokeWidth)


type alias Path =
    String


type alias Position =
    ( Float, Float )


type alias Size =
    ( Float, Float )


cornerSize : Float
cornerSize =
    8.0


view : String -> ( Position, Size ) -> ( Position, Size ) -> Svg Msg
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


drawLines : ( Position, Size ) -> ( Position, Size ) -> List Path
drawLines ( ( fromX, fromY ), ( fromWidth, fromHeight ) ) ( ( toX, toY ), ( _, toHeight ) ) =
    if fromY < toY then
        let
            interval =
                (toX - (fromX + fromWidth)) / 2

            fromMargin =
                fromHeight / 2

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
            interval =
                (toX - (fromX + fromWidth)) / 2

            fromMargin =
                fromHeight / 2

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


draw : String -> List Path -> Svg Msg
draw colour pathList =
    path
        [ strokeWidth "2"
        , stroke colour
        , d <| String.join " " pathList
        , fill "transparent"
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
