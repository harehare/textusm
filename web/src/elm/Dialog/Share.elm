port module Dialog.Share exposing (CopyState, InputCondition, Model, Msg(..), init, update, view)

import Api.Graphql.Query exposing (ShareCondition)
import Api.Request as Request
import Css
    exposing
        ( absolute
        , alignItems
        , border3
        , borderStyle
        , center
        , color
        , cursor
        , displayFlex
        , height
        , hex
        , justifyContent
        , left
        , none
        , padding
        , padding3
        , paddingTop
        , pct
        , pointer
        , position
        , px
        , relative
        , rem
        , resize
        , right
        , solid
        , start
        , textAlign
        , top
        , transforms
        , translateX
        , translateY
        , width
        )
import Css.Media as Media exposing (withMedia)
import Env
import Events
import Graphql.Enum.Diagram exposing (Diagram)
import Html.Styled exposing (Html, div, input, text, textarea)
import Html.Styled.Attributes as Attr exposing (css, id, maxlength, placeholder, readonly, type_, value)
import Html.Styled.Events exposing (onClick, onFocus, onInput)
import Html.Styled.Lazy as Lazy
import Maybe.Extra as MaybeEx
import Message exposing (Message)
import Models.Color as Color
import Models.DiagramId as DiagramId exposing (DiagramId)
import Models.DiagramType as DiagramType
import Models.Duration as Duration exposing (Duration)
import Models.Email as Email exposing (Email)
import Models.IpAddress as IpAddress exposing (IpAddress)
import Models.Session as Session exposing (Session)
import Models.Size as Size exposing (Size)
import Models.Title as Title exposing (Title)
import RemoteData exposing (RemoteData(..))
import Return exposing (Return)
import Style.Color as Color
import Style.Font as Font
import Style.Style as Style
import Style.Text as Text
import Task exposing (Task)
import Time exposing (Posix, Zone)
import Time.Extra as TimeEx
import Url.Builder as Builder exposing (crossOrigin)
import Utils.Date as DateUtils
import Utils.Utils as Utils
import Views.Empty as Empty
import Views.Icon as Icon
import Views.Spinner as Spinner
import Views.Switch as Switch


type alias InputCondition =
    { input : Maybe String
    , error : Bool
    }


type alias Model =
    { embedSize : Size
    , diagramType : Diagram
    , token : RemoteData Message String
    , title : Title
    , diagramId : DiagramId
    , expireDate : String
    , expireTime : String
    , expireSecond : Duration
    , timeZone : Zone
    , urlCopyState : CopyState
    , embedCopyState : CopyState
    , now : Posix
    , session : Session
    , password : Maybe String
    , ip : InputCondition
    , email : InputCondition
    }


type Msg
    = SelectAll String
    | GotTimeZone Zone
    | GotNow Posix
    | ChangeEmbedWidth String
    | ChangeEmbedHeight String
    | DateChange String
    | TimeChange String
    | Shared (Result Message String)
    | UrlCopy
    | UrlCopied
    | EmbedCopy
    | EmbedCopied
    | Close
    | UsePassword Bool
    | EditPassword String
    | UseLimitByIP Bool
    | UseLimitByEmail Bool
    | EditIP String
    | EditEmail String
    | LoadShareCondition (Result Message ShareCondition)


type CopyState
    = NotCopy
    | Copying
    | Copied


port selectTextById : String -> Cmd msg


port copyText : String -> Cmd msg


sharUrl : RemoteData Message String -> Diagram -> String
sharUrl token diagramType =
    case token of
        Success t ->
            crossOrigin Env.webRoot
                [ "view"
                , DiagramType.toString diagramType
                , t
                ]
                []

        Loading ->
            "Loading..."

        _ ->
            "Loading..."


