module View.Tooltip exposing (docs, view)

import ElmBook.Chapter as Chapter exposing (Chapter)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Style.Color as ColorStyle
import Style.Global as GlobalStyle
import Style.Style


view : String -> Html msg
view text =
    Html.span [ Attr.class "bottom-tooltip" ]
        [ Html.span [ Attr.class "text" ] [ Html.text <| text ]
        ]


docs : Chapter x
docs =
    Chapter.chapter "Tooltip"
        |> Chapter.renderComponent
            (Html.div [ Attr.css [ ColorStyle.bgMain, ColorStyle.textLight, Style.Style.paddingSm ] ] [ GlobalStyle.style, view "tooltip", Html.text "test" ] |> Html.toUnstyled)
