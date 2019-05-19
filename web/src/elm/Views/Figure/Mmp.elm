module Views.Figure.Mmp exposing (view)

import Constants exposing (..)
import Html exposing (div)
import Html.Attributes as Attr
import Models.Figure exposing (Children(..), Color, Comment, Item, ItemType(..), Model, Msg(..), Settings)
import String
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (..)
import Svg.Lazy exposing (..)
import Utils exposing (calcFontSize)


type Position
    = Position Direction Direction


type Direction
    = All
    | Top
    | Bottom
    | Left
    | Right


itemWidth : Int
itemWidth =
    88


itemHeight : Int
itemHeight =
    30


distance : Int
distance =
    80


angle : Int
angle =
    20


childAngle : Int
childAngle =
    12


leftPositionStart : Int
leftPositionStart =
    270


rightPositionStart : Int
rightPositionStart =
    90


deg : Float
deg =
    degrees 180 / 180


view : Model -> Svg Msg
view model =
    let
        posX =
            model.svg.width // 2 - itemWidth

        posY =
            model.svg.height // 2 - itemHeight
    in
    g
        [ transform
            ("translate("
                ++ String.fromInt model.x
                ++ ","
                ++ String.fromInt model.y
                ++ ")"
            )
        , fill "#F5F5F6"
        ]
        (case model.items of
            x :: _ ->
                (case x.children of
                    Children [] ->
                        [ g [] [] ]

                    Children c ->
                        childrenView All 1 model.settings model.settings.color.task c posX posY
                )
                    ++ [ itemView model.settings (String.fromInt posX) (String.fromInt posY) x model.settings.color.activity ]

            [] ->
                [ g [] [] ]
        )


getPosition : Int -> Direction -> Int -> Int -> Int -> Int -> ( Position, ( Int, Int ) )
getPosition childrenCount direction hierarchy index posX posY =
    let
        dist =
            distance
                * (if childrenCount > 0 then
                    childrenCount

                   else
                    2
                  )
                |> toFloat

        round v =
            if v == 0 then
                1

            else
                v

        calcAngle v =
            if v > 360 then
                abs v - 360

            else if v < 0 then
                abs v

            else
                v

        a =
            angle * Basics.max 1 (ceiling (toFloat index / 2 / 2))

        aa =
            childAngle * Basics.max 1 (ceiling (toFloat index / 2))

        ( pos, newAngle, radio ) =
            if direction == All then
                if modBy 2 index == 1 && modBy 2 (round (index + 1) // 2) == 1 then
                    ( Position Top Right, rightPositionStart - a |> calcAngle, toFloat a / toFloat rightPositionStart )

                else if modBy 2 index == 0 && modBy 2 (round (index // 2)) == 1 then
                    ( Position Bottom Right, rightPositionStart + a |> calcAngle, toFloat a / toFloat rightPositionStart )

                else if modBy 2 index == 1 && modBy 2 (round ((index + 1) // 2)) == 0 then
                    ( Position Top Left, leftPositionStart + a |> calcAngle, toFloat a / toFloat leftPositionStart )

                else
                    ( Position Bottom Left, leftPositionStart - a |> calcAngle, toFloat a / toFloat leftPositionStart )

            else if modBy 2 (index // 2) == 1 then
                ( Position Top direction
                , if direction == Right then
                    rightPositionStart
                        - aa
                        |> calcAngle

                  else
                    leftPositionStart
                        + aa
                        |> calcAngle
                , if direction == Right then
                    toFloat aa / toFloat rightPositionStart

                  else
                    toFloat aa / toFloat leftPositionStart
                )

            else
                ( Position Bottom direction
                , if direction == Right then
                    rightPositionStart
                        + aa
                        |> calcAngle

                  else
                    leftPositionStart
                        - aa
                        |> calcAngle
                , if direction == Right then
                    toFloat aa / toFloat rightPositionStart

                  else
                    toFloat aa / toFloat leftPositionStart
                )
    in
    ( pos
    , ( posX + Basics.round (dist * (1 + radio) * sin (deg * toFloat newAngle))
      , posY + Basics.round (dist * (1 + radio) * cos (deg * toFloat newAngle))
      )
    )


childrenView : Direction -> Int -> Settings -> Color -> List Item -> Int -> Int -> List (Svg Msg)
childrenView direction hierarchy settings color items posX posY =
    items
        |> List.indexedMap
            (\i item ->
                let
                    childrenItems =
                        case item.children of
                            Children [] ->
                                []

                            Children c ->
                                c

                    ( Position topOrBottom leftOrRight, ( x1, y1 ) ) =
                        getPosition (List.length childrenItems) direction hierarchy (i + 1) posX posY
                in
                -- TODO: random color
                childrenView leftOrRight (hierarchy + 1) settings settings.color.task childrenItems x1 y1
                    ++ [ lineView (posX + itemWidth // 2) (posY + itemHeight // 2) (x1 + itemWidth // 2) (y1 + itemHeight // 2) color
                       , itemView settings (String.fromInt x1) (String.fromInt y1) item color
                       ]
            )
        |> List.concat


lineView : Int -> Int -> Int -> Int -> Color -> Svg Msg
lineView posX1 posY1 posX2 posY2 color =
    line
        [ x1 (String.fromInt posX1)
        , y1 (String.fromInt posY1)
        , x2 (String.fromInt posX2)
        , y2 (String.fromInt posY2)
        , strokeWidth "3"
        , stroke color.backgroundColor
        ]
        []


itemView : Settings -> String -> String -> Item -> Color -> Svg Msg
itemView settings posX posY item c =
    g []
        [ rect
            ([ x posX
             , y posY
             , width (String.fromInt itemWidth)
             , height (String.fromInt itemHeight)
             , rx "10"
             , ry "10"
             , strokeWidth "2"
             ]
                ++ (case item.itemType of
                        Stories _ ->
                            [ stroke c.backgroundColor
                            , fill "#FFFFFF"
                            ]

                        _ ->
                            [ fill c.backgroundColor
                            ]
                   )
            )
            []
        , textView settings posX posY item c
        ]


textView : Settings -> String -> String -> Item -> Color -> Svg Msg
textView settings posX posY item c =
    foreignObject
        [ x posX
        , y posY
        , width (String.fromInt itemWidth)
        , height (String.fromInt itemHeight)
        , fill c.backgroundColor
        , case item.itemType of
            Stories _ ->
                color "#000000"

            _ ->
                color c.color
        , fontSize (calcFontSize itemWidth item.text)
        , fontFamily settings.font
        , class "svg-text"
        ]
        [ div
            [ Attr.style "padding" "8px"
            , Attr.style "font-family" ("'" ++ settings.font ++ "', sans-serif")
            , Attr.style "word-wrap" "break-word"
            ]
            [ Html.text item.text ]
        ]