embedUrl : { token : RemoteData Message String, diagramType : Diagram, title : Title, embedSize : Size } -> String
embedUrl { token, diagramType, title, embedSize } =
    case token of
        Success t ->
            let
                w =
                    Size.getWidth embedSize

                h =
                    Size.getHeight embedSize

                embed =
                    crossOrigin Env.webRoot
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

        Failure _ ->
            "Load error"

        NotAsked ->
            "Not working"


share :
    { diagramId : DiagramId
    , expireSecond : Duration
    , password : Maybe String
    , allowIPList : List IpAddress
    , allowEmail : List Email
    }
    -> Session
    -> Task Message String
share { diagramId, expireSecond, password, allowIPList, allowEmail } session =
    Request.share
        { idToken = Session.getIdToken session
        , itemID = DiagramId.toString diagramId
        , expSecond = expireSecond
        , password = password
        , allowIPList = allowIPList
        , allowEmailList = allowEmail
        }
        |> Task.mapError (\_ -> Message.messageFailedSharing)


shareCondition : DiagramId -> Session -> Task Message (Maybe ShareCondition)
shareCondition diagramId session =
    Request.shareCondition (Session.getIdToken session) (DiagramId.toString diagramId)
        |> Task.mapError (\_ -> Message.messageFailedSharing)


init :
    { diagram : Diagram
    , diagramId : DiagramId
    , session : Session
    , title : Title
    }
    -> Return Msg Model
init { diagram, diagramId, session, title } =
    let
        initTask =
            Task.andThen
                (\cond ->
                    let
                        shareReqTask =
                            Task.andThen
                                (\s ->
                                    Task.andThen
                                        (\now ->
                                            Task.succeed
                                                { allowIPList = []
                                                , token = s
                                                , expireTime = Time.posixToMillis now + 300 * 1000
                                                , allowEmail = []
                                                }
                                        )
                                        Time.now
                                )
                            <|
                                share
                                    { diagramId = diagramId
                                    , expireSecond = Duration.seconds 300
                                    , password = Nothing
                                    , allowIPList = []
                                    , allowEmail = []
                                    }
                                    session
                    in
                    case cond of
                        Just c ->
                            if String.isEmpty c.token then
                                shareReqTask

                            else
                                Task.succeed c

                        Nothing ->
                            shareReqTask
                )
            <|
                shareCondition diagramId session
    in
    Return.singleton
        { embedSize = ( 800, 600 )
        , diagramType = diagram
        , token = NotAsked
        , title = title
        , diagramId = diagramId
        , expireDate = ""
        , expireTime = ""
        , expireSecond = Duration.seconds 300
        , timeZone = Time.utc
        , urlCopyState = NotCopy
        , embedCopyState = NotCopy
        , now = Time.millisToPosix 0
        , session = session
        , password = Nothing
        , ip =
            { input = Nothing
            , error = False
            }
        , email =
            { input = Nothing
            , error = False
            }
        }
        |> (Return.command <| Task.attempt LoadShareCondition initTask)
        |> Return.command (Task.perform GotTimeZone Time.here)
        |> Return.command (Task.perform GotNow Time.now)


validIPList : Maybe String -> List IpAddress
validIPList ipList =
    case
        Maybe.andThen
            (\i ->
                String.lines i
                    |> List.filterMap IpAddress.fromString
                    |> Just
            )
            ipList
    of
        Just ip ->
            ip

        Nothing ->
            []


