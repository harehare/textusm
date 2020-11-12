module Views.Diagram.Markdown exposing (view)

import Data.Size as Size
import Data.Text as Text
import Html.Attributes as Attr
import Markdown
import Models.Diagram as Diagram exposing (Model, Msg)
import Svg exposing (Svg, foreignObject, g)
import Svg.Attributes exposing (class, height, style, width, x, y)
import Utils.Diagram as DiagramUtils


view : Model -> Svg Msg
view model =
    g
        []
        [ foreignObject
            [ x "0"
            , y "0"
            , width <| String.fromInt (Size.getWidth model.size)
            , height <| String.fromInt (Text.toString model.text |> String.lines |> DiagramUtils.getMarkdownHeight)
            ]
            [ Markdown.toHtml
                [ Attr.class "md-content"
                , Attr.style "font-family" ("'" ++ model.settings.font ++ "', sans-serif")
                , Attr.style "color" <| Diagram.getTextColor model.settings.color
                ]
                (Text.toString model.text)
            ]
        ]
