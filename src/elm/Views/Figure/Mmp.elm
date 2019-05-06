module Views.Figure.Mmp exposing (view)

import Constants exposing (..)
import Models.Figure exposing (Children(..), ItemType(..), Model, Msg(..))
import String
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (..)
import Svg.Lazy exposing (..)


view : Model -> Svg Msg
view model =
    let
        posX =
            String.fromInt (model.svg.width // 2)

        posY =
            String.fromInt (model.svg.height // 2)
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
        [ rect
            [ x posX
            , y posY
            , width (String.fromInt model.settings.size.width)
            , height
                (String.fromInt model.settings.size.height)
            , fill model.settings.color.activity.backgroundColor
            , rx "10"
            , ry "10"
            ]
            []
        ]
