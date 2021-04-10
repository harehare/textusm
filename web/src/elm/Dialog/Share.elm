port module Dialog.Share exposing (Model, Msg(..), init, update, view)

import Data.DiagramId as DiagramId exposing (DiagramId)
import Data.DiagramType as DiagramType
import Data.IPAddress as IPAddress exposing (IPAddress)
import Data.Session as Session exposing (Session)
import Data.Size as Size exposing (Size)
import Data.Title as Title exposing (Title)
import Events
import GraphQL.Request as Request
import Html exposing (Html, div, input, text, textarea)
import Html.Attributes as Attr exposing (class, id, maxlength, placeholder, readonly, style, type_, value)
import Html.Events exposing (onClick, onFocus, onInput)
import Html.Lazy as Lazy
import Maybe.Extra as MaybeEx
import RemoteData exposing (RemoteData(..))
import Return as Return exposing (Return)
import Route exposing (Route(..))
import Task
import TextUSM.Enum.Diagram exposing (Diagram(..))
import Time exposing (Posix, Zone)
import Time.Extra as TimeEx
import Url.Builder as Builder exposing (crossOrigin)
import Utils.Date as DateUtils
import Utils.Utils as Utils
import Views.Empty as Empty
import Views.Icon as Icon
import Views.Spinner as Spinner
import Views.Switch as Switch


