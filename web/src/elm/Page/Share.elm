port module Page.Share exposing (Model, Msg, init, update, view)

import Html exposing (Html, div, input, text)
import Html.Attributes exposing (class, id, readonly, style, value)
import Html.Events exposing (onClick)


type alias Model =
    { embedUrl : String
    , url : String
    }


type Msg
    = SelectAll String


port selectTextById : String -> Cmd msg


init : String -> String -> ( Model, Cmd Msg )
init embedUrl url =
    ( Model embedUrl url
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        SelectAll id ->
            ( model, selectTextById id )


view : Model -> Html Msg
view model =
    div [ class "share" ]
        [ div
            [ style "font-weight" "600"
            , style "padding" "16px"
            , style "display" "flex"
            , style "align-items" "center"
            , style "justify-content" "flex-start"
            ]
            [ div [ style "width" "100%" ]
                [ div [ class "page-title" ] [ text "SHARE" ]
                , link "share-url" "Link to share" model.url
                , link "embed" "Embed" ("<iframe src=\"" ++ model.embedUrl ++ "\"  width=\"800\" height=\"600\" frameborder=\"0\" style=\"border:0\" allowfullscreen></iframe>")
                ]
            ]
        ]


link : String -> String -> String -> Html Msg
link elementId label url =
    div [ style "padding" "16px" ]
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
