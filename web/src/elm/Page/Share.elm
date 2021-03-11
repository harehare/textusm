port module Page.Share exposing (Model, Msg(..), init, update, view)

import Data.DiagramId as DiagramId exposing (DiagramId)
import Data.DiagramType as DiagramType
import Data.Session as Session exposing (Session)
import Data.Size as Size exposing (Size)
import Data.Title as Title exposing (Title)
import GraphQL.Request as Request
import Html exposing (Html, div, input, text, textarea)
import Html.Attributes exposing (class, id, readonly, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Return as Return exposing (Return)
import Task
import TextUSM.Enum.Diagram exposing (Diagram(..))
import Url.Builder exposing (crossOrigin)


type alias Model =
    { empbedSize : Size
    , diagramType : Maybe Diagram
    , hashKey : Maybe String
    , title : Title
    }


type Msg
    = SelectAll String
    | OnInputWidth String
    | OnInputHeight String
    | Shared (Result String String)


port selectTextById : String -> Cmd msg


sharUrl : Model -> String
sharUrl { hashKey, diagramType } =
    case hashKey of
        Just h ->
            crossOrigin "https://app.textusm.com"
                [ "view"
                , Maybe.map (\d -> DiagramType.toString d) diagramType |> Maybe.withDefault ""
                , h
                ]
                []

        Nothing ->
            ""


embedUrl : Model -> String
embedUrl { hashKey, diagramType, title, empbedSize } =
    case hashKey of
        Just h ->
            let
                embed =
                    crossOrigin "https://app.textusm.com"
                        [ "embed"
                        , Maybe.map (\d -> DiagramType.toString d) diagramType |> Maybe.withDefault ""
                        , Title.toString title
                        , h
                        ]
                        []
            in
            "<iframe src=\"" ++ embed ++ "\"  width=\"" ++ String.fromInt (Size.getWidth empbedSize) ++ "\" height=\"" ++ String.fromInt (Size.getHeight empbedSize) ++ "\" frameborder=\"0\" style=\"border:0\" allowfullscreen></iframe>"

        Nothing ->
            ""


share : Maybe DiagramId -> String -> Session -> Return.ReturnF Msg Model
share diagramId apiRoot session =
    case diagramId of
        Just id ->
            let
                shareTask =
                    Request.share { url = apiRoot, idToken = Session.getIdToken session } (DiagramId.toString id)
                        |> Task.mapError (\_ -> "Failed to generate URL for sharing.")
            in
            Return.command <| Task.attempt Shared shareTask

        Nothing ->
            Return.zero


init :
    { diagram : Maybe Diagram
    , diagramId : Maybe DiagramId
    , apiRoot : String
    , session : Session
    , title : Title
    }
    -> Return Msg Model
init { diagram, diagramId, apiRoot, session, title } =
    Return.singleton
        { empbedSize = ( 800, 600 )
        , diagramType = diagram
        , hashKey = Nothing
        , title = title
        }
        |> share diagramId apiRoot session


update : Msg -> Model -> Return Msg Model
update msg model =
    Return.singleton model
        |> (case msg of
                SelectAll id ->
                    Return.command (selectTextById id)

                OnInputWidth width ->
                    case String.toInt width of
                        Just w ->
                            Return.andThen <| \m -> Return.singleton { m | empbedSize = ( w, Size.getHeight model.empbedSize ) }

                        Nothing ->
                            Return.zero

                OnInputHeight height ->
                    case String.toInt height of
                        Just h ->
                            Return.andThen <| \m -> Return.singleton { m | empbedSize = ( Size.getWidth model.empbedSize, h ) }

                        Nothing ->
                            Return.zero

                Shared (Ok hashKey) ->
                    Return.andThen (\m -> Return.singleton { m | hashKey = Just hashKey })

                Shared (Err _) ->
                    Return.zero
           )


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
                        , value <| sharUrl model
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
                                , style "width" "60px"
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
                                , style "width" "60px"
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
                        , value <| embedUrl model
                        , id "embed"
                        , onClick <| SelectAll "embed"
                        ]
                        []
                    ]
                ]
            ]
        ]
