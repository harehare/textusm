module Views.Diagram.Markdown exposing (view)

import Data.Position as Position
import Data.Size as Size
import Data.Text as Text
import Html.Attributes as Attr
import Markdown
import Models.Diagram as Diagram exposing (Model, Msg)
import Svg exposing (Svg, foreignObject, g)
import Svg.Attributes exposing (class, fill, height, transform, width, x, y)
import Utils


view : Model -> Svg Msg
view model =
    g
        [ transform
            ("translate("
                ++ String.fromInt (Position.getX model.position)
                ++ ","
                ++ String.fromInt (Position.getY model.position)
                ++ "), scale("
                ++ String.fromFloat model.svg.scale
                ++ ","
                ++ String.fromFloat model.svg.scale
                ++ ")"
            )
        , fill model.settings.backgroundColor
        ]
        [ foreignObject
            [ x "0"
            , y "0"
            , width <| String.fromInt (Size.getWidth model.size)
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
