module Views.Editor exposing (view)

import Html exposing (Html, div)
import Html.Attributes exposing (id, style)
import Html.Lazy exposing (lazy2)
import Models.Model exposing (Msg, Settings)
import Route exposing (Route(..))
import Styles
import Views.Help as Help
import Views.Settings as Settings


view : Maybe String -> Settings -> Route -> Html Msg
view dropDownIndex settings route =
    div
        (style "background-color" "#273037" :: Styles.matchParent)
        [ if route == Route.Settings then
            div
                Styles.matchParent
                [ lazy2 Settings.view dropDownIndex settings
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
