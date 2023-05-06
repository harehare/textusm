module Views.Tooltip exposing (docs, view)

import ElmBook.Chapter as Chapter exposing (Chapter)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr


view : String -> Html msg
view text =
    Html.span [ Attr.class "bottom-tooltip" ]
        [ Html.span [ Attr.class "text" ] [ Html.text <| text ]
        ]


docs : Chapter x
docs =
    Chapter.chapter "Tooltip"
        |> Chapter.renderComponent
            (view "tooltip" |> Html.toUnstyled)
