module Views.Editor exposing (view)

import Html exposing (Html, div)
import Html.Attributes exposing (id, style)
import Html.Lazy exposing (lazy2)
import Models.Model exposing (Msg, Settings)
import Route exposing (Route(..))
import Styles


view : Maybe String -> Settings -> Html Msg
view dropDownIndex settings =
    div
        (style "background-color" "#273037" :: Styles.matchParent)
        [ div
            (Styles.matchParent
                ++ [ id "editor"
                   ]
            )
            []
        ]
