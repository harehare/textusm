module Main exposing (init, main, view)

import Action
import Asset
import Browser
import Browser.Events
    exposing
        ( Visibility(..)
        , onMouseMove
        , onMouseUp
        , onResize
        , onVisibilityChange
        )
import Browser.Navigation as Nav
import Components.Diagram as Diagram
import Data.DiagramId as DiagramId
import Data.DiagramItem as DiagramItem exposing (DiagramItem)
import Data.DiagramType as DiagramType
import Data.FileType as FileType
import Data.IdToken as IdToken
import Data.Jwt as Jwt
import Data.LoginProvider as LoginProdiver
import Data.Session as Session
import Data.ShareToken as ShareToken
import Data.Size as Size
import Data.Text as Text
import Data.Title as Title
import Dialog.Input as InputDialog
import Dialog.Share as Share
import Env
import File.Download as Download
import GraphQL.Request as Request
import GraphQL.RequestError as RequestError
import Graphql.Http as Http
import Html exposing (Html, div, img, main_, text)
import Html.Attributes exposing (alt, attribute, class, id, style)
import Html.Events as E
import Html.Lazy as Lazy
import Json.Decode as D
import Json.Encode as E
import List.Extra exposing (find)
import Models.Diagram as DiagramModel
import Models.Model as Page exposing (Model, Msg(..), Notification(..), Page(..), SwitchWindow(..))
import Models.Views.ER as ER
import Models.Views.Table as Table
import Page.Embed as Embed
import Page.Help as Help
import Page.List as DiagramList
import Page.New as New
import Page.NotFound as NotFound
import Page.Settings as Settings
import Page.Tags as Tags
import Ports
import RemoteData exposing (RemoteData(..))
import Return as Return exposing (Return)
import Route exposing (Route(..), toRoute)
import Settings
    exposing
        ( defaultEditorSettings
        , defaultSettings
        , settingsDecoder
        , settingsEncoder
        )
import String
import Task
import TextUSM.Enum.Diagram as Diagram
import Time
import Translations
import Url
import Utils.Diagram as DiagramUtils
import Utils.Utils as Utils
import Views.Empty as Empty
import Views.Footer as Footer
import Views.Header as Header
import Views.Menu as Menu
import Views.Notification as Notification
import Views.ProgressBar as ProgressBar
import Views.SplitWindow as SplitWindow
import Views.SwitchWindow as SwitchWindow


type alias Flags =
    { lang : String
    , settings : D.Value
    }


init : Flags -> Url.Url -> Nav.Key -> Return Msg Model
init flags url key =
    let
        initSettings =
            D.decodeValue settingsDecoder flags.settings
                |> Result.withDefault defaultSettings

        lang =
            Translations.fromString flags.lang

        ( diagramListModel, _ ) =
            DiagramList.init Session.guest lang Env.apiRoot

        ( diagramModel, _ ) =
            Diagram.init initSettings.storyMap

        ( shareModel, _ ) =
            Share.init
                { diagram = Diagram.UserStoryMap
                , diagramId = DiagramId.fromString ""
                , apiRoot = Env.apiRoot
                , session = Session.guest
                , title = Title.untitled
                }

        ( settingsModel, _ ) =
            Settings.init initSettings

        ( model, cmds ) =
            changeRouteTo (toRoute url)
                { diagramModel = { diagramModel | text = Text.fromString (Maybe.withDefault "" initSettings.text) }
                , diagramListModel = diagramListModel
                , settingsModel = settingsModel
                , shareModel = shareModel
                , openMenu = Nothing
                , title = Title.fromString (Maybe.withDefault "" initSettings.title)
                , window =
                    { position = initSettings.position |> Maybe.withDefault 0
                    , moveStart = False
                    , moveX = 0
                    , fullscreen = False
                    }
                , notification = Nothing
                , url = url
                , key = key
                , switchWindow = Left
                , progress = False
                , apiRoot = Env.apiRoot
                , session = Session.guest
                , currentDiagram = initSettings.diagram
                , page = Page.Main
                , lang = lang
                , view =
                    { password = Nothing
                    , authenticated = False
                    , token = Nothing
                    , error = Nothing
                    }
                }
    in
    ( model, cmds )


editor : Model -> Html Msg
editor model =
    div [ id "editor", class "full p-sm" ]
        [ Html.node "monaco-editor"
            [ attribute "value" <| Text.toString model.diagramModel.text
            , attribute "fontSize" <| String.fromInt <| .fontSize <| defaultEditorSettings model.settingsModel.settings.editor
            , attribute "wordWrap" <|
                if .wordWrap <| defaultEditorSettings model.settingsModel.settings.editor then
                    "true"

                else
                    "false"
            , attribute "showLineNumber" <|
                if .showLineNumber <| defaultEditorSettings model.settingsModel.settings.editor then
                    "true"

                else
                    "false"
            , attribute "changed" <|
                if Text.isChanged model.diagramModel.text then
                    "true"

                else
                    "false"
            ]
            []
        ]