type alias Model =
    { embedSize : Size
    , diagramType : Diagram
    , token : RemoteData String String
    , title : Title
    , diagramId : DiagramId
    , expireDate : String
    , expireTime : String
    , expireSecond : Int
    , timeZone : Zone
    , urlCopyState : CopyState
    , embedCopyState : CopyState
    , now : Posix
    , apiRoot : String
    , session : Session
    , password : Maybe String
    , allowIP : Maybe String
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
    | UsePassword Bool
    | EditPassword String
    | UseLimitByIP Bool
    | EditIP String


type CopyState
    = NotCopy
    | Copying
    | Copied


port selectTextById : String -> Cmd msg


port copyText : String -> Cmd msg


sharUrl : RemoteData String String -> Diagram -> String
sharUrl token diagramType =
    case token of
        Success t ->
            crossOrigin "https://app.textusm.com"
                [ "view"
                , DiagramType.toString diagramType
                , t
                ]
                []

        Loading ->
            "Loading..."

        _ ->
            "Loading..."


embedUrl : { token : RemoteData String String, diagramType : Diagram, title : Title, embedSize : Size } -> String
embedUrl { token, diagramType, title, embedSize } =
    case token of
        Success t ->
            let
                w =
                    Size.getWidth embedSize

                h =
                    Size.getHeight embedSize

                embed =
                    crossOrigin "https://app.textusm.com"
                        [ "embed"
                        , DiagramType.toString diagramType
                        , Title.toString title
                        , t
                        ]
                        [ Builder.int "w" w, Builder.int "h" h ]
            in
            "<iframe src=\"" ++ embed ++ "\"  width=\"" ++ String.fromInt w ++ "\" height=\"" ++ String.fromInt h ++ "\" frameborder=\"0\" style=\"border:0\" allowfullscreen></iframe>"

        Loading ->
            "Loading..."

        _ ->
            "Loading..."


share : { diagramId : DiagramId, expireSecond : Int, password : Maybe String, allowIPList : List IPAddress } -> String -> Session -> Return.ReturnF Msg Model
share { diagramId, expireSecond, password, allowIPList } apiRoot session =
    let
        shareTask =
            Request.share { url = apiRoot, idToken = Session.getIdToken session } (DiagramId.toString diagramId) expireSecond password allowIPList
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
        { embedSize = ( 800, 600 )
        , diagramType = diagram
        , token = NotAsked
        , title = title
        , diagramId = diagramId
        , expireDate = ""
        , expireTime = ""
        , expireSecond = 300
        , timeZone = Time.utc
        , urlCopyState = NotCopy
        , embedCopyState = NotCopy
        , now = Time.millisToPosix 0
        , apiRoot = apiRoot
        , session = session
        , password = Nothing
        , allowIP = Nothing
        }
        |> share { diagramId = diagramId, expireSecond = 300, password = Nothing, allowIPList = [] } apiRoot session
        |> Return.command (Task.perform GotTimeZone Time.here)
        |> Return.command (Task.perform GotNow Time.now)


validIPList : Maybe String -> List IPAddress
validIPList ipList =
    case
        Maybe.andThen
            (\i ->
                String.lines i
                    |> List.map IPAddress.fromString
                    |> List.filter MaybeEx.isJust
                    |> List.map (Maybe.withDefault IPAddress.localhost)
                    |> Just
            )
            ipList
    of
        Just ip ->
            ip

        Nothing ->
            []


update : Msg -> Model -> Return Msg Model
update msg model =
    Return.singleton model
        |> (case msg of
                SelectAll id ->
                    Return.command (selectTextById id)

                ChangeEmbedWidth width ->
                    case String.toInt width of
                        Just w ->
                            Return.andThen <| \m -> Return.singleton { m | embedSize = ( w, Size.getHeight model.embedSize ) }

                        Nothing ->
                            Return.zero

                ChangeEmbedHeight height ->
                    case String.toInt height of
                        Just h ->
                            Return.andThen <| \m -> Return.singleton { m | embedSize = ( Size.getWidth model.embedSize, h ) }

                        Nothing ->
                            Return.zero

                Shared (Ok token) ->
                    Return.andThen (\m -> Return.singleton { m | token = Success token })
                        >> (case ( model.urlCopyState, model.embedCopyState ) of
                                ( Copying, _ ) ->
                                    Return.command (Utils.delay 500 UrlCopied)
                                        >> Return.andThen (\m -> Return.singleton { m | urlCopyState = Copied })
                                        >> Return.command (copyText <| sharUrl (Success token) model.diagramType)

                                ( _, Copying ) ->
                                    Return.command (Utils.delay 500 EmbedCopied)
                                        >> Return.andThen (\m -> Return.singleton { m | embedCopyState = Copied })
                                        >> Return.command (copyText <| embedUrl { token = Success token, diagramType = model.diagramType, title = model.title, embedSize = model.embedSize })

                                _ ->
                                    Return.zero
                           )

                Shared (Err e) ->
                    Return.andThen (\m -> Return.singleton { m | token = Failure e })

                GotTimeZone zone ->
                    Return.andThen (\m -> Return.singleton { m | timeZone = zone })

                GotNow now ->
                    Return.andThen
                        (\m ->
                            let
                                d =
                                    TimeEx.add TimeEx.Second m.expireSecond m.timeZone now
                            in
                            Return.singleton
                                { m
                                    | expireDate = DateUtils.millisToDateString m.timeZone d
                                    , expireTime = DateUtils.millisToTimeString m.timeZone d
                                    , now = now
                                }
                        )

                UrlCopy ->
                    let
                        validIP =
                            validIPList model.allowIP

                        ipList =
                            List.map IPAddress.toString validIP
                                |> String.join "\n"
                    in
                    Return.andThen
                        (\m ->
                            Return.singleton
                                { m
                                    | urlCopyState = Copying
                                    , allowIP = Maybe.andThen (\_ -> Just ipList) m.allowIP
                                }
                        )
                        >> share
                            { diagramId = model.diagramId
                            , expireSecond = model.expireSecond
                            , password = model.password
                            , allowIPList = validIP
                            }
                            model.apiRoot
                            model.session

                UrlCopied ->
                    Return.andThen (\m -> Return.singleton { m | urlCopyState = NotCopy })

                EmbedCopy ->
                    let
                        validIP =
                            validIPList model.allowIP

                        ipList =
                            List.map IPAddress.toString validIP
                                |> String.join "\n"
                    in
                    Return.andThen
                        (\m ->
                            Return.singleton
                                { m
                                    | embedCopyState = Copying
                                    , allowIP = Maybe.andThen (\_ -> Just ipList) m.allowIP
                                }
                        )
                        >> share { diagramId = model.diagramId, expireSecond = model.expireSecond, password = model.password, allowIPList = validIP } model.apiRoot model.session

                EmbedCopied ->
                    Return.andThen (\m -> Return.singleton { m | embedCopyState = NotCopy })

                DateChange date ->
                    case DateUtils.stringToPosix model.timeZone date model.expireTime of
                        Just d ->
                            let
                                diffSecond =
                                    TimeEx.diff TimeEx.Second model.timeZone model.now d
                            in
                            Return.andThen
                                (\m ->
                                    Return.singleton
                                        { m
                                            | expireDate = date
                                            , expireSecond = diffSecond
                                        }
                                )

                        Nothing ->
                            Return.zero

                TimeChange time ->
                    case DateUtils.stringToPosix model.timeZone model.expireDate time of
                        Just d ->
                            let
                                diffSecond =
                                    TimeEx.diff TimeEx.Second model.timeZone model.now d
                            in
                            Return.andThen
                                (\m ->
                                    Return.singleton
                                        { m
                                            | expireTime = time
                                            , expireSecond = diffSecond
                                        }
                                )

                        Nothing ->
                            Return.zero

                Close ->
                    Return.zero

                EditPassword p ->
                    Return.andThen (\m -> Return.singleton { m | password = Just p })

                UsePassword f ->
                    Return.andThen
                        (\m ->
                            Return.singleton
                                { m
                                    | password =
                                        if f then
                                            Just ""

                                        else
                                            Nothing
                                }
                        )

                UseLimitByIP f ->
                    Return.andThen
                        (\m ->
                            Return.singleton
                                { m
                                    | allowIP =
                                        if f then
                                            Just ""

                                        else
                                            Nothing
                                }
                        )

                EditIP i ->
                    Return.andThen (\m -> Return.singleton { m | allowIP = Just i })
           )


copyButton : CopyState -> Msg -> Html Msg
copyButton copy msg =
    div
        [ class "copy-button"
        , case copy of
            Copied ->
                style "width" "64px"

            _ ->
                style "width" "32px"
        , onClick msg
        ]
        [ case copy of
            NotCopy ->
                Icon.copy "#FEFEFE" 16

            Copying ->
                Spinner.small

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
                        [ div [ class "label", style "padding" "8px 8px 16px" ] [ text "Link to share" ]
                        , div [ class "flex-h-center", style "padding" "8px" ]
                            [ div [ class "text-sm", style "margin-right" "8px" ] [ text "Expire in" ]
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
                        , div [ class "flex-space", style "padding" "8px" ]
                            [ div [ class "text-sm" ] [ text "Password protection" ]
                            , Switch.view (MaybeEx.isJust model.password) UsePassword
                            ]
                        , case model.password of
                            Just p ->
                                div [ style "padding" "8px" ]
                                    [ input
                                        [ class "input-light text-sm"
                                        , type_ "password"
                                        , placeholder "Password"
                                        , style "color" "#555"
                                        , style "width" "305px"
                                        , value p
                                        , maxlength 72
                                        , onInput EditPassword
                                        ]
                                        []
                                    ]

                            Nothing ->
                                Empty.view
                        , div [ class "flex-space", style "padding" "8px" ]
                            [ div [ class "text-sm" ] [ text "Limit Access By IP Address" ]
                            , Switch.view (MaybeEx.isJust model.allowIP) UseLimitByIP
                            ]
                        , case model.allowIP of
                            Just i ->
                                div [ style "padding" "8px" ]
                                    [ textarea
                                        [ class "input-light text-sm"
                                        , placeholder "127.0.0.1"
                                        , style "resize" "none"
                                        , style "color" "#555"
                                        , style "width" "305px"
                                        , style "height" "100px"
                                        , maxlength 150
                                        , onInput EditIP
                                        ]
                                        [ text i ]
                                    ]

                            Nothing ->
                                Empty.view
                        , div [ style "position" "relative", style "padding" "8px" ]
                            [ input
                                [ class "input-light text-sm"
                                , style "color" "#555"
                                , style "width" "305px"
                                , readonly True
                                , value <| sharUrl model.token model.diagramType
                                , id "share-url"
                                , onClick <| SelectAll "share-url"
                                , onFocus UrlCopy
                                ]
                                []
                            , Lazy.lazy2 copyButton model.urlCopyState UrlCopy
                            ]
                        ]
                    , div [ style "padding-top" "24px" ]
                        [ div [ class "label", style "padding" "8px 8px 16px", style "display" "flex", style "align-items" "center" ]
                            [ text "Embed"
                            ]
                        , div [ style "display" "flex", style "align-items" "center", style "padding" "8px" ]
                            [ div [ class "text-sm", style "margin-right" "8px" ] [ text "Embed size" ]
                            , input
                                [ class "input-light text-sm"
                                , type_ "number"
                                , style "color" "#555"
                                , style "width" "60px"
                                , style "height" "32px"
                                , value <| String.fromInt (Size.getWidth model.embedSize)
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
                                , value <| String.fromInt (Size.getHeight model.embedSize)
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
                                , value <| embedUrl { token = model.token, diagramType = model.diagramType, title = model.title, embedSize = model.embedSize }
                                , id "embed"
                                , onClick <| SelectAll "embed"
                                , onFocus EmbedCopy
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
                , style "cursor" "pointer"
                , onClick Close
                ]
                [ Icon.times "#FEFEFE" 24 ]
            ]
        ]
