port module Dialog.Share exposing (CopyState, InputCondition, Model, Msg(..), init, update, view)

import Api.Graphql.Query exposing (ShareCondition)
import Api.Request as Request
import Bool.Extra as BoolEx
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
import Env
import Events
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Html.Styled.Events exposing (onClick, onFocus, onInput)
import Html.Styled.Lazy as Lazy
import Maybe.Extra as MaybeEx
import Message exposing (Message)
import Models.Color as Color
import Models.Diagram.Id as DiagramId exposing (DiagramId)
import Models.Diagram.Type as DiagramType exposing (DiagramType)
import Models.Duration as Duration exposing (Duration)
import Models.Email as Email exposing (Email)
import Models.IpAddress as IpAddress exposing (IpAddress)
import Models.Session as Session exposing (Session)
import Models.Size as Size exposing (Size)
import Models.Title as Title exposing (Title)
import Ports
import RemoteData exposing (RemoteData(..))
import Return exposing (Return)
import Style.Breakpoint as Breakpoint
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
    , diagramType : DiagramType
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


sharUrl : RemoteData Message String -> DiagramType -> String
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


embedUrl : { token : RemoteData Message String, diagramType : DiagramType, title : Title, embedSize : Size } -> String
embedUrl { token, diagramType, title, embedSize } =
    case token of
        Success t ->
            let
                w : Int
                w =
                    Size.getWidth embedSize

                h : Int
                h =
                    Size.getHeight embedSize

                embed : String
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
    { diagram : DiagramType
    , diagramId : DiagramId
    , session : Session
    , title : Title
    }
    -> Return Msg Model