view : Model -> Html Msg
view model =
    main_
        [ class "relative w-screen"
        , E.onClick CloseMenu
        ]
        [ Lazy.lazy Header.view
            { session = model.session
            , page = model.page
            , title = model.title
            , isFullscreen = model.window.fullscreen
            , currentDiagram = model.currentDiagram
            , menu = model.openMenu
            , currentText = model.diagramModel.text
            , lang = model.lang
            , route = toRoute model.url
            }
        , Lazy.lazy showNotification model.notification
        , Lazy.lazy2 showProgressbar model.progress model.window.fullscreen
        , div
            [ class "flex"
            , class "overflow-hidden"
            , class "relative"
            , class "w-full"
            , class "h-content"
            ]
            [ Lazy.lazy Menu.view { page = model.page, route = toRoute model.url, text = model.diagramModel.text, width = Size.getWidth model.diagramModel.size, fullscreen = model.window.fullscreen, openMenu = model.openMenu, lang = model.lang }
            , let
                mainWindow =
                    if Size.getWidth model.diagramModel.size > 0 && Utils.isPhone (Size.getWidth model.diagramModel.size) then
                        Lazy.lazy5 SwitchWindow.view
                            SwitchWindow
                            model.diagramModel.settings.backgroundColor
                            model.switchWindow
                            (div
                                [ class "h-main"
                                , class "bg-main"
                                , class "lg:h-full"
                                , class "w-full"
                                ]
                                [ editor model
                                ]
                            )

                    else
                        Lazy.lazy5 SplitWindow.view
                            HandleStartWindowResize
                            model.diagramModel.settings.backgroundColor
                            model.window
                            (div
                                [ class "bg-main"
                                , class "w-full"
                                , class "h-main"
                                , class "lg:h-full"
                                ]
                                [ editor model
                                ]
                            )
              in
              case model.page of
                Page.List ->
                    Lazy.lazy DiagramList.view model.diagramListModel |> Html.map UpdateDiagramList

                Page.Help ->
                    Help.view

                Page.Settings ->
                    Lazy.lazy Settings.view model.settingsModel |> Html.map UpdateSettings

                Page.Tags m ->
                    Lazy.lazy Tags.view m |> Html.map UpdateTags

                Page.Embed _ _ _ ->
                    Embed.view model

                Page.New ->
                    New.view

                Page.NotFound ->
                    NotFound.view

                _ ->
                    case toRoute model.url of
                        ViewFile _ id_ ->
                            case ShareToken.unwrap id_ |> Maybe.andThen Jwt.fromString of
                                Just jwt ->
                                    if jwt.checkEmail && Session.isGuest model.session then
                                        div
                                            [ class "flex-center"
                                            , class "text-xl"
                                            , class "font-semibold"
                                            , class "w-screen"
                                            , class "text-color"
                                            , class "m-sm"
                                            , class "text-sm"
                                            , style "height" "calc(100vh - 40px)"
                                            ]
                                            [ img [ class "keyframe anim", Asset.src Asset.logo, style "width" "32px", alt "NOT FOUND" ] []
                                            , div [ class "m-sm" ] [ text "Sign in required" ]
                                            ]

                                    else
                                        div [ class "full", style "background-color" model.settingsModel.settings.storyMap.backgroundColor ]
                                            [ Lazy.lazy Diagram.view model.diagramModel
                                                |> Html.map UpdateDiagram
                                            ]

                                Nothing ->
                                    NotFound.view

                        _ ->
                            mainWindow
                                (Lazy.lazy Diagram.view model.diagramModel
                                    |> Html.map UpdateDiagram
                                )
            ]
        , case toRoute model.url of
            Share ->
                Lazy.lazy Share.view model.shareModel |> Html.map UpdateShare

            ViewFile _ id_ ->
                case ShareToken.unwrap id_ |> Maybe.andThen Jwt.fromString of
                    Just jwt ->
                        if jwt.checkPassword && not model.view.authenticated then
                            Lazy.lazy InputDialog.view
                                { title = "Protedted diagram"
                                , errorMessage = Maybe.map RequestError.toMessage model.view.error
                                , value = model.view.password |> Maybe.withDefault ""
                                , inProcess = model.progress
                                , onInput = EditPassword
                                , onEnter = EndEditPassword
                                }

                        else
                            Empty.view

                    Nothing ->
                        Empty.view

            _ ->
                Empty.view
        , Footer.view
        ]


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view =
            \m ->
                { title =
                    Title.toString m.title
                        ++ (if Text.isChanged m.diagramModel.text then
                                "*"

                            else
                                ""
                           )
                        ++ " | TextUSM"
                , body = [ view m ]
                }
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }


showProgressbar : Bool -> Bool -> Html Msg
showProgressbar show fullscreen =
    if show then
        ProgressBar.view

    else if not fullscreen then
        div [ style "height" "4px", class "bg-main" ] []

    else
        Empty.view


showNotification : Maybe Notification -> Html Msg
showNotification notify =
    Notification.view notify



-- Update


