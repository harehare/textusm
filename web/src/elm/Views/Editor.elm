module Views.Editor exposing (view)

import Html exposing (Html, div)
import Html.Attributes exposing (id, style)
import Html.Lazy exposing (lazy)
import Models.Model exposing (Msg, Settings)
import Route exposing (Route(..))
import Styles
import Views.Help as Help
import Views.Settings as Settings


view : Settings -> Route -> Html Msg
view settings route =
    div
        (style "background-color" "#272c32" :: Styles.matchParent)
        [ if route == Route.Settings then
            div
                Styles.matchParent
                [ lazy Settings.view settings
                ]

          else if route == Route.Help then
            div
                Styles.matchParent
                [ Help.view
                ]

          else
            div
                (Styles.matchParent
                    ++ [ id "editor"
                       ]
                )
                []
        ]