init { diagram, diagramId, session, title } =
    let
        initTask :
            Task
                Message
                { allowIPList : List IpAddress
                , token : String
                , expireTime : Int
                , allowEmail : List Email
                }
        initTask =
            Task.andThen
                (\cond ->
                    let
                        shareReqTask :
                            Task
                                Message
                                { allowIPList : List IpAddress
                                , token : String
                                , expireTime : Int
                                , allowEmail : List Email
                                }
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
        Maybe.map
            (\i ->
                String.lines i
                    |> List.filterMap IpAddress.fromString
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
        Maybe.map
            (\i ->
                String.lines i
                    |> List.filterMap Email.fromString
            )
            email
    of
        Just m ->
            m

        Nothing ->
            []


update : Model -> Msg -> Return.ReturnF Msg Model
update model msg =
    case msg of
        SelectAll id ->
            Return.command (selectTextById id)

        GotTimeZone zone ->
            Return.map (\m -> { m | timeZone = zone })

        GotNow now ->
            Return.map
                (\m ->
                    let
                        d : Posix
                        d =
                            TimeEx.add TimeEx.Second (Duration.toInt m.expireSecond) m.timeZone now
                    in
                    { m
                        | expireDate = DateUtils.millisToDateString m.timeZone d
                        , expireTime = DateUtils.millisToTimeString m.timeZone d
                        , now = now
                    }
                )

        ChangeEmbedWidth width ->
            String.toInt width
                |> Maybe.map
                    (\w ->
                        Return.map <| \m -> { m | embedSize = ( w, Size.getHeight model.embedSize ) }
                    )
                |> Maybe.withDefault Return.zero

        ChangeEmbedHeight height ->
            String.toInt height
                |> Maybe.map
                    (\h ->
                        Return.map <| \m -> { m | embedSize = ( Size.getWidth model.embedSize, h ) }
                    )
                |> Maybe.withDefault Return.zero

        DateChange date ->
            DateUtils.stringToPosix model.timeZone date model.expireTime
                |> Maybe.map
                    (\d ->
                        Return.map (\m -> { m | expireDate = date, expireSecond = Duration.seconds <| TimeEx.diff TimeEx.Second model.timeZone model.now d })
                    )
                |> Maybe.withDefault Return.zero

        TimeChange time ->
            DateUtils.stringToPosix model.timeZone model.expireDate time
                |> Maybe.map
                    (\d ->
                        Return.map
                            (\m ->
                                { m
                                    | expireTime = time
                                    , expireSecond = Duration.seconds <| TimeEx.diff TimeEx.Second model.timeZone model.now d
                                }
                            )
                    )
                |> Maybe.withDefault Return.zero

        Shared (Ok token) ->
            Return.andThen (\m -> Return.singleton { m | token = Success token })
                >> (case ( model.urlCopyState, model.embedCopyState ) of
                        ( Copying, _ ) ->
                            Return.command (Utils.delay 500 UrlCopied)
                                >> Return.andThen (\m -> Return.singleton { m | urlCopyState = Copied })
                                >> Return.command (Ports.copyText <| sharUrl (Success token) model.diagramType)

                        ( _, Copying ) ->
                            Return.command (Utils.delay 500 EmbedCopied)
                                >> Return.andThen (\m -> Return.singleton { m | embedCopyState = Copied })
                                >> Return.command (Ports.copyText <| embedUrl { token = Success token, diagramType = model.diagramType, title = model.title, embedSize = model.embedSize })

                        _ ->
                            Return.zero
                   )

        Shared (Err e) ->
            Return.map (\m -> { m | token = Failure e })

        UrlCopy ->
            if model.ip.error then
                Return.zero

            else
                let
                    validIP : List IpAddress
                    validIP =
                        validIPList model.ip.input

                    ipList : String
                    ipList =
                        List.map IpAddress.toString validIP
                            |> String.join "\n"

                    validMail : List Email
                    validMail =
                        validEmail model.email.input

                    email : String
                    email =
                        List.map Email.toString validMail
                            |> String.join "\n"
                in
                Return.map
                    (\m ->
                        { m
                            | urlCopyState = Copying
                            , ip =
                                { input = Maybe.map (\_ -> ipList) m.ip.input
                                , error = False
                                }
                            , email =
                                { input = Maybe.map (\_ -> email) m.email.input
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
            Return.map (\m -> { m | urlCopyState = NotCopy })

        EmbedCopy ->
            if model.ip.error then
                Return.zero

            else
                let
                    validIP : List IpAddress
                    validIP =
                        validIPList model.ip.input

                    ipList : String
                    ipList =
                        List.map IpAddress.toString validIP
                            |> String.join "\n"

                    validMail : List Email
                    validMail =
                        validEmail model.email.input

                    email : String
                    email =
                        List.map Email.toString validMail
                            |> String.join "\n"
                in
                Return.map
                    (\m ->
                        { m
                            | embedCopyState = Copying
                            , ip =
                                { input = Maybe.map (\_ -> ipList) m.ip.input
                                , error = False
                                }
                            , email =
                                { input = Maybe.map (\_ -> email) m.email.input
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
            Return.map <| \m -> { m | embedCopyState = NotCopy }

        Close ->
            Return.zero

        UsePassword f ->
            Return.map <| \m -> { m | password = BoolEx.toMaybe "" f }

        EditPassword p ->
            Return.map <| \m -> { m | password = Just p }

        UseLimitByIP f ->
            Return.map <| \m -> { m | ip = { input = BoolEx.toMaybe "" f, error = False } }

        UseLimitByEmail f ->
            Return.map <| \m -> { m | email = { input = BoolEx.toMaybe "" f, error = False } }

        EditIP i ->
            if String.isEmpty i then
                Return.map <| \m -> { m | ip = { input = Just i, error = False } }

            else if (List.length <| validIPList (Just i)) /= (List.length <| String.lines i) then
                Return.map <| \m -> { m | ip = { input = Just i, error = True } }

            else
                Return.map <| \m -> { m | ip = { input = Just i, error = False } }

        EditEmail a ->
            if String.isEmpty a then
                Return.map <| \m -> { m | email = { input = Just a, error = False } }

            else if (List.length <| validEmail (Just a)) /= (List.length <| String.lines a) then
                Return.map <| \m -> { m | email = { input = Just a, error = True } }

            else
                Return.map <| \m -> { m | email = { input = Just a, error = False } }

        LoadShareCondition (Ok cond) ->
            Return.map <|
                \m ->
                    { m
                        | ip =
                            { input = BoolEx.toMaybe (List.map IpAddress.toString cond.allowIPList |> String.join "\n") (not <| List.isEmpty cond.allowIPList)
                            , error = False
                            }
                        , email =
                            { input = BoolEx.toMaybe (List.map Email.toString cond.allowEmail |> String.join "\n") (not <| List.isEmpty cond.allowEmail)
                            , error = False
                            }
                        , token = RemoteData.succeed cond.token
                        , expireDate = DateUtils.millisToDateString m.timeZone (Time.millisToPosix <| cond.expireTime)
                        , expireTime = DateUtils.millisToTimeString m.timeZone (Time.millisToPosix <| cond.expireTime)
                    }

        LoadShareCondition (Err _) ->
            Return.zero


copyButton : CopyState -> Msg -> Html Msg
copyButton copy msg =
    Html.div
        [ Attr.css
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
                Icon.copy Color.white 16

            Copying ->
                Spinner.view

            Copied ->
                Html.text "Copied"
        ]


view : Model -> Html Msg
view model =
    Html.div [ Attr.css [ Style.dialogBackdrop ] ]
        [ Html.div
            [ Attr.css
                [ Breakpoint.style
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
                    ]
                    [ Breakpoint.small [ Style.widthAuto, Style.heightAuto, Style.rounded ] ]
                ]
            ]
            [ Html.div
                [ Attr.css [ displayFlex, alignItems center, justifyContent start, Font.fontSemiBold ]
                ]
                [ Html.div [ Attr.css [ Style.widthFull ] ]
                    [ Html.div []
                        [ Html.div [ Attr.css [ Style.label, padding3 (px 8) (px 8) (px 16) ] ] [ Html.text "Link to share" ]
                        , Html.div [ Attr.css [ Style.flexHCenter, Style.paddingSm ] ]
                            [ Html.div [ Attr.css [ Text.sm, Style.mrSm ] ] [ Html.text "Expire in" ]
                            , Html.input
                                [ Attr.css [ Style.inputLight, Text.sm, Style.paddingXs ]
                                , Attr.type_ "date"
                                , Attr.min <| DateUtils.millisToDateString model.timeZone model.now
                                , Attr.value <| model.expireDate
                                , Events.onChangeStyled DateChange
                                ]
                                []
                            , Html.input
                                [ Attr.css [ Style.inputLight, Text.sm, Style.paddingXs ]
                                , Attr.type_ "time"
                                , Attr.value <| model.expireTime
                                , Events.onChangeStyled TimeChange
                                ]
                                []
                            ]
                        , Html.div [ Attr.css [ Style.flexSpace, Style.paddingSm ] ]
                            [ Html.div [ Attr.css [ Text.sm ] ] [ Html.text "Password protection" ]
                            , Switch.view (MaybeEx.isJust model.password) UsePassword
                            ]
                        , case model.password of
                            Just p ->
                                Html.div [ Attr.css [ Style.paddingSm ] ]
                                    [ Html.input
                                        [ Attr.css [ Style.inputLight, Text.sm, color <| hex "#555555", width <| px 305 ]
                                        , Attr.type_ "password"
                                        , Attr.placeholder "Password"
                                        , Attr.value p
                                        , Attr.maxlength 72
                                        , onInput EditPassword
                                        ]
                                        []
                                    ]

                            Nothing ->
                                Empty.view
                        , Html.div [ Attr.css [ Style.flexSpace, Style.paddingSm ] ]
                            [ Html.div [ Attr.css [ Text.sm ] ] [ Html.text "Limit access by ip address" ]
                            , Switch.view (MaybeEx.isJust model.ip.input) UseLimitByIP
                            ]
                        , case model.ip.input of
                            Just i ->
                                Html.div [ Attr.css [ Style.paddingSm ] ]
                                    [ Html.textarea
                                        [ Attr.css
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
                                        , Attr.placeholder "127.0.0.1"
                                        , Attr.maxlength 150
                                        , onInput EditIP
                                        ]
                                        [ Html.text i ]
                                    , if model.ip.error then
                                        Html.div [ Attr.css [ Style.widthFull, Text.sm, Font.fontBold, textAlign right, Color.textError ] ]
                                            [ Html.text "Invalid ip address entered" ]

                                      else
                                        Empty.view
                                    ]

                            Nothing ->
                                Empty.view
                        , Html.div [ Attr.css [ Style.flexSpace, Style.paddingSm ] ]
                            [ Html.div [ Attr.css [ Text.sm ] ] [ Html.text "Limit access by mail address" ]
                            , Switch.view (MaybeEx.isJust model.email.input) UseLimitByEmail
                            ]
                        , case model.email.input of
                            Just m ->
                                Html.div [ Attr.css [ Style.paddingSm ] ]
                                    [ Html.textarea
                                        [ Attr.css
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
                                        , Attr.placeholder "example@textusm.com"
                                        , Attr.maxlength 150
                                        , onInput EditEmail
                                        ]
                                        [ Html.text m ]
                                    , if model.email.error then
                                        Html.div [ Attr.css [ Style.widthFull, Text.sm, Font.fontBold, textAlign right, Color.textError ] ]
                                            [ Html.text "Invalid mail address entered" ]

                                      else
                                        Empty.view
                                    ]

                            Nothing ->
                                Empty.view
                        , Html.div [ Attr.css [ position relative, Style.paddingSm ] ]
                            [ Html.input
                                [ Attr.css
                                    [ Style.inputLight
                                    , Text.sm
                                    , color <| hex "#555555"
                                    , width <| px 305
                                    ]
                                , Attr.readonly True
                                , Attr.value <| sharUrl model.token model.diagramType
                                , Attr.id "share-url"
                                , onClick <| SelectAll "share-url"
                                , onFocus UrlCopy
                                ]
                                []
                            , Lazy.lazy2 copyButton model.urlCopyState UrlCopy
                            ]
                        ]
                    , Html.div [ Attr.css [ paddingTop <| px 24 ] ]
                        [ Html.div [ Attr.css [ Style.label, displayFlex, alignItems center, padding3 (px 8) (px 8) (px 16) ] ]
                            [ Html.text "Embed"
                            ]
                        , Html.div [ Attr.css [ displayFlex, alignItems center, Style.paddingSm ] ]
                            [ Html.div [ Attr.css [ Text.sm, Style.mrSm ] ] [ Html.text "Embed size" ]
                            , Html.input
                                [ Attr.css
                                    [ Style.inputLight
                                    , Text.sm
                                    , color <| hex "#555555"
                                    , width <| px 60
                                    , height <| px 32
                                    ]
                                , Attr.type_ "number"
                                , Attr.value <| String.fromInt (Size.getWidth model.embedSize)
                                , onInput ChangeEmbedWidth
                                ]
                                []
                            , Html.div [] [ Html.text "x" ]
                            , Html.input
                                [ Attr.css
                                    [ Style.inputLight
                                    , Text.sm
                                    , color <| hex "#555555"
                                    , width <| px 60
                                    , height <| px 32
                                    ]
                                , Attr.type_ "number"
                                , Attr.value <| String.fromInt (Size.getHeight model.embedSize)
                                , onInput ChangeEmbedHeight
                                ]
                                []
                            , Html.div [] [ Html.text "px" ]
                            ]
                        , Html.div [ Attr.css [ position relative, Style.paddingSm ] ]
                            [ Html.input
                                [ Attr.css
                                    [ Style.inputLight
                                    , Text.sm
                                    , color <| hex "#555555"
                                    , width <| px 305
                                    ]
                                , Attr.readonly True
                                , Attr.value <| embedUrl { token = model.token, diagramType = model.diagramType, title = model.title, embedSize = model.embedSize }
                                , Attr.id "embed"
                                , onClick <| SelectAll "embed"
                                , onFocus EmbedCopy
                                ]
                                []
                            , Lazy.lazy2 copyButton model.embedCopyState EmbedCopy
                            ]
                        ]
                    ]
                ]
            , Html.div
                [ Attr.css [ position absolute, cursor pointer, top <| rem 1, right <| rem 1 ]
                , onClick Close
                ]
                [ Icon.times Color.white 24 ]
            ]
        ]
