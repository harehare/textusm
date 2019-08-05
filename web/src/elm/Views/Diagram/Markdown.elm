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
                ++ String.fromInt model.x
                ++ ","
                ++ String.fromInt model.y
                ++ ")"
            )
        , fill "#F5F5F6"
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