changeRouteTo : Route -> Model -> Return Msg Model
changeRouteTo route model =
    Return.singleton model
        |> (if Text.isChanged model.diagramModel.text then
                Action.startEditTitle

            else
                case route of
                    Route.DiagramList ->
                        (if DiagramList.isNotAsked model.diagramListModel.diagramList then
                            let
                                ( model_, cmd_ ) =
                                    DiagramList.init model.session model.lang model.diagramListModel.apiRoot
                            in
                            Return.andThen (\m -> Return.singleton { m | diagramListModel = model_ })
                                >> Return.andThen (Action.switchPage Page.List)
                                >> Return.command (cmd_ |> Cmd.map UpdateDiagramList)
                                >> Return.andThen Action.startProgress

                         else
                            Return.andThen (Action.switchPage Page.List)
                                >> Return.andThen Action.stopProgress
                        )
                            >> Return.andThen Action.changeRouteInit

                    Route.Tag ->
                        case model.currentDiagram of
                            Nothing ->
                                Return.zero

                            Just diagram ->
                                let
                                    ( model_, _ ) =
                                        Tags.init (diagram.tags |> Maybe.withDefault [] |> List.map (Maybe.withDefault ""))
                                in
                                Return.andThen <| Action.switchPage (Page.Tags model_)

                    Route.New ->
                        Return.andThen <| Action.switchPage Page.New

                    Route.NotFound ->
                        Return.andThen <| Action.switchPage Page.NotFound

                    Route.Embed diagram title id_ width height ->
                        Return.andThen
                            (\m ->
                                Return.singleton
                                    { m
                                        | window = m.window |> Page.windowOfFullscreen.set True
                                        , diagramModel =
                                            model.diagramModel
                                                |> DiagramModel.modelOfShowZoomControl.set False
                                                |> DiagramModel.modelOfDiagramType.set diagram
                                                |> DiagramModel.modelOfScale.set 1.0
                                    }
                            )
                            >> Return.andThen (Action.setTitle title)
                            >> Return.command
                                (Task.attempt Load <|
                                    Request.shareItem
                                        { url = model.apiRoot
                                        , idToken = Session.getIdToken model.session
                                        }
                                        (ShareToken.toString id_)
                                        Nothing
                                )
                            >> Return.andThen
                                (Action.switchPage
                                    (Page.Embed diagram
                                        title
                                        (Maybe.andThen (\w -> Maybe.andThen (\h -> Just ( w, h )) height) width)
                                    )
                                )
                            >> Return.andThen Action.changeRouteInit

                    Route.Edit diagramType ->
                        Return.andThen
                            (\m ->
                                Return.singleton
                                    { m
                                        | title = Title.untitled
                                        , diagramModel =
                                            DiagramModel.updatedText
                                                (model.diagramModel
                                                    |> DiagramModel.modelOfDiagramType.set diagramType
                                                )
                                                (Text.fromString <| DiagramType.defaultText diagramType)
                                    }
                            )
                            >> Return.andThen (Action.setCurrentDiagram Nothing)
                            >> Return.andThen (Action.switchPage Page.Main)
                            >> Return.andThen Action.changeRouteInit

                    Route.EditFile _ id_ ->
                        let
                            loadText_ =
                                if Session.isSignedIn model.session then
                                    Action.updateIdToken
                                        >> Return.andThen (Action.switchPage Page.Main)
                                        >> Return.command (Task.attempt Load <| Request.item { url = model.apiRoot, idToken = Session.getIdToken model.session } (DiagramId.toString id_))

                                else
                                    Return.andThen (Action.switchPage Page.Main)
                                        >> Return.andThen (Action.loadLocalDiagram id_)
                                        >> Return.andThen Action.changeRouteInit
                        in
                        case ( model.diagramListModel.diagramList, model.currentDiagram ) of
                            ( DiagramList.DiagramList (Success d) _ _, _ ) ->
                                case find (\diagram -> (DiagramItem.getId diagram |> DiagramId.toString) == DiagramId.toString id_) d of
                                    Just item ->
                                        if item.isRemote then
                                            Action.updateIdToken
                                                >> Return.andThen (Action.switchPage Page.Main)
                                                >> Return.command (Task.attempt Load <| Request.item { url = model.apiRoot, idToken = Session.getIdToken model.session } (DiagramId.toString id_))

                                        else
                                            Return.andThen (Action.switchPage Page.Main)
                                                >> Return.command (Task.attempt Load <| Task.succeed item)

                                    Nothing ->
                                        Return.andThen (Action.switchPage Page.NotFound)
                                            >> Return.andThen Action.stopProgress

                            ( _, Just diagram ) ->
                                if (DiagramItem.getId diagram |> DiagramId.toString) == DiagramId.toString id_ then
                                    Return.andThen (Action.switchPage Page.Main)
                                        >> (case ( model.page, Size.isZero model.diagramModel.size ) of
                                                ( Page.Main, False ) ->
                                                    Return.zero

                                                _ ->
                                                    Return.andThen Action.changeRouteInit
                                           )

                                else
                                    loadText_

                            _ ->
                                loadText_

                    Route.ViewPublic _ id_ ->
                        Action.updateIdToken
                            >> Return.andThen (Action.switchPage Page.Main)
                            >> Return.command (Task.attempt Load <| Request.publicItem { url = model.apiRoot, idToken = Session.getIdToken model.session } (DiagramId.toString id_))

                    Route.Home ->
                        Return.andThen (Action.switchPage Page.Main)
                            >> Action.redirectToLastEditedFile model
                            >> Return.andThen Action.changeRouteInit

                    Route.Settings ->
                        Return.andThen <| Action.switchPage Page.Settings

                    Route.Help ->
                        Return.andThen <| Action.switchPage Page.Help

                    Route.Share ->
                        case ( model.currentDiagram, Session.isSignedIn model.session ) of
                            ( Just diagram, True ) ->
                                if diagram.isRemote then
                                    let
                                        ( shareModel, cmd_ ) =
                                            Share.init
                                                { diagram = diagram.diagram
                                                , diagramId = diagram.id |> Maybe.withDefault (DiagramId.fromString "")
                                                , apiRoot = model.apiRoot
                                                , session = model.session
                                                , title = model.title
                                                }
                                    in
                                    Return.andThen (\m -> Return.return { m | shareModel = shareModel } (cmd_ |> Cmd.map UpdateShare))
                                        >> Return.andThen Action.startProgress

                                else
                                    Action.moveTo model.key Route.Home

                            _ ->
                                Action.moveTo model.key Route.Home

                    Route.ViewFile _ id_ ->
                        case ShareToken.unwrap id_ |> Maybe.andThen Jwt.fromString of
                            Just jwt ->
                                Return.andThen (\m -> Return.singleton { m | view = { password = m.view.password, authenticated = m.view.authenticated, token = Just id_, error = Nothing } })
                                    >> (if jwt.checkPassword || jwt.checkEmail then
                                            Return.andThen (Action.switchPage Page.Main)
                                                >> Return.andThen Action.changeRouteInit

                                        else
                                            Return.andThen (Action.switchPage Page.Main)
                                                >> Return.command (Task.attempt Load <| Request.shareItem { url = model.apiRoot, idToken = Session.getIdToken model.session } (ShareToken.toString id_) Nothing)
                                                >> Return.andThen Action.startProgress
                                                >> Return.andThen Action.changeRouteInit
                                       )

                            Nothing ->
                                Return.andThen <| Action.switchPage Page.NotFound
           )


