module Views.ProgressBar exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr


view : Html msg
view =
    Html.div [ Attr.class "progress" ] [ Html.div [ Attr.class "indeterminate" ] [] ]
