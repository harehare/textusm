module Views.Share exposing (view)

import Html exposing (Html, div, input, text)
import Html.Attributes exposing (class, id, readonly, style, value)
import Html.Events exposing (onClick)
import Models.Model exposing (Msg(..))


view : String -> String -> Html Msg
view embedUrl url =
    div [ class "share" ]
        [ div
            [ style "font-weight" "600"
            , style "padding" "16px"
            , style "display" "flex"
            , style "align-items" "center"
            , style "justify-content" "flex-start"
            ]
            [ div [ class "title" ]
                [ text "Share"
                , link "share-url" "Link to share" url
                , link "embed" "Embed" ("<iframe src=\"" ++ embedUrl ++ "\"  width=\"800\" height=\"600\" frameborder=\"0\" style=\"border:0\" allowfullscreen></iframe>")
                ]
            ]
        ]


link : String -> String -> String -> Html Msg
link elementId label url =
    div [ style "padding-top" "16px" ]
        [ div [ class "label" ] [ text label ]
        , input
            [ class "input"
            , style "color" "#555"
            , style "width" "calc(100% - 40px)"
            , style "border" "1px solid #8C9FAE"
            , readonly True
            , value url
            , id elementId
            , onClick <| SelectAll elementId
            ]
            []
        ]