loadDiagram : Model -> DiagramItem -> Return.ReturnF Msg Model
loadDiagram model diagram =
    let
        newDiagram =
            case diagram.id of
                Nothing ->
                    { diagram
                        | title = model.title
                        , text = model.diagramModel.text
                        , diagram = model.diagramModel.diagramType
                    }

                Just _ ->
                    diagram

        diagramModel =
            model.diagramModel

        newDiagramModel =
            { diagramModel
                | diagramType = newDiagram.diagram
                , text = newDiagram.text
            }

        ( model_, cmd_ ) =
            Diagram.update (DiagramModel.OnChangeText <| Text.toString newDiagram.text) newDiagramModel
    in
    Return.andThen
        (\m ->
            Return.return
                { m
                    | title = newDiagram.title
                    , currentDiagram = Just newDiagram
                    , diagramModel = model_
                }
                (cmd_ |> Cmd.map UpdateDiagram)
        )
        >> Return.andThen Action.stopProgress


update : Msg -> Model -> Return Msg Model
update message model =
    Return.singleton model
        |> (case message of
                NoOp ->
                    Return.zero

                UpdateShare msg ->
                    case toRoute model.url of
                        Share ->
                            let
                                ( model_, cmd_ ) =
                                    Share.update msg model.shareModel
                            in
                            Return.andThen <|
                                (\m ->
                                    Return.return { m | shareModel = model_ } (cmd_ |> Cmd.map UpdateShare)
                                )
                                    >> (case msg of
                                            Share.Shared (Err errMsg) ->
                                                Action.showErrorMessage errMsg

                                            Share.Close ->
                                                Action.historyBack model.key

                                            Share.LoadShareCondition (Err errMsg) ->
                                                Action.showErrorMessage errMsg

                                            _ ->
                                                Return.zero
                                       )
                                    >> Return.andThen Action.stopProgress

                        _ ->
                            Return.zero

                UpdateTags msg ->
                    case ( model.page, model.currentDiagram ) of
                        ( Page.Tags m, Just diagram ) ->
                            let
                                ( model_, cmd_ ) =
                                    Tags.update msg m

                                newDiagram =
                                    { diagram
                                        | tags = Just (List.map Just model_.tags)
                                    }
                            in
                            Return.andThen <| \mo -> Return.return { mo | page = Page.Tags model_, currentDiagram = Just newDiagram, diagramModel = DiagramModel.updatedText mo.diagramModel (Text.change diagram.text) } (cmd_ |> Cmd.map UpdateTags)

                        _ ->
                            Return.zero

                UpdateSettings msg ->
                    let
                        ( model_, cmd_ ) =
                            Settings.update msg model.settingsModel

                        diagramModel =
                            model.diagramModel

                        newDiagramModel =
                            { diagramModel | settings = model_.settings.storyMap }
                    in
                    Return.andThen <| \m -> Return.return { m | page = Page.Settings, diagramModel = newDiagramModel, settingsModel = model_ } cmd_

                UpdateDiagram msg ->
                    let
                        ( model_, cmd_ ) =
                            Diagram.update msg model.diagramModel
                    in
                    case msg of
                        DiagramModel.OnResize _ _ ->
                            Return.andThen <| \m -> Return.return { m | diagramModel = model_ } (cmd_ |> Cmd.map UpdateDiagram)

                        DiagramModel.EndEditSelectedItem _ ->
                            Return.andThen <| \m -> Return.singleton { m | diagramModel = model_ }

                        DiagramModel.FontStyleChanged _ ->
                            case model.diagramModel.selectedItem of
                                Just _ ->
                                    Return.andThen <| \m -> Return.return { m | diagramModel = model_ } (cmd_ |> Cmd.map UpdateDiagram)

                                Nothing ->
                                    Return.zero

                        DiagramModel.ColorChanged _ _ ->
                            case model.diagramModel.selectedItem of
                                Just _ ->
                                    Return.andThen <| \m -> Return.return { m | diagramModel = model_ } (cmd_ |> Cmd.map UpdateDiagram)

                                Nothing ->
                                    Return.zero

                        DiagramModel.FontSizeChanged _ ->
                            case model.diagramModel.selectedItem of
                                Just _ ->
                                    Return.andThen <| \m -> Return.return { m | diagramModel = model_ } (cmd_ |> Cmd.map UpdateDiagram)

                                Nothing ->
                                    Return.zero

                        DiagramModel.ToggleFullscreen ->
                            Return.andThen
                                (\m ->
                                    Return.return
                                        { m
                                            | window =
                                                m.window
                                                    |> Page.windowOfFullscreen.set (not m.window.fullscreen)
                                            , diagramModel = model_
                                        }
                                        (cmd_ |> Cmd.map UpdateDiagram)
                                )
                                >> (if not model.window.fullscreen then
                                        Action.openFullscreen

                                    else
                                        Action.closeFullscreen
                                   )

                        _ ->
                            Return.andThen <| \m -> Return.return { m | diagramModel = model_ } (cmd_ |> Cmd.map UpdateDiagram)

                UpdateDiagramList subMsg ->
                    let
                        ( model_, cmd_ ) =
                            DiagramList.update subMsg model.diagramListModel
                    in
                    case subMsg of
                        DiagramList.Select diagram ->
                            case diagram.id of
                                Just _ ->
                                    (if diagram.isRemote && diagram.isPublic then
                                        Action.pushUrl
                                            (Route.toString <|
                                                ViewPublic diagram.diagram (DiagramItem.getId diagram)
                                            )
                                            model

                                     else
                                        Action.pushUrl
                                            (Route.toString <|
                                                EditFile diagram.diagram (DiagramItem.getId diagram)
                                            )
                                            model
                                    )
                                        >> Return.andThen Action.startProgress

                                Nothing ->
                                    Return.zero

                        DiagramList.Removed (Err e) ->
                            case e of
                                Http.GraphqlError _ _ ->
                                    Action.showErrorMessage (Translations.messageFailed model.lang)

                                Http.HttpError Http.Timeout ->
                                    Action.showErrorMessage (Translations.messageRequestTimeout model.lang)

                                Http.HttpError Http.NetworkError ->
                                    Action.showErrorMessage (Translations.messageNetworkError model.lang)

                                Http.HttpError _ ->
                                    Action.showErrorMessage (Translations.messageFailed model.lang)

                        DiagramList.GotDiagrams (Err _) ->
                            Action.showErrorMessage (Translations.messageFailed model.lang)

                        DiagramList.ImportComplete json ->
                            case DiagramItem.stringToList json of
                                Ok _ ->
                                    Return.andThen (\m -> Return.return { m | diagramListModel = model_ } (cmd_ |> Cmd.map UpdateDiagramList))
                                        >> Return.andThen (Action.showInfoMessage (Translations.messageImportCompleted model.lang))

                                Err _ ->
                                    Action.showErrorMessage (Translations.messageFailed model.lang)

                        _ ->
                            Return.andThen (\m -> Return.return { m | diagramListModel = model_ } (cmd_ |> Cmd.map UpdateDiagramList))
                                >> Return.andThen Action.stopProgress

                Init window ->
                    let
                        ( model_, cmd_ ) =
                            Diagram.update (DiagramModel.Init model.diagramModel.settings window (Text.toString model.diagramModel.text)) model.diagramModel

                        model__ =
                            case toRoute model.url of
                                Route.Embed _ _ _ (Just w) (Just h) ->
                                    let
                                        scale =
                                            toFloat w
                                                / toFloat model_.svg.width
                                    in
                                    { model_ | size = ( w, h ), svg = { width = w, height = h, scale = scale } }

                                _ ->
                                    model_
                    in
                    Return.andThen (\m -> Return.return { m | diagramModel = model__ } (cmd_ |> Cmd.map UpdateDiagram))
                        >> Return.andThen (Action.loadText (model.currentDiagram |> Maybe.withDefault DiagramItem.empty))
                        >> Return.andThen Action.stopProgress

                DownloadCompleted ( x, y ) ->
                    Return.andThen (\m -> Return.singleton { m | diagramModel = m.diagramModel |> DiagramModel.modelOfPosition.set ( x, y ) })

                Download fileType ->
                    case fileType of
                        FileType.Ddl ex ->
                            let
                                ( _, tables ) =
                                    ER.from model.diagramModel.items

                                ddl =
                                    List.map ER.tableToString tables
                                        |> String.join "\n"
                            in
                            Return.command <| Download.string (Title.toString model.title ++ ex) "text/plain" ddl

                        FileType.Markdown ex ->
                            Return.command <| Download.string (Title.toString model.title ++ ex) "text/plain" (Table.toString (Table.from model.diagramModel.items))

                        FileType.PlainText ex ->
                            Return.command <| Download.string (Title.toString model.title ++ ex) "text/plain" (Text.toString model.diagramModel.text)

                        _ ->
                            let
                                ( posX, posY ) =
                                    model.diagramModel.position

                                ( width, height ) =
                                    DiagramUtils.getCanvasSize model.diagramModel
                                        |> Tuple.mapBoth (\x -> x + posX) (\y -> y + posY)

                                ( sub, extension ) =
                                    case fileType of
                                        FileType.Png ex ->
                                            ( Ports.downloadPng, ex )

                                        FileType.Pdf ex ->
                                            ( Ports.downloadPdf, ex )

                                        FileType.Svg ex ->
                                            ( Ports.downloadSvg, ex )

                                        FileType.Html ex ->
                                            ( Ports.downloadHtml, ex )

                                        _ ->
                                            ( Ports.downloadSvg, "" )
                            in
                            Return.command <|
                                sub
                                    { width = width
                                    , height = height
                                    , id = "usm"
                                    , title = Title.toString model.title ++ extension
                                    , x = 0
                                    , y = 0
                                    , text = Text.toString model.diagramModel.text
                                    , diagramType = DiagramType.toString model.diagramModel.diagramType
                                    }

                StartDownload info ->
                    Return.command (Download.string (Title.toString model.title ++ info.extension) info.mimeType info.content)
                        >> Return.andThen Action.closeMenu

                OpenMenu menu ->
                    Return.andThen <| \m -> Return.singleton { m | openMenu = Just menu }

                CloseMenu ->
                    Return.andThen Action.closeMenu

                Save ->
                    let
                        isRemote =
                            Maybe.andThen
                                (\d ->
                                    case ( d.isRemote, d.id ) of
                                        ( False, Nothing ) ->
                                            Nothing

                                        ( False, Just _ ) ->
                                            Just False

                                        ( True, _ ) ->
                                            Just True
                                )
                                model.currentDiagram
                                |> Maybe.withDefault (Session.isSignedIn model.session)
                    in
                    if Title.isUntitled model.title then
                        Action.startEditTitle

                    else
                        let
                            newDiagramModel =
                                DiagramModel.updatedText model.diagramModel (Text.saved model.diagramModel.text)

                            item =
                                { id = Maybe.andThen .id model.currentDiagram
                                , title = model.title
                                , text = newDiagramModel.text
                                , thumbnail = Nothing
                                , diagram = newDiagramModel.diagramType
                                , isRemote = isRemote
                                , isPublic = Maybe.map .isPublic model.currentDiagram |> Maybe.withDefault False
                                , isBookmark = False
                                , tags = Maybe.andThen .tags model.currentDiagram
                                , updatedAt = Time.millisToPosix 0
                                , createdAt = Time.millisToPosix 0
                                }
                        in
                        Return.andThen
                            (\m ->
                                Return.singleton
                                    { m
                                        | diagramListModel = m.diagramListModel |> DiagramList.modelOfDiagramList.set DiagramList.notAsked
                                        , diagramModel = newDiagramModel
                                    }
                            )
                            >> Action.saveDiagram item

                SaveToLocalCompleted diagramJson ->
                    case D.decodeValue DiagramItem.decoder diagramJson of
                        Ok item ->
                            Return.andThen
                                (\m ->
                                    Return.return { m | currentDiagram = Just item } <|
                                        Route.replaceRoute m.key
                                            (Route.EditFile item.diagram
                                                (case item.id of
                                                    Nothing ->
                                                        DiagramId.fromString ""

                                                    Just diagramId ->
                                                        diagramId
                                                )
                                            )
                                )
                                >> Return.andThen (Action.showInfoMessage (Translations.messageSuccessfullySaved model.lang (Title.toString item.title)))

                        Err _ ->
                            Return.zero

                SaveToRemote diagramJson ->
                    let
                        result =
                            D.decodeValue DiagramItem.decoder diagramJson
                    in
                    case result of
                        Ok diagram ->
                            Action.saveToRemote diagram model.apiRoot model.session
                                >> Return.andThen Action.startProgress

                        Err _ ->
                            Action.showWarningMessage ("Successfully \"" ++ Title.toString model.title ++ "\" saved.")
                                >> Return.andThen Action.stopProgress

                SaveToRemoteCompleted (Err _) ->
                    let
                        item =
                            { id = Nothing
                            , title = model.title
                            , text = model.diagramModel.text
                            , thumbnail = Nothing
                            , diagram = model.diagramModel.diagramType
                            , isRemote = False
                            , isPublic = False
                            , isBookmark = False
                            , tags = Nothing
                            , updatedAt = Time.millisToPosix 0
                            , createdAt = Time.millisToPosix 0
                            }
                    in
                    Return.andThen (Action.setCurrentDiagram <| Just item)
                        >> Action.saveToLocal item
                        >> Return.andThen Action.stopProgress
                        >> (Action.showWarningMessage <| Translations.messageFailedSaved model.lang (Title.toString model.title))

                SaveToRemoteCompleted (Ok diagram) ->
                    Return.andThen (Action.setCurrentDiagram <| Just diagram)
                        >> Return.command
                            (Route.replaceRoute model.key
                                (Route.EditFile diagram.diagram
                                    (diagram.id |> Maybe.withDefault (DiagramId.fromString ""))
                                )
                            )
                        >> Return.andThen Action.stopProgress
                        >> Return.andThen (Action.showInfoMessage <| Translations.messageSuccessfullySaved model.lang (Title.toString model.title))

                Shortcuts x ->
                    case x of
                        "save" ->
                            if Text.isChanged model.diagramModel.text then
                                Return.command <| Task.perform identity <| Task.succeed Save

                            else
                                Return.zero

                        "open" ->
                            Return.command <| Nav.load <| Route.toString (toRoute model.url)

                        _ ->
                            Return.zero

                StartEditTitle ->
                    Return.andThen (\m -> Return.singleton { m | title = Title.edit m.title })
                        >> Return.andThen (Action.setFocus "title")

                EndEditTitle ->
                    Return.andThen (\m -> Return.singleton { m | title = Title.view m.title })
                        >> Action.setFocusEditor

                EditTitle title ->
                    Return.andThen (\m -> Return.singleton { m | title = Title.edit <| Title.fromString title })
                        >> Return.andThen Action.needSaved

                HandleVisibilityChange visible ->
                    case visible of
                        Hidden ->
                            let
                                newStoryMap =
                                    model.settingsModel.settings |> Settings.settingsOfFont.set model.settingsModel.settings.font

                                newSettings =
                                    { position = Just model.window.position
                                    , font = model.settingsModel.settings.font
                                    , diagramId = Maybe.andThen (\d -> Maybe.andThen (\i -> Just <| DiagramId.toString i) d.id) model.currentDiagram
                                    , storyMap = newStoryMap.storyMap |> DiagramModel.settingsOfScale.set (Just model.diagramModel.svg.scale)
                                    , text = Just (Text.toString model.diagramModel.text)
                                    , title = Just <| Title.toString model.title
                                    , editor = model.settingsModel.settings.editor
                                    , diagram = model.currentDiagram
                                    }

                                ( newSettingsModel, _ ) =
                                    Settings.init newSettings
                            in
                            Return.andThen (\m -> Return.singleton { m | settingsModel = newSettingsModel })
                                >> Return.command (Ports.saveSettings (settingsEncoder newSettings))

                        _ ->
                            Return.zero

                HandleStartWindowResize x ->
                    Return.andThen <|
                        \m ->
                            Return.singleton
                                { m
                                    | window =
                                        m.window
                                            |> Page.windowOfMoveStart.set True
                                            |> Page.windowOfMoveX.set x
                                }

                Stop ->
                    Return.andThen <| \m -> Return.singleton { m | window = m.window |> Page.windowOfMoveStart.set False }

                HandleWindowResize x ->
                    Return.andThen <| \m -> Return.singleton { m | window = { position = m.window.position + x - m.window.moveX, moveStart = True, moveX = x, fullscreen = m.window.fullscreen } }

                ShowNotification notification ->
                    Return.andThen <| \m -> Return.singleton { m | notification = Just notification }

                HandleAutoCloseNotification notification ->
                    Return.andThen (\m -> Return.singleton { m | notification = Just notification })
                        >> Action.closeNotification

                HandleCloseNotification ->
                    Return.andThen <| \m -> Return.singleton { m | notification = Nothing }

                SwitchWindow w ->
                    Return.andThen <| \m -> Return.singleton { m | switchWindow = w }

                LinkClicked urlRequest ->
                    case urlRequest of
                        Browser.Internal url ->
                            Action.pushUrl (Url.toString url) model

                        Browser.External href ->
                            Return.command (Nav.load href)

                UrlChanged url ->
                    \( m, _ ) -> changeRouteTo (toRoute url) { m | url = url }

                SignIn provider ->
                    Return.command (Ports.signIn <| LoginProdiver.toString provider)
                        >> Return.andThen Action.startProgress

                SignOut ->
                    Return.andThen (\m -> Return.return { m | session = Session.guest } (Ports.signOut ()))
                        >> Return.andThen (Action.setCurrentDiagram Nothing)

                HandleAuthStateChanged (Just user) ->
                    Return.andThen (\m -> Return.singleton { m | session = Session.signIn user })
                        >> (case ( toRoute model.url, model.currentDiagram ) of
                                ( Route.EditFile type_ id_, Just diagram ) ->
                                    if (DiagramItem.getId diagram |> DiagramId.toString) /= DiagramId.toString id_ then
                                        Action.pushUrl (Route.toString <| Route.EditFile type_ id_) model

                                    else
                                        Return.zero

                                ( Route.EditFile type_ id_, _ ) ->
                                    Action.pushUrl (Route.toString <| Route.EditFile type_ id_) model

                                ( Route.ViewFile _ id_, _ ) ->
                                    case ShareToken.unwrap id_ |> Maybe.andThen Jwt.fromString of
                                        Just jwt ->
                                            if jwt.checkPassword then
                                                Return.andThen (Action.switchPage Page.Main)
                                                    >> Return.andThen Action.changeRouteInit

                                            else
                                                Return.andThen (Action.switchPage Page.Main)
                                                    >> Return.command (Task.attempt Load <| Request.shareItem { url = model.apiRoot, idToken = Session.getIdToken <| Session.signIn user } (ShareToken.toString id_) Nothing)
                                                    >> Return.andThen Action.startProgress
                                                    >> Return.andThen Action.changeRouteInit

                                        Nothing ->
                                            Return.andThen <| Action.switchPage Page.NotFound

                                ( Route.DiagramList, _ ) ->
                                    Action.pushUrl (Route.toString <| Route.Home) model

                                _ ->
                                    Return.zero
                           )
                        >> Return.andThen Action.stopProgress

                HandleAuthStateChanged Nothing ->
                    Return.andThen (\m -> Return.singleton { m | session = Session.guest })
                        >> Return.andThen Action.stopProgress

                Progress visible ->
                    Return.andThen (\m -> Return.singleton { m | progress = visible })

                Load (Ok diagram) ->
                    loadDiagram model diagram

                EditText text ->
                    let
                        ( model_, cmd_ ) =
                            Diagram.update (DiagramModel.OnChangeText text) model.diagramModel
                    in
                    Return.andThen (\m -> Return.return { m | diagramModel = model_ } (cmd_ |> Cmd.map UpdateDiagram))

                Load (Err e) ->
                    (case RequestError.toError e of
                        RequestError.NotFound ->
                            Action.moveTo model.key Route.NotFound

                        RequestError.Forbidden ->
                            Action.moveTo model.key Route.Home

                        RequestError.NoAuthorization ->
                            Action.moveTo model.key Route.Home

                        RequestError.DecryptionFailed ->
                            Action.moveTo model.key Route.Home

                        RequestError.EncryptionFailed ->
                            Action.moveTo model.key Route.Home

                        RequestError.URLExpired ->
                            Action.moveTo model.key Route.Home

                        RequestError.Unknown ->
                            Action.moveTo model.key Route.Home

                        RequestError.Http _ ->
                            Action.moveTo model.key Route.Home
                    )
                        >> Return.andThen Action.stopProgress
                        >> Action.showErrorMessage (RequestError.toMessage <| RequestError.toError e)

                GotLocalDiagramJson json ->
                    case D.decodeValue DiagramItem.decoder json of
                        Ok item ->
                            Return.andThen <| Action.loadText item

                        Err _ ->
                            Return.zero

                ChangePublicStatus isPublic ->
                    case model.currentDiagram of
                        Just diagram ->
                            let
                                saveTask =
                                    Request.save { url = model.apiRoot, idToken = Session.getIdToken model.session } (DiagramItem.toInputItem diagram) isPublic
                                        |> Task.mapError (\_ -> diagram)
                            in
                            Action.updateIdToken
                                >> Return.command (Task.attempt ChangePublicStatusCompleted saveTask)
                                >> Return.andThen Action.stopProgress

                        _ ->
                            Return.zero

                ChangePublicStatusCompleted (Ok d) ->
                    Return.andThen (Action.setCurrentDiagram <| Just d)
                        >> Return.andThen Action.stopProgress
                        >> Return.andThen (Action.showInfoMessage <| "\"" ++ Title.toString d.title ++ "\"" ++ " published")

                ChangePublicStatusCompleted (Err _) ->
                    Action.showErrorMessage "Failed to change publishing settings"
                        >> Return.andThen Action.stopProgress

                CloseFullscreen _ ->
                    let
                        ( model_, cmd_ ) =
                            Diagram.update DiagramModel.ToggleFullscreen model.diagramModel
                    in
                    Return.andThen <| \m -> Return.return { m | window = m.window |> Page.windowOfFullscreen.set False, diagramModel = model_ } (cmd_ |> Cmd.map UpdateDiagram)

                UpdateIdToken token ->
                    Return.andThen <| \m -> Return.singleton { m | session = Session.updateIdToken m.session (IdToken.fromString token) }

                HistoryBack ->
                    Action.historyBack model.key

                EditPassword password ->
                    Return.andThen <|
                        \m ->
                            Return.singleton { m | view = { password = Just password, authenticated = False, token = m.view.token, error = Nothing } }

                EndEditPassword ->
                    case model.view.token of
                        Just token ->
                            Return.andThen (Action.switchPage Page.Main)
                                >> Return.command (Task.attempt LoadWithPassword <| Request.shareItem { url = model.apiRoot, idToken = Session.getIdToken model.session } (ShareToken.toString token) model.view.password)
                                >> Return.andThen Action.startProgress

                        Nothing ->
                            Return.zero

                LoadWithPassword (Ok diagram) ->
                    Return.andThen (\m -> Return.singleton { m | view = { password = Nothing, token = Nothing, authenticated = True, error = Nothing } })
                        >> loadDiagram model diagram

                LoadWithPassword (Err e) ->
                    Return.andThen (\m -> Return.singleton { m | view = { password = Nothing, token = m.view.token, authenticated = False, error = Just <| RequestError.toError e } })
                        >> Return.andThen Action.stopProgress
           )



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ([ Ports.changeText (\text -> UpdateDiagram (DiagramModel.OnChangeText text))
         , Ports.startDownload StartDownload
         , Ports.gotLocalDiagramsJson (\json -> UpdateDiagramList (DiagramList.GotLocalDiagramsJson json))
         , Ports.reload (\_ -> UpdateDiagramList DiagramList.Reload)
         , onVisibilityChange HandleVisibilityChange
         , onResize (\width height -> UpdateDiagram (DiagramModel.OnResize width height))
         , Ports.shortcuts Shortcuts
         , Ports.onNotification (\n -> HandleAutoCloseNotification (Info n))
         , Ports.sendErrorNotification (\n -> HandleAutoCloseNotification (Error n))
         , Ports.onWarnNotification (\n -> HandleAutoCloseNotification (Warning n))
         , Ports.onAuthStateChanged HandleAuthStateChanged
         , Ports.saveToRemote SaveToRemote
         , Ports.removeRemoteDiagram (\diagram -> UpdateDiagramList <| DiagramList.RemoveRemote diagram)
         , Ports.downloadCompleted DownloadCompleted
         , Ports.progress Progress
         , Ports.saveToLocalCompleted SaveToLocalCompleted
         , Ports.gotLocalDiagramJson GotLocalDiagramJson
         , Ports.onCloseFullscreen CloseFullscreen
         , Ports.updateIdToken UpdateIdToken
         ]
            ++ (if model.window.moveStart then
                    [ onMouseUp <| D.succeed Stop
                    , onMouseMove <| D.map HandleWindowResize (D.field "pageX" D.int)
                    ]

                else
                    [ Sub.none ]
               )
        )
