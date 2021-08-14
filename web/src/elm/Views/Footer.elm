module Views.Footer exposing (view)

import Env
import Html exposing (Html)
import Html.Attributes as Attr
import Views.Icon as Icon


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
        [ Html.div [ Attr.class "p-2", Attr.class "cursor-pointer" ]
            [ Html.a
                [ Attr.href Env.repoUrl
                , Attr.target "_blank"
                , Attr.rel "noopener noreferrer"
                ]
                [ Icon.github "#b9b9b9" 16 ]
            ]
        , Html.div
            [ Attr.class "text-secondary-color"
            , Attr.class "text-xs"
            , Attr.class "font-bold"
            , Attr.class "pr-sm"
            ]
            [ Html.text Env.appVersion ]
        ]
