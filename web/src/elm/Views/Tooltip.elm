module Views.Tooltip exposing (view)

import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (class)


view : String -> Html msg
view text =
    Html.span [ class "bottom-tooltip" ]
        [ Html.span [ class "text" ] [ Html.text <| text ]
        ]
