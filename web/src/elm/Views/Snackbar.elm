module Views.Snackbar exposing (..)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Models.Snackbar as Snackbar
import Views.Empty as Empty


view : Snackbar.Snackbar msg -> Html msg
view snackbar =
    case snackbar of
        Snackbar.Show model ->
            Html.div
                [ Attr.class "snackbar"
                ]
                [ Html.div [ Attr.class "p-3" ] [ Html.text model.message ]
                , Html.div
                    [ Attr.class "p-3 text-accent cursor-pointer font-bold"
                    , Events.onClick model.action
                    ]
                    [ Html.text model.text ]
                ]

        Snackbar.Hide ->
            Empty.view