validEmail : Maybe String -> List Email
validEmail email =
    case
        Maybe.andThen
            (\i ->
                String.lines i
                    |> List.filterMap Email.fromString
                    |> Just
            )
            email
    of
        Just m ->
            m

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
                                    TimeEx.add TimeEx.Second (Duration.toInt m.expireSecond) m.timeZone now
                            in
                            Return.singleton
                                { m
                                    | expireDate = DateUtils.millisToDateString m.timeZone d
                                    , expireTime = DateUtils.millisToTimeString m.timeZone d
                                    , now = now
                                }
                        )

                UrlCopy ->
                    if model.ip.error then
                        Return.zero

                    else
                        let
                            validIP =
                                validIPList model.ip.input

                            ipList =
                                List.map IpAddress.toString validIP
                                    |> String.join "\n"

                            validMail =
                                validEmail model.email.input

                            email =
                                List.map Email.toString validMail
                                    |> String.join "\n"
                        in
                        Return.andThen
                            (\m ->
                                Return.singleton
                                    { m
                                        | urlCopyState = Copying
                                        , ip =
                                            { input = Maybe.andThen (\_ -> Just ipList) m.ip.input
                                            , error = False
                                            }
                                        , email =
                                            { input = Maybe.andThen (\_ -> Just email) m.email.input
                                            , error = False
                                            }
                                    }
                            )
                            >> (Return.command <|
                                    Task.attempt Shared <|
                                        share
                                            { diagramId = model.diagramId
                                            , expireSecond = model.expireSecond
                                            , password = model.password
                                            , allowIPList = validIP
                                            , allowEmail = validMail
                                            }
                                            model.session
                               )

                UrlCopied ->
                    Return.andThen (\m -> Return.singleton { m | urlCopyState = NotCopy })

                EmbedCopy ->
                    if model.ip.error then
                        Return.zero

                    else
                        let
                            validIP =
                                validIPList model.ip.input

                            ipList =
                                List.map IpAddress.toString validIP
                                    |> String.join "\n"

                            validMail =
                                validEmail model.email.input

                            email =
                                List.map Email.toString validMail
                                    |> String.join "\n"
                        in
                        Return.andThen
                            (\m ->
                                Return.singleton
                                    { m
                                        | embedCopyState = Copying
                                        , ip =
                                            { input = Maybe.andThen (\_ -> Just ipList) m.ip.input
                                            , error = False
                                            }
                                        , email =
                                            { input = Maybe.andThen (\_ -> Just email) m.email.input
                                            , error = False
                                            }
                                    }
                            )
                            >> (Return.command <|
                                    Task.attempt Shared <|
                                        share
                                            { diagramId = model.diagramId
                                            , expireSecond = model.expireSecond
                                            , password = model.password
                                            , allowIPList = validIP
                                            , allowEmail = validMail
                                            }
                                            model.session
                               )

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
                                            , expireSecond = Duration.seconds diffSecond
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
                                            , expireSecond = Duration.seconds diffSecond
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
                                    | ip =
                                        { input =
                                            if f then
                                                Just ""

                                            else
                                                Nothing
                                        , error = False
                                        }
                                }
                        )

                UseLimitByEmail f ->
                    Return.andThen
                        (\m ->
                            Return.singleton
                                { m
                                    | email =
                                        { input =
                                            if f then
                                                Just ""

                                            else
                                                Nothing
                                        , error = False
                                        }
                                }
                        )

                EditIP i ->
                    if String.isEmpty i then
                        Return.andThen (\m -> Return.singleton { m | ip = { input = Just i, error = False } })

                    else if (List.length <| validIPList (Just i)) /= (List.length <| String.lines i) then
                        Return.andThen (\m -> Return.singleton { m | ip = { input = Just i, error = True } })

                    else
                        Return.andThen (\m -> Return.singleton { m | ip = { input = Just i, error = False } })

                EditEmail a ->
                    if String.isEmpty a then
                        Return.andThen (\m -> Return.singleton { m | email = { input = Just a, error = False } })

                    else if (List.length <| validEmail (Just a)) /= (List.length <| String.lines a) then
                        Return.andThen (\m -> Return.singleton { m | email = { input = Just a, error = True } })

                    else
                        Return.andThen (\m -> Return.singleton { m | email = { input = Just a, error = False } })

                LoadShareCondition (Ok cond) ->
                    Return.andThen
                        (\m ->
                            Return.singleton
                                { m
                                    | ip =
                                        { input =
                                            if List.isEmpty cond.allowIPList then
                                                Nothing

                                            else
                                                List.map IpAddress.toString cond.allowIPList
                                                    |> String.join "\n"
                                                    |> Just
                                        , error = False
                                        }
                                    , email =
                                        { input =
                                            if List.isEmpty cond.allowEmail then
                                                Nothing

                                            else
                                                List.map Email.toString cond.allowEmail
                                                    |> String.join "\n"
                                                    |> Just
                                        , error = False
                                        }
                                    , token = RemoteData.succeed cond.token
                                    , expireDate = DateUtils.millisToDateString m.timeZone (Time.millisToPosix <| cond.expireTime)
                                    , expireTime = DateUtils.millisToTimeString m.timeZone (Time.millisToPosix <| cond.expireTime)
                                }
                        )

                LoadShareCondition (Err _) ->
                    Return.zero
           )


