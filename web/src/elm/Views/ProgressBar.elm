module Views.ProgressBar exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr


view : Html msg
view =
    Html.div [ Attr.class "progress z-50 absolute top-0 left-0" ] [ Html.div [ Attr.class "indeterminate" ] [] ]
