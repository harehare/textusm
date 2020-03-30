module Views.Diagram.Markdown exposing (view)

import Html.Attributes as Attr
import Markdown
import Models.Diagram as Diagram exposing (Model, Msg)
import Models.Text as Text
import Svg exposing (Svg, foreignObject, g)
import Svg.Attributes exposing (class, fill, height, transform, width, x, y)
import Utils


view : Model -> Svg Msg
view model =
    g
        [ transform
            ("translate("
                ++ String.fromFloat
                    (if isInfinite <| model.x then
                        0

                     else
                        model.x
                    )
                ++ ","
                ++ String.fromFloat
                    (if isInfinite <| model.y then
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
            , height <| String.fromInt (Text.toString model.text |> String.lines |> Utils.getMarkdownHeight)
            ]
            [ Markdown.toHtml
                [ Attr.class "md-content"
                , Attr.style "font-family" ("'" ++ model.settings.font ++ "', sans-serif")
                , Attr.style "color" <| Diagram.getTextColor model.settings.color
                ]
                (Text.toString model.text)
            ]
        ]