copyButton : CopyState -> Msg -> Html Msg
copyButton copy msg =
    div
        [ css
            [ Style.flexCenter
            , cursor pointer
            , position absolute
            , top <| px 8
            , right <| px 8
            , height <| px 8
            , Color.bgActivity
            , height <| px 32
            , case copy of
                Copied ->
                    width <| px 64

                _ ->
                    width <| px 32
            ]
        , onClick msg
        ]
        [ case copy of
            NotCopy ->
                Icon.copy (Color.toString Color.white) 16

            Copying ->
                Spinner.small

            Copied ->
                text "Copied"
        ]


view : Model -> Html Msg
view model =
    div [ css [ Style.dialogBackdrop ] ]
        [ div
            [ css
                [ Style.shadowSm
                , top <| pct 50
                , left <| pct 50
                , transforms [ translateX <| pct -50, translateY <| pct -50 ]
                , padding <| rem 1
                , displayFlex
                , Color.bgMain
                , Color.textColor
                , Style.fullScreen
                , Style.roundedNone
                , position absolute
                , withMedia [ Media.all [ Media.minWidth <| px 768 ] ]
                    [ Style.widthAuto, Style.heightAuto, Style.rounded ]
                ]
            ]
            [ div
                [ css [ displayFlex, alignItems center, justifyContent start, Font.fontSemiBold ]
                ]
                [ div [ css [ Style.widthFull ] ]
                    [ div []
                        [ div [ css [ Style.label, padding3 (px 8) (px 8) (px 16) ] ] [ text "Link to share" ]
                        , div [ css [ Style.flexHCenter, Style.paddingSm ] ]
                            [ div [ css [ Text.sm, Style.mrSm ] ] [ text "Expire in" ]
                            , input
                                [ css [ Style.inputLight, Text.sm, Style.paddingXs ]
                                , type_ "date"
                                , Attr.min <| DateUtils.millisToDateString model.timeZone model.now
                                , value <| model.expireDate
                                , Events.onChangeStyled DateChange
                                ]
                                []
                            , input
                                [ css [ Style.inputLight, Text.sm, Style.paddingXs ]
                                , type_ "time"
                                , value <| model.expireTime
                                , Events.onChangeStyled TimeChange
                                ]
                                []
                            ]
                        , div [ css [ Style.flexSpace, Style.paddingSm ] ]
                            [ div [ css [ Text.sm ] ] [ text "Password protection" ]
                            , Switch.view (MaybeEx.isJust model.password) UsePassword
                            ]
                        , case model.password of
                            Just p ->
                                div [ css [ Style.paddingSm ] ]
                                    [ input
                                        [ css [ Style.inputLight, Text.sm, color <| hex "#555555", width <| px 305 ]
                                        , type_ "password"
                                        , placeholder "Password"
                                        , value p
                                        , maxlength 72
                                        , onInput EditPassword
                                        ]
                                        []
                                    ]

                            Nothing ->
                                Empty.view
                        , div [ css [ Style.flexSpace, Style.paddingSm ] ]
                            [ div [ css [ Text.sm ] ] [ text "Limit access by ip address" ]
                            , Switch.view (MaybeEx.isJust model.ip.input) UseLimitByIP
                            ]
                        , case model.ip.input of
                            Just i ->
                                div [ css [ Style.paddingSm ] ]
                                    [ textarea
                                        [ css
                                            [ Style.inputLight
                                            , Text.sm
                                            , resize none
                                            , color <| hex "#555555"
                                            , width <| px 305
                                            , height <| px 100
                                            , if model.ip.error then
                                                border3 (px 3) solid Color.errorColor

                                              else
                                                borderStyle none
                                            ]
                                        , placeholder "127.0.0.1"
                                        , maxlength 150
                                        , onInput EditIP
                                        ]
                                        [ text i ]
                                    , if model.ip.error then
                                        div [ css [ Style.widthFull, Text.sm, Font.fontBold, textAlign right, Color.textError ] ]
                                            [ text "Invalid ip address entered" ]

                                      else
                                        Empty.view
                                    ]

                            Nothing ->
                                Empty.view
                        , div [ css [ Style.flexSpace, Style.paddingSm ] ]
                            [ div [ css [ Text.sm ] ] [ text "Limit access by mail address" ]
                            , Switch.view (MaybeEx.isJust model.email.input) UseLimitByEmail
                            ]
                        , case model.email.input of
                            Just m ->
                                div [ css [ Style.paddingSm ] ]
                                    [ textarea
                                        [ css
                                            [ Style.inputLight
                                            , Text.sm
                                            , resize none
                                            , color <| hex "#555555"
                                            , width <| px 305
                                            , height <| px 100
                                            , if model.email.error then
                                                border3 (px 3) solid Color.errorColor

                                              else
                                                borderStyle none
                                            ]
                                        , placeholder "example@textusm.com"
                                        , maxlength 150
                                        , onInput EditEmail
                                        ]
                                        [ text m ]
                                    , if model.email.error then
                                        div [ css [ Style.widthFull, Text.sm, Font.fontBold, textAlign right, Color.textError ] ]
                                            [ text "Invalid mail address entered" ]

                                      else
                                        Empty.view
                                    ]

                            Nothing ->
                                Empty.view
                        , div [ css [ position relative, Style.paddingSm ] ]
                            [ input
                                [ css
                                    [ Style.inputLight
                                    , Text.sm
                                    , color <| hex "#555555"
                                    , width <| px 305
                                    ]
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
                    , div [ css [ paddingTop <| px 24 ] ]
                        [ div [ css [ Style.label, displayFlex, alignItems center, padding3 (px 8) (px 8) (px 16) ] ]
                            [ text "Embed"
                            ]
                        , div [ css [ displayFlex, alignItems center, Style.paddingSm ] ]
                            [ div [ css [ Text.sm, Style.mrSm ] ] [ text "Embed size" ]
                            , input
                                [ css
                                    [ Style.inputLight
                                    , Text.sm
                                    , color <| hex "#555555"
                                    , width <| px 60
                                    , height <| px 32
                                    ]
                                , type_ "number"
                                , value <| String.fromInt (Size.getWidth model.embedSize)
                                , onInput ChangeEmbedWidth
                                ]
                                []
                            , div [] [ text "x" ]
                            , input
                                [ css
                                    [ Style.inputLight
                                    , Text.sm
                                    , color <| hex "#555555"
                                    , width <| px 60
                                    , height <| px 32
                                    ]
                                , type_ "number"
                                , value <| String.fromInt (Size.getHeight model.embedSize)
                                , onInput ChangeEmbedHeight
                                ]
                                []
                            , div [] [ text "px" ]
                            ]
                        , div [ css [ position relative, Style.paddingSm ] ]
                            [ input
                                [ css
                                    [ Style.inputLight
                                    , Text.sm
                                    , color <| hex "#555555"
                                    , width <| px 305
                                    ]
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
                [ css [ position absolute, cursor pointer, top <| rem 1, right <| rem 1 ]
                , onClick Close
                ]
                [ Icon.times (Color.toString Color.white) 24 ]
            ]
        ]
