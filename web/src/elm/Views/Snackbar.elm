module Views.Snackbar exposing (..)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events


type alias Props msg =
    { message : String
    , action :
        { text : String
        , msg : msg
        }
    }


view : Props msg -> Html msg
view props =
    Html.div
        [ Attr.class "snackbar"
        ]
        [ Html.div [ Attr.class "p-3" ] [ Html.text props.message ]
        , Html.div
            [ Attr.class "p-3 text-accent cursor-pointer font-bold"
            , Events.onClick props.action.msg
            ]
            [ Html.text props.action.text ]
        ]
