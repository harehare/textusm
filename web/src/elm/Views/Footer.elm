module Views.Footer exposing (view)

import Env
import Html exposing (Html)
import Html.Attributes as Attr


view : Html msg
view =
    Html.div
        [ Attr.class "h-8"
        , Attr.class "bg-main"
        , Attr.class "w-screen"
        , Attr.class "relative"
        , Attr.class "shadow-sm"
        , Attr.class "flex"
        , Attr.class "items-center"
        , Attr.class "justify-end"
        ]
        [ Html.div
            [ Attr.class "text-secondary-color"
            , Attr.class "text-xs"
            , Attr.class "font-bold"
            , Attr.class "pr-sm"
            ]
            [ Html.text Env.appVersion ]
        ]
