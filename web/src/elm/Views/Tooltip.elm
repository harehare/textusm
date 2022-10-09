module Views.Tooltip exposing (view)

import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr


view : String -> Html msg
view text =
    Html.span [ Attr.class "bottom-tooltip" ]
        [ Html.span [ Attr.class "text" ] [ Html.text <| text ]
        ]
