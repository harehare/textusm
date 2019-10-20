module Views.MiniMap exposing (view)

import Html exposing (Html, div)
import Html.Attributes as Attr
import Html.Events.Extra.Mouse as Mouse
import Models.Diagram exposing (Model, Msg(..))
import Svg exposing (Svg, svg)
import Svg.Attributes exposing (width, height, viewBox)


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
        [ Attr.class "minimap"
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
