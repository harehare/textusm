module Views.Tag exposing (view)

import Html exposing (Html, div, input, text)
import Html.Attributes exposing (class, placeholder, style)
import Models.Model exposing (Msg(..))


view : List String -> Html Msg
view tags =
    div [ class "tags" ]
        [ div [ style "font-weight" "400", style "padding" "16px" ] [ text "TAGS" ]
        , div [ class "tag-list" ]
            (List.map tagView tags
                ++ [ input
                        [ class "input"
                        , placeholder "ADD TAG"
                        ]
                        []
                   ]
            )
        ]


tagView : String -> Html Msg
tagView tag =
    div [ class "tag" ] [ text tag ]
