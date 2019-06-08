module Views.Tab exposing (view)

import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Models.Model exposing (Msg(..))
import Styles


view : String -> Int -> Html Msg -> Html Msg -> Html Msg
view backgroundColor index view1 view2 =
    div
        (Styles.flex
            ++ [ style "width" "100vw"
               , style "height" "calc(100vh - 136px)"
               , style "flex-direction" "column"
               , style "backgrond-color" "#282C32"
               ]
        )
        [ div
            (Styles.flex
                ++ [ style "width" "100vw"
                   , style "height" "40px"
                   , style "background-color" "#282C32"
                   ]
            )
            [ div
                [ if index == 1 then
                    class "tab-selected"

                  else
                    class "tab"
                , onClick (TabSelect 1)
                ]
                [ text "Editor" ]
            , div
                [ if index == 2 then
                    class "tab-selected"

                  else
                    class "tab"
                , onClick (TabSelect 2)
                ]
                [ text "Diagram" ]
            ]
        , div Styles.matchParent
            [ div
                ((if index == 1 then
                    style "display" "block"

                  else
                    style "display" "none"
                 )
                    :: Styles.matchParent
                )
                [ view1 ]
            , div
                ((if index == 2 then
                    style "display" "block"

                  else
                    style "display" "none"
                 )
                    :: style "background-color" backgroundColor
                    :: Styles.matchParent
                )
                [ view2 ]
            ]
        ]
