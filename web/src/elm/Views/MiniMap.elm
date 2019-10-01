module Views.MiniMap exposing (view)

import Html exposing (Html, div)
import Html.Attributes as Attr
import Html.Events.Extra.Mouse as Mouse
import Models.Diagram exposing (Model, Msg(..))
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (..)
import Svg.Lazy exposing (..)


view : Model -> ( String, String ) -> Svg Msg -> Html Msg
view model ( svgWidth, svgHeight ) mainSvg =
    let
        baseWidth =
            toFloat <| Maybe.withDefault 0 <| String.toInt <| svgWidth

        baseHeight =
            toFloat <| Maybe.withDefault 0 <| String.toInt <| svgHeight

        rate =
            if baseWidth > baseHeight then
                baseHeight / baseWidth

            else if baseHeight > baseWidth then
                baseWidth / baseHeight

            else
                1

        newHeight =
            String.fromFloat <| 220 * rate
    in
    div
        [ Attr.style "position" "absolute"
        , Attr.style "cursor" "pointer"
        , Attr.style "left" "1px"
        , Attr.style "bottom" "-8px"
        , Attr.style "width" "220px"
        , Attr.style "z-index" "1000"
        , Attr.style "border-radius" "2px"
        , Attr.style "background-color" "transparent"
        , Attr.style "box-shadow" "0 2px 4px -1px rgba(0, 0, 0, 0.2), 0 4px 5px 0 rgba(0, 0, 0, 0.14), 0 1px 10px 0 rgba(0, 0, 0, 0.12)"
        , Attr.style "transition" "all 0.2s ease-out"
        , Mouse.onDown
            (\event ->
                let
                    ( x, y ) =
                        event.offsetPos
                            |> Tuple.mapFirst (\w -> 0 - w * (toFloat (String.toInt svgWidth |> Maybe.withDefault 1) / toFloat model.width) * (2.0 - model.svg.scale))
                            |> Tuple.mapSecond (\h -> 0 - h * (toFloat (String.toInt svgHeight |> Maybe.withDefault 1) / toFloat model.height * (2.0 - model.svg.scale)))
                in
                MoveTo (round x) (round y)
            )
        ]
        [ svg
            [ width "220"
            , height newHeight
            , viewBox ("0 0 " ++ svgWidth ++ " " ++ svgHeight)
            , Attr.style "background-color" model.settings.backgroundColor
            ]
            [ mainSvg ]
        ]
