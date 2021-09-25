module Views.Progress exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr
import Views.Loading as Loading


view : Html msg
view =
    Html.div [ Attr.class "absolute top-0 left-0 full-screen z-40 flex-center", Attr.style "background-color" "rgba(39,48,55,0.4)" ]
        [ Html.div [ Attr.class "progress z-50 absolute top-0 left-0" ] [ Html.div [ Attr.class "indeterminate" ] [] ], Loading.view ]
