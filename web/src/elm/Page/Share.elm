port module Page.Share exposing (Model, Msg, init, update, view)

import Data.Size as Size exposing (Size)
import Html exposing (Html, div, input, text, textarea)
import Html.Attributes exposing (class, id, readonly, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Return as Return exposing (Return)


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


init : String -> String -> Return Msg Model
init embedUrl url =
    Return.singleton (Model embedUrl ( 800, 600 ) url)


update : Msg -> Model -> Return Msg Model
update msg model =
    case msg of
        SelectAll id ->
            Return.return model (selectTextById id)

        OnInputWidth width ->
            case String.toInt width of
                Just w ->
                    Return.singleton { model | empbedSize = ( w, Size.getHeight model.empbedSize ) }

                Nothing ->
                    Return.singleton model

        OnInputHeight height ->
            case String.toInt height of
                Just h ->
                    Return.singleton { model | empbedSize = ( Size.getWidth model.empbedSize, h ) }

                Nothing ->
                    Return.singleton model


view : Model -> Html Msg
view model =
    div [ class "share" ]
        [ div
            [ class "flex items-center justify-start font-semibold"
            , style "padding" "16px"
            ]
            [ div [ class "w-full" ]
                [ div [ style "padding" "16px" ]
                    [ div [ class "label" ] [ text "Link to share" ]
                    , input
                        [ class "input text-sm"
                        , style "color" "#555"
                        , style "height" "32px"
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
                                [ class "input text-sm"
                                , type_ "number"
                                , style "color" "#555"
                                , style "width" "50px"
                                , style "height" "32px"
                                , style "border" "1px solid #8C9FAE"
                                , value <| String.fromInt (Size.getWidth model.empbedSize)
                                , onInput OnInputWidth
                                ]
                                []
                            , div [] [ text "x" ]
                            , input
                                [ class "input text-sm"
                                , type_ "number"
                                , style "color" "#555"
                                , style "width" "50px"
                                , style "height" "32px"
                                , style "border" "1px solid #8C9FAE"
                                , value <| String.fromInt (Size.getHeight model.empbedSize)
                                , onInput OnInputHeight
                                ]
                                []
                            , div [] [ text "px" ]
                            ]
                        ]
                    , textarea
                        [ class "input text-sm"
                        , style "color" "#555"
                        , style "height" "80px"
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
