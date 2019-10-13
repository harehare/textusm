module Views.Diagram.Markdown exposing (view)

import Constants exposing (..)
import Html.Attributes as Attr
import Markdown
import Models.Diagram exposing (Model, Msg)
import Svg exposing (Svg, foreignObject, g)
import Svg.Attributes exposing (..)
import Utils


view : Model -> Svg Msg
view model =
    g
        [ transform
            ("translate("
                ++ String.fromInt
                    (if isInfinite <| toFloat <| model.x then
                        0

                     else
                        model.x
                    )
                ++ ","
                ++ String.fromInt
                    (if isInfinite <| toFloat <| model.y then
                        0

                     else
                        model.y
                    )
                ++ ")"
            )
        , fill model.settings.backgroundColor
        ]
        [ foreignObject
            [ x "0"
            , y "0"
            , width <| String.fromInt model.width
            , height <| String.fromInt (model.text |> Maybe.withDefault "" |> String.lines |> Utils.getMarkdownHeight)
            ]
            [ Markdown.toHtml
                [ Attr.class "md-content"
                , Attr.style "font-family" ("'" ++ model.settings.font ++ "', sans-serif")
                ]
                (model.text |> Maybe.withDefault "")
            ]
        ]
