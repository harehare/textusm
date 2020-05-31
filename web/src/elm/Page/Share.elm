port module Page.Share exposing (Model, Msg, init, update, view)

import Data.Size as Size exposing (Size)
import Html exposing (Html, div, input, text, textarea)
import Html.Attributes exposing (class, id, readonly, style, type_, value)
import Html.Events exposing (onClick, onInput)


type alias Model =
    { embedUrl : String
    , empbedSize : Size
    , url : String
    }


type Msg
    = SelectAll String
    | OnInputWidth String
    | OnInputHeight String


port selectTextById : String -> Cmd msg


init : String -> String -> ( Model, Cmd Msg )
init embedUrl url =
    ( Model embedUrl ( 800, 600 ) url
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        SelectAll id ->
            ( model, selectTextById id )

        OnInputWidth width ->
            case String.toInt width of
                Just w ->
                    ( { model | empbedSize = ( w, Size.getHeight model.empbedSize ) }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        OnInputHeight height ->
            case String.toInt height of
                Just h ->
                    ( { model | empbedSize = ( Size.getWidth model.empbedSize, h ) }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )


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
                [ div [ style "padding" "16px" ]
                    [ div [ class "label" ] [ text "Link to share" ]
                    , input
                        [ class "input"
                        , style "color" "#555"
                        , style "height" "20px"
                        , style "font-size" "0.95rem"
                        , style "width" "calc(100% - 40px)"
                        , style "border" "1px solid #8C9FAE"
                        , readonly True
                        , value model.url
                        , id "share-url"
                        , onClick <| SelectAll "share-url"
                        ]
                        []
                    ]
                , div [ style "padding" "16px" ]
                    [ div [ class "label", style "display" "flex", style "align-items" "center" ]
                        [ text "Embed"
                        , div [ style "display" "flex", style "align-items" "center", style "padding" "0 24px" ]
                            [ div [] [ text "Size:" ]
                            , input
                                [ class "input"
                                , type_ "number"
                                , style "color" "#555"
                                , style "width" "50px"
                                , style "height" "20px"
                                , style "font-size" "0.95rem"
                                , style "border" "1px solid #8C9FAE"
                                , value <| String.fromInt (Size.getWidth model.empbedSize)
                                , onInput OnInputWidth
                                ]
                                []
                            , div [] [ text "x" ]
                            , input
                                [ class "input"
                                , type_ "number"
                                , style "color" "#555"
                                , style "width" "50px"
                                , style "height" "20px"
                                , style "font-size" "0.95rem"
                                , style "border" "1px solid #8C9FAE"
                                , value <| String.fromInt (Size.getHeight model.empbedSize)
                                , onInput OnInputHeight
                                ]
                                []
                            , div [] [ text "px" ]
                            ]
                        ]
                    , textarea
                        [ class "input"
                        , style "color" "#555"
                        , style "height" "40px"
                        , style "font-size" "0.95rem"
                        , style "width" "calc(100% - 40px)"
                        , style "border" "1px solid #8C9FAE"
                        , readonly True
                        , value <| "<iframe src=\"" ++ model.embedUrl ++ "\"  width=\"" ++ String.fromInt (Size.getWidth model.empbedSize) ++ "\" height=\"" ++ String.fromInt (Size.getHeight model.empbedSize) ++ "\" frameborder=\"0\" style=\"border:0\" allowfullscreen></iframe>"
                        , id "embed"
                        , onClick <| SelectAll "embed"
                        ]
                        []
                    ]
                ]
            ]
        ]
