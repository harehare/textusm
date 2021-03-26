port module Dialog.Share exposing (Model, Msg(..), init, update, view)

import Data.DiagramId as DiagramId exposing (DiagramId)
import Data.DiagramType as DiagramType
import Data.Session as Session exposing (Session)
import Data.Size as Size exposing (Size)
import Data.Title as Title exposing (Title)
import Events
import GraphQL.Request as Request
import Html exposing (Html, div, input, text)
import Html.Attributes as Attr exposing (class, id, readonly, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Lazy as Lazy
import Return as Return exposing (Return)
import Route exposing (Route(..))
import Task
import TextUSM.Enum.Diagram exposing (Diagram(..))
import Time exposing (Posix, Zone)
import Time.Extra as TimeEx
import Url.Builder exposing (crossOrigin)
import Utils.Date as DateUtils
import Utils.Utils as Utils
import Views.Icon as Icon


type alias Model =
    { empbedSize : Size
    , diagramType : Diagram
    , token : Maybe String
    , title : Title
    , diagramId : DiagramId
    , expireDate : String
    , expireTime : String
    , expioreSecond : Int
    , timeZone : Zone
    , urlCopyState : CopyState
    , embedCopyState : CopyState
    , now : Posix
    , apiRoot : String
    , session : Session
    }


type Msg
    = SelectAll String
    | GotTimeZone Zone
    | GotNow Posix
    | ChangeEmbedWidth String
    | ChangeEmbedHeight String
    | DateChange String
    | TimeChange String
    | Shared (Result String String)
    | UrlCopy
    | UrlCopied
    | EmbedCopy
    | EmbedCopied
    | Close


type CopyState
    = NotCopy
    | Copied


port selectTextById : String -> Cmd msg


port copyText : String -> Cmd msg


sharUrl : Model -> String
sharUrl { token, diagramType } =
    case token of
        Just h ->
            crossOrigin "https://app.textusm.com"
                [ "view"
                , DiagramType.toString diagramType
                , h
                ]
                []

        Nothing ->
            ""


embedUrl : Model -> String
embedUrl { token, diagramType, title, empbedSize } =
    case token of
        Just h ->
            let
                embed =
                    crossOrigin "https://app.textusm.com"
                        [ "embed"
                        , DiagramType.toString diagramType
                        , Title.toString title
                        , h
                        ]
                        []
            in
            "<iframe src=\"" ++ embed ++ "\"  width=\"" ++ String.fromInt (Size.getWidth empbedSize) ++ "\" height=\"" ++ String.fromInt (Size.getHeight empbedSize) ++ "\" frameborder=\"0\" style=\"border:0\" allowfullscreen></iframe>"

        Nothing ->
            ""


share : DiagramId -> Int -> String -> Session -> Return.ReturnF Msg Model
share diagramId expireSecond apiRoot session =
    let
        shareTask =
            Request.share { url = apiRoot, idToken = Session.getIdToken session } (DiagramId.toString diagramId) expireSecond
                |> Task.mapError (\_ -> "Failed to generate URL for sharing.")
    in
    Return.command <| Task.attempt Shared shareTask


init :
    { diagram : Diagram
    , diagramId : DiagramId
    , apiRoot : String
    , session : Session
    , title : Title
    }
    -> Return Msg Model
init { diagram, diagramId, apiRoot, session, title } =
    Return.singleton
        { empbedSize = ( 800, 600 )
        , diagramType = diagram
        , token = Nothing
        , title = title
        , diagramId = diagramId
        , expireDate = ""
        , expireTime = ""
        , expioreSecond = 300
        , timeZone = Time.utc
        , urlCopyState = NotCopy
        , embedCopyState = NotCopy
        , now = Time.millisToPosix 0
        , apiRoot = apiRoot
        , session = session
        }
        |> share diagramId 300 apiRoot session
        |> Return.command (Task.perform GotTimeZone Time.here)
        |> Return.command (Task.perform GotNow Time.now)


update : Msg -> Model -> Return Msg Model
update msg model =
    Return.singleton model
        |> (case msg of
                SelectAll id ->
                    Return.command (selectTextById id)

                ChangeEmbedWidth width ->
                    case String.toInt width of
                        Just w ->
                            Return.andThen <| \m -> Return.singleton { m | empbedSize = ( w, Size.getHeight model.empbedSize ) }

                        Nothing ->
                            Return.zero

                ChangeEmbedHeight height ->
                    case String.toInt height of
                        Just h ->
                            Return.andThen <| \m -> Return.singleton { m | empbedSize = ( Size.getWidth model.empbedSize, h ) }

                        Nothing ->
                            Return.zero

                Shared (Ok token) ->
                    Return.andThen (\m -> Return.singleton { m | token = Just token })

                Shared (Err _) ->
                    Return.zero

                GotTimeZone zone ->
                    Return.andThen (\m -> Return.singleton { m | timeZone = zone })

                GotNow now ->
                    Return.andThen
                        (\m ->
                            let
                                d =
                                    TimeEx.add TimeEx.Second m.expioreSecond m.timeZone now
                            in
                            Return.singleton
                                { m
                                    | expireDate = DateUtils.millisToDateString m.timeZone d
                                    , expireTime = DateUtils.millisToTimeString m.timeZone d
                                    , now = now
                                }
                        )

                UrlCopy ->
                    Return.andThen (\m -> Return.singleton { m | urlCopyState = Copied })
                        >> Return.command (Utils.delay 500 UrlCopied)
                        >> Return.command (copyText <| sharUrl model)

                UrlCopied ->
                    Return.andThen (\m -> Return.singleton { m | urlCopyState = NotCopy })

                EmbedCopy ->
                    Return.andThen (\m -> Return.singleton { m | embedCopyState = Copied })
                        >> Return.command (Utils.delay 500 EmbedCopied)
                        >> Return.command (copyText <| embedUrl model)

                EmbedCopied ->
                    Return.andThen (\m -> Return.singleton { m | embedCopyState = NotCopy })

                DateChange date ->
                    case DateUtils.stringToPosix model.timeZone date model.expireTime of
                        Just d ->
                            let
                                diffSecond =
                                    TimeEx.diff TimeEx.Second model.timeZone model.now d
                            in
                            Return.andThen (\m -> Return.singleton { m | expireDate = date, expioreSecond = diffSecond })
                                >> share model.diagramId diffSecond model.apiRoot model.session

                        Nothing ->
                            Return.zero

                TimeChange time ->
                    case DateUtils.stringToPosix model.timeZone model.expireDate time of
                        Just d ->
                            let
                                diffSecond =
                                    TimeEx.diff TimeEx.Second model.timeZone model.now d
                            in
                            Return.andThen (\m -> Return.singleton { m | expireTime = time, expioreSecond = diffSecond })
                                >> share model.diagramId diffSecond model.apiRoot model.session

                        Nothing ->
                            Return.zero

                Close ->
                    Return.zero
           )


copyButton : CopyState -> Msg -> Html Msg
copyButton copy msg =
    div
        [ class "copy-button"
        , case copy of
            NotCopy ->
                style "width" "32px"

            Copied ->
                style "width" "64px"
        , onClick msg
        ]
        [ case copy of
            NotCopy ->
                Icon.copy "#FEFEFE" 16

            Copied ->
                text "Copied"
        ]


view : Model -> Html Msg
view model =
    div [ class "dialog" ]
        [ div [ class "share" ]
            [ div
                [ class "flex items-center justify-start font-semibold"
                ]
                [ div [ class "w-full" ]
                    [ div []
                        [ div [ class "label" ] [ text "Link to share" ]
                        , div [ class "flex-h-center", style "padding" "8px" ]
                            [ div [ style "margin-right" "8px" ] [ text "expire in" ]
                            , input
                                [ class "input-light text-sm"
                                , style "padding" "4px"
                                , type_ "date"
                                , Attr.min <| DateUtils.millisToDateString model.timeZone model.now
                                , value <| model.expireDate
                                , Events.onChange DateChange
                                ]
                                []
                            , input
                                [ class "input-light text-sm"
                                , style "padding" "4px"
                                , type_ "time"
                                , value <| model.expireTime
                                , Events.onChange TimeChange
                                ]
                                []
                            ]
                        , div [ style "position" "relative", style "padding" "8px" ]
                            [ input
                                [ class "input-light text-sm"
                                , style "color" "#555"
                                , style "width" "305px"
                                , readonly True
                                , value <| sharUrl model
                                , id "share-url"
                                , onClick <| SelectAll "share-url"
                                ]
                                []
                            , Lazy.lazy2 copyButton model.urlCopyState UrlCopy
                            ]
                        ]
                    , div [ style "padding-top" "24px" ]
                        [ div [ class "label", style "display" "flex", style "align-items" "center" ]
                            [ text "Embed"
                            ]
                        , div [ style "display" "flex", style "align-items" "center", style "padding" "8px" ]
                            [ div [ style "margin-right" "8px" ] [ text "embed size" ]
                            , input
                                [ class "input-light text-sm"
                                , type_ "number"
                                , style "color" "#555"
                                , style "width" "60px"
                                , style "height" "32px"
                                , value <| String.fromInt (Size.getWidth model.empbedSize)
                                , onInput ChangeEmbedWidth
                                ]
                                []
                            , div [] [ text "x" ]
                            , input
                                [ class "input-light text-sm"
                                , type_ "number"
                                , style "color" "#555"
                                , style "width" "60px"
                                , style "height" "32px"
                                , value <| String.fromInt (Size.getHeight model.empbedSize)
                                , onInput ChangeEmbedHeight
                                ]
                                []
                            , div [] [ text "px" ]
                            ]
                        , div [ style "position" "relative", style "padding" "8px" ]
                            [ input
                                [ class "input-light text-sm"
                                , style "color" "#555"
                                , style "width" "305px"
                                , readonly True
                                , value <| embedUrl model
                                , id "embed"
                                , onClick <| SelectAll "embed"
                                ]
                                []
                            , Lazy.lazy2 copyButton model.embedCopyState EmbedCopy
                            ]
                        ]
                    ]
                ]
            , div
                [ style "position" "absolute"
                , style "top" "8px"
                , style "right" "8px"
                , onClick Close
                ]
                [ Icon.clear "#FEFEFE" 24 ]
            ]
        ]
