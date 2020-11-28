module Main exposing (init, main, view)

import Api.UrlShorter as UrlShorterApi
import Browser
import Browser.Dom as Dom
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
import Data.LoginProvider as LoginProdiver
import Data.Session as Session
import Data.Size as Size
import Data.Text as Text
import Data.Title as Title
import Effect
import Events
import File.Download as Download
import GraphQL.Request as Request
import Graphql.Http as Http
import Html exposing (Html, div, main_, textarea)
import Html.Attributes exposing (class, id, placeholder, style, value)
import Html.Events as E
import Html.Lazy as Lazy
import Json.Decode as D
import Json.Encode as E
import List.Extra exposing (find)
import Models.Diagram as DiagramModel
import Models.Model as Page exposing (Model, Msg(..), Notification(..), Page(..), SwitchWindow(..), modelOfDiagramModel)
import Models.Views.ER as ER
import Models.Views.Table as Table
import Page.Help as Help
import Page.List as DiagramList
import Page.New as New
import Page.NotFound as NotFound
import Page.Settings as Settings
import Page.Share as Share
import Page.Tags as Tags
import Ports
import RemoteData exposing (RemoteData(..))
import Return as Return exposing (Return)
import Route exposing (Route(..), toRoute)
import Settings
    exposing
        ( EditorSettings
        , Settings
        , defaultEditorSettings
        , defaultSettings
        , settingsDecoder
        , settingsEncoder
        )
import String
import Task
import TextUSM.Enum.Diagram as Diagram
import Time
import Translations
import Url as Url exposing (percentDecode)
import Utils.Diagram as DiagramUtils
import Utils.Utils as Utils
import Views.Empty as Empty
import Views.Header as Header
import Views.Menu as Menu
import Views.Notification as Notification
import Views.ProgressBar as ProgressBar
import Views.SplitWindow as SplitWindow
import Views.SwitchWindow as SwitchWindow


type alias Flags =
    { apiRoot : String
    , lang : String
    , settings : D.Value
    }


init : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        initSettings =
            D.decodeValue settingsDecoder flags.settings
                |> Result.withDefault defaultSettings

        lang =
            Translations.fromString flags.lang

        ( diagramListModel, _ ) =
            DiagramList.init Session.guest lang flags.apiRoot

        ( diagramModel, _ ) =
            Diagram.init initSettings.storyMap

        ( shareModel, _ ) =
            Share.init "" ""

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
                , progress = True
                , apiRoot = flags.apiRoot
                , session = Session.guest
                , currentDiagram = initSettings.diagram
                , page = Page.Main
                , lang = lang
                }
    in
    ( model, cmds )


view : Model -> Html Msg
view model =
    main_
        [ class "relative w-screen"
        , E.onClick CloseMenu
        ]
        [ Lazy.lazy Header.view { session = model.session, page = model.page, title = model.title, isFullscreen = model.window.fullscreen, currentDiagram = model.currentDiagram, menu = model.openMenu, currentText = model.diagramModel.text, lang = model.lang }
        , Lazy.lazy showNotification model.notification
        , Lazy.lazy2 showProgressbar model.progress model.window.fullscreen
        , div
            [ style "display" "flex"
            , style "overflow" "hidden"
            , style "position" "relative"
            , style "width" "100%"
            , style "height" "100vh"
            ]
            [ Lazy.lazy Menu.view { page = model.page, route = toRoute model.url, text = model.diagramModel.text, width = Size.getWidth model.diagramModel.size, fullscreen = model.window.fullscreen, openMenu = model.openMenu, lang = model.lang }
            , let
                mainWindow =
                    if Size.getWidth model.diagramModel.size > 0 && Utils.isPhone (Size.getWidth model.diagramModel.size) then
                        Lazy.lazy5 SwitchWindow.view
                            SwitchWindow
                            model.diagramModel.settings.backgroundColor
                            model.switchWindow
                            (div [ class "h-main bg-main lg:h-full w-full" ]
                                [ textarea
                                    [ E.onInput EditText
                                    , style "font-size" ((defaultEditorSettings model.settingsModel.settings.editor |> .fontSize |> String.fromInt) ++ "px")
                                    , placeholder "Enter Text"
                                    , value <| Text.toString model.diagramModel.text
                                    ]
                                    []
                                ]
                            )

                    else
                        Lazy.lazy5 SplitWindow.view
                            OnStartWindowResize
                            model.diagramModel.settings.backgroundColor
                            model.window
                            (div [ class "bg-main w-full h-main lg:h-full" ]
                                [ div
                                    [ id "editor", class "full" ]
                                    []
                                ]
                            )
              in
              case model.page of
                Page.List ->
                    Lazy.lazy DiagramList.view model.diagramListModel |> Html.map UpdateDiagramList

                Page.Help ->
                    Help.view

                Page.Share ->
                    Lazy.lazy Share.view model.shareModel |> Html.map UpdateShare

                Page.Settings ->
                    Lazy.lazy Settings.view model.settingsModel |> Html.map UpdateSettings

                Page.Tags m ->
                    Lazy.lazy Tags.view m |> Html.map UpdateTags

                Page.Embed _ _ _ ->
                    div [ style "width" "100%", style "height" "100%", style "background-color" model.settingsModel.settings.storyMap.backgroundColor ]
                        [ Lazy.lazy Diagram.view model.diagramModel
                            |> Html.map UpdateDiagram
                        ]

                Page.New ->
                    New.view

                Page.NotFound ->
                    NotFound.view

                _ ->
                    mainWindow
                        (Lazy.lazy Diagram.view model.diagramModel
                            |> Html.map UpdateDiagram
                        )
            ]
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
        div [ style "height" "4px", style "background" "#273037" ] []

    else
        Empty.view


showNotification : Maybe Notification -> Html Msg
showNotification notify =
    case notify of
        Nothing ->
            Empty.view

        Just notification ->
            Notification.view notification



-- Update


loadText : DiagramItem.DiagramItem -> Model -> Return Msg Model
loadText diagram model =
    Return.return model (Task.attempt Load <| Task.succeed diagram)


loadTextToEditor : Model -> Return Msg Model
loadTextToEditor model =
    Return.return model (Ports.loadText <| Text.toString model.diagramModel.text)


loadEditor : ( String, EditorSettings ) -> Model -> Return Msg Model
loadEditor editorSettings model =
    Return.return model (Ports.loadEditor editorSettings)


changeRouteInit : Model -> Return Msg Model
changeRouteInit model =
    Return.return model (Task.perform Init Dom.getViewport)


startProgress : Model -> Return Msg Model
startProgress model =
    Return.singleton { model | progress = True }


stopProgress : Model -> Return Msg Model
stopProgress model =
    Return.singleton { model | progress = False }


closeNotification : Model -> Return Msg Model
closeNotification model =
    Return.return model (Utils.delay 3000 OnCloseNotification)


showWarningMessage : String -> Model -> Return Msg Model
showWarningMessage msg model =
    Return.return model (Task.perform identity (Task.succeed (OnNotification (Warning msg))))
        |> Return.andThen closeNotification


showInfoMessage : String -> Model -> Return Msg Model
showInfoMessage msg model =
    Return.return model (Task.perform identity (Task.succeed (OnNotification (Info msg))))
        |> Return.andThen closeNotification


showErrorMessage : String -> Model -> Return Msg Model
showErrorMessage msg model =
    Return.return model (Task.perform identity (Task.succeed (OnNotification (Error msg))))
        |> Return.andThen closeNotification


openFullscreen : Model -> Return Msg Model
openFullscreen model =
    Return.return model (Ports.openFullscreen ())


closeFullscreen : Model -> Return Msg Model
closeFullscreen model =
    Return.return model (Ports.closeFullscreen ())


saveDiagram : DiagramItem -> Model -> Return Msg Model
saveDiagram item model =
    Return.return model (Ports.saveDiagram <| DiagramItem.encoder item)


saveToLocal : DiagramItem -> Model -> Return Msg Model
saveToLocal item model =
    Return.return model (Ports.saveDiagram <| DiagramItem.encoder { item | isRemote = False })


saveToRemote : DiagramItem -> Model -> Return Msg Model
saveToRemote diagram model =
    let
        saveTask =
            Request.save { url = model.apiRoot, idToken = Session.getIdToken model.session } (DiagramItem.toInputItem diagram) diagram.isPublic
                |> Task.mapError (\_ -> diagram)
    in
    Return.return model (Task.attempt SaveToRemoteCompleted saveTask)


setFocus : String -> Model -> Return Msg Model
setFocus id model =
    Effect.focus NoOp id model


pushUrl : String -> Model -> Return Msg Model
pushUrl url model =
    Return.return model (Nav.pushUrl model.key url)


changeRouteTo : Route -> Model -> Return Msg Model
changeRouteTo route model =
    case route of
        Route.DiagramList ->
            (if DiagramList.isNotAsked model.diagramListModel.diagramList then
                let
                    ( model_, cmd_ ) =
                        DiagramList.init model.session model.lang model.diagramListModel.apiRoot
                in
                ( { model | page = Page.List, diagramListModel = model_ }, cmd_ |> Cmd.map UpdateDiagramList )
                    |> Return.andThen startProgress

             else
                ( { model | page = Page.List }, Cmd.none )
                    |> Return.andThen stopProgress
            )
                |> Return.andThen changeRouteInit

        Route.Tag ->
            case model.currentDiagram of
                Nothing ->
                    ( model, Cmd.none )

                Just diagram ->
                    let
                        ( model_, _ ) =
                            Tags.init (diagram.tags |> Maybe.withDefault [] |> List.map (Maybe.withDefault ""))
                    in
                    ( { model | page = Page.Tags model_ }, Cmd.none )

        Route.New ->
            ( { model | page = Page.New }, Cmd.none )

        Route.NotFound ->
            ( { model | page = Page.NotFound }, Cmd.none )

        Route.Embed diagram title path ->
            ( { model
                | window = model.window |> Page.windowOfFullscreen.set True
                , diagramModel =
                    model.diagramModel
                        |> DiagramModel.modelOfShowZoomControl.set False
                        |> DiagramModel.modelOfDiagramType.set (DiagramType.fromString diagram)
                , title = Title.fromString title
                , page = Page.Embed diagram title path
              }
            , Ports.decodeShareText path
            )
                |> Return.andThen changeRouteInit

        Route.Share diagram title path ->
            ( { model
                | diagramModel =
                    model.diagramModel
                        |> DiagramModel.modelOfDiagramType.set (DiagramType.fromString diagram)
                , title = percentDecode title |> Maybe.withDefault "" |> Title.fromString
                , page = Page.Main
              }
            , Ports.decodeShareText path
            )
                |> Return.andThen changeRouteInit

        Route.UsmView settingsJson ->
            changeRouteTo (Route.View "usm" settingsJson) model

        Route.View diagram settingsJson ->
            let
                maybeSettings =
                    percentDecode settingsJson
                        |> Maybe.andThen
                            (\x ->
                                D.decodeString settingsDecoder x |> Result.toMaybe
                            )

                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    model.diagramModel
                        |> DiagramModel.modelOfDiagramType.set (DiagramType.fromString diagram)

                updatedDiagramModel =
                    case maybeSettings of
                        Nothing ->
                            { newDiagramModel | showZoomControl = False, fullscreen = True }

                        Just settings ->
                            { newDiagramModel
                                | settings = settings.storyMap
                                , showZoomControl = False
                                , fullscreen = True
                                , text = Text.edit newDiagramModel.text (String.replace "\\n" "\n" (Maybe.withDefault "" settings.text))
                            }
            in
            (case maybeSettings of
                Nothing ->
                    ( model, Cmd.none )

                Just settings ->
                    let
                        ( settingsModel_, cmd_ ) =
                            Settings.init settings
                    in
                    ( { model
                        | settingsModel = settingsModel_
                        , diagramModel = updatedDiagramModel
                        , window =
                            { position = model.window.position
                            , moveStart = model.window.moveStart
                            , moveX = model.window.moveX
                            , fullscreen = True
                            }
                        , title = Title.fromString <| Maybe.withDefault "" settings.title
                        , page = Page.Main
                      }
                    , cmd_ |> Cmd.map UpdateSettings
                    )
            )
                |> Return.andThen changeRouteInit

        Route.Edit type_ ->
            let
                diagramType =
                    DiagramType.fromString type_

                defaultText =
                    DiagramType.defaultText diagramType
            in
            Return.singleton
                { model
                    | title = Title.untitled
                    , currentDiagram = Nothing
                    , diagramModel =
                        DiagramModel.updatedText
                            (model.diagramModel
                                |> DiagramModel.modelOfDiagramType.set diagramType
                            )
                            (Text.fromString defaultText)
                    , page = Page.Main
                }
                |> Return.andThen changeRouteInit

        Route.EditFile _ id_ ->
            let
                loadText_ =
                    (if Session.isSignedIn model.session then
                        ( { model | page = Page.Main }
                        , Task.attempt Load <| Request.item { url = model.apiRoot, idToken = Session.getIdToken model.session } (DiagramId.toString id_)
                        )

                     else
                        ( { model | page = Page.Main }
                        , Ports.getDiagram (DiagramId.toString id_)
                        )
                    )
                        |> Return.andThen changeRouteInit
            in
            case ( model.diagramListModel.diagramList, model.currentDiagram ) of
                ( DiagramList.DiagramList (Success d) _ _, _ ) ->
                    let
                        loadItem =
                            find (\diagram -> (DiagramItem.getId diagram |> DiagramId.toString) == DiagramId.toString id_) d
                    in
                    case loadItem of
                        Just item ->
                            if item.isRemote then
                                ( { model | page = Page.Main }
                                , Task.attempt Load <| Request.item { url = model.apiRoot, idToken = Session.getIdToken model.session } (DiagramId.toString id_)
                                )

                            else
                                ( { model | page = Page.Main }
                                , Task.attempt Load <| Task.succeed item
                                )

                        Nothing ->
                            ( { model | page = Page.NotFound }, Cmd.none )

                ( _, Just diagram ) ->
                    let
                        ( _, cmd_ ) =
                            changeRouteInit model
                    in
                    if (DiagramItem.getId diagram |> DiagramId.toString) == DiagramId.toString id_ then
                        ( { model | page = Page.Main }
                        , case ( model.page, Size.isZero model.diagramModel.size ) of
                            ( Page.Main, True ) ->
                                cmd_

                            ( Page.Main, False ) ->
                                Cmd.none

                            _ ->
                                cmd_
                        )

                    else
                        loadText_

                _ ->
                    loadText_

        Route.Home ->
            Return.singleton { model | page = Page.Main }
                |> Return.andThen changeRouteInit

        Route.Settings ->
            Return.singleton { model | page = Page.Settings }

        Route.Help ->
            Return.singleton { model | page = Page.Help }

        Route.SharingDiagram ->
            ( { model | page = Page.Share }
            , Ports.encodeShareText
                { diagramType =
                    DiagramType.toString model.diagramModel.diagramType
                , title = Just <| Title.toString model.title
                , text = Text.toString model.diagramModel.text
                }
            )
                |> Return.andThen startProgress


update : Msg -> Model -> Return Msg Model
update message model =
    case message of
        NoOp ->
            ( model, Cmd.none )

        UpdateShare msg ->
            case model.page of
                Page.Share ->
                    let
                        ( model_, cmd_ ) =
                            Share.update msg model.shareModel
                    in
                    Return.return { model | shareModel = model_, page = Page.Share } (cmd_ |> Cmd.map UpdateShare)

                _ ->
                    Return.singleton model

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
                    ( { model | page = Page.Tags model_, currentDiagram = Just newDiagram, diagramModel = DiagramModel.updatedText model.diagramModel (Text.change diagram.text) }, cmd_ |> Cmd.map UpdateTags )

                _ ->
                    Return.singleton model

        UpdateSettings msg ->
            let
                ( model_, cmd_ ) =
                    Settings.update msg model.settingsModel

                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    { diagramModel | settings = model_.settings.storyMap }
            in
            Return.return { model | page = Page.Settings, diagramModel = newDiagramModel, settingsModel = model_ } cmd_

        UpdateDiagram msg ->
            let
                ( model_, cmd_ ) =
                    Diagram.update msg model.diagramModel
            in
            case msg of
                DiagramModel.OnResize _ _ ->
                    ( { model | diagramModel = model_ }, cmd_ |> Cmd.map UpdateDiagram )

                DiagramModel.MoveItem ( _, _ ) ->
                    ( { model | diagramModel = model_ }, Ports.loadText <| Text.toString model_.text )

                DiagramModel.EndEditSelectedItem _ code isComposing ->
                    if code == 13 && not isComposing then
                        ( { model | diagramModel = model_ }, Ports.loadText <| Text.toString model_.text )

                    else
                        Return.singleton model

                DiagramModel.OnFontStyleChanged _ ->
                    case model.diagramModel.selectedItem of
                        Just _ ->
                            ( { model | diagramModel = model_ }, cmd_ |> Cmd.map UpdateDiagram )
                                |> Return.andThen loadTextToEditor

                        Nothing ->
                            Return.singleton model

                DiagramModel.OnColorChanged _ _ ->
                    case model.diagramModel.selectedItem of
                        Just _ ->
                            ( { model | diagramModel = model_ }, cmd_ |> Cmd.map UpdateDiagram )
                                |> Return.andThen loadTextToEditor

                        Nothing ->
                            Return.singleton model

                DiagramModel.ToggleFullscreen ->
                    ( { model
                        | window =
                            model.window
                                |> Page.windowOfFullscreen.set (not model.window.fullscreen)
                        , diagramModel = model_
                      }
                    , cmd_ |> Cmd.map UpdateDiagram
                    )
                        |> Return.andThen
                            (if not model.window.fullscreen then
                                openFullscreen

                             else
                                closeFullscreen
                            )

                _ ->
                    Return.return { model | diagramModel = model_ } (cmd_ |> Cmd.map UpdateDiagram)

        UpdateDiagramList subMsg ->
            let
                ( model_, cmd_ ) =
                    DiagramList.update subMsg model.diagramListModel
            in
            case subMsg of
                DiagramList.Select diagram ->
                    pushUrl
                        (Route.toString <|
                            EditFile (DiagramType.toString diagram.diagram) (DiagramItem.getId diagram)
                        )
                        model
                        |> Return.andThen startProgress

                DiagramList.Removed (Err e) ->
                    case e of
                        Http.GraphqlError _ _ ->
                            showErrorMessage (Translations.messageFailed model.lang) model

                        Http.HttpError Http.Timeout ->
                            showErrorMessage (Translations.messageRequestTimeout model.lang) model

                        Http.HttpError Http.NetworkError ->
                            showErrorMessage (Translations.messageNetworkError model.lang) model

                        Http.HttpError _ ->
                            showErrorMessage (Translations.messageFailed model.lang) model

                DiagramList.GotDiagrams (Err _) ->
                    showErrorMessage (Translations.messageFailed model.lang) model

                DiagramList.ImportComplete json ->
                    case DiagramItem.stringToList json of
                        Ok _ ->
                            ( { model | diagramListModel = model_ }, cmd_ |> Cmd.map UpdateDiagramList )
                                |> Return.andThen (showInfoMessage (Translations.messageImportCompleted model.lang))

                        Err _ ->
                            showErrorMessage (Translations.messageFailed model.lang) model

                _ ->
                    ( { model | diagramListModel = model_ }, cmd_ |> Cmd.map UpdateDiagramList )
                        |> Return.andThen stopProgress

        Init window ->
            let
                ( model_, cmd_ ) =
                    Diagram.update (DiagramModel.Init model.diagramModel.settings window (Text.toString model.diagramModel.text)) model.diagramModel
            in
            Return.return { model | diagramModel = model_ } (cmd_ |> Cmd.map UpdateDiagram)
                |> Return.andThen (loadText (model.currentDiagram |> Maybe.withDefault DiagramItem.empty))
                |> Return.andThen stopProgress

        DownloadCompleted ( x, y ) ->
            let
                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    { diagramModel | position = ( x, y ) }
            in
            ( { model | diagramModel = newDiagramModel }, Cmd.none )

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
                    ( model, Download.string (Title.toString model.title ++ ex) "text/plain" ddl )

                FileType.Markdown ex ->
                    ( model, Download.string (Title.toString model.title ++ ex) "text/plain" (Table.toString (Table.from model.diagramModel.items)) )

                FileType.PlainText ex ->
                    ( model, Download.string (Title.toString model.title ++ ex) "text/plain" (Text.toString model.diagramModel.text) )

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
                    ( model
                    , sub
                        { width = width
                        , height = height
                        , id = "usm"
                        , title = Title.toString model.title ++ extension
                        , x = 0
                        , y = 0
                        , text = Text.toString model.diagramModel.text
                        , diagramType = DiagramType.toString model.diagramModel.diagramType
                        }
                    )

        StartDownload info ->
            ( model, Cmd.batch [ Download.string (Title.toString model.title ++ info.extension) info.mimeType info.content, Task.perform identity (Task.succeed CloseMenu) ] )

        OpenMenu menu ->
            ( { model | openMenu = Just menu }, Cmd.none )

        CloseMenu ->
            ( { model | openMenu = Nothing }, Cmd.none )

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

                diagramListModel =
                    model.diagramListModel

                newDiagramListModel =
                    { diagramListModel | diagramList = DiagramList.notAsked }
            in
            if Title.isUntitled model.title then
                update StartEditTitle model

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
                Return.singleton { model | diagramListModel = newDiagramListModel, diagramModel = newDiagramModel }
                    |> Return.andThen (saveDiagram item)

        SaveToLocalCompleted diagramJson ->
            case D.decodeValue DiagramItem.decoder diagramJson of
                Ok item ->
                    ( { model | currentDiagram = Just item }
                    , Route.replaceRoute model.key
                        (Route.EditFile (DiagramType.toString item.diagram)
                            (case item.id of
                                Nothing ->
                                    DiagramId.fromString ""

                                Just diagramId ->
                                    diagramId
                            )
                        )
                    )
                        |> Return.andThen (showInfoMessage (Translations.messageSuccessfullySaved model.lang (Title.toString item.title)))

                Err _ ->
                    Return.singleton model

        SaveToRemote diagramJson ->
            let
                result =
                    D.decodeValue DiagramItem.decoder diagramJson
            in
            case result of
                Ok diagram ->
                    saveToRemote diagram model
                        |> Return.andThen startProgress

                Err _ ->
                    showWarningMessage ("Successfully \"" ++ Title.toString model.title ++ "\" saved.") model
                        |> Return.andThen stopProgress

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
            Return.singleton { model | currentDiagram = Just item }
                |> Return.andThen (saveToLocal item)
                |> Return.andThen stopProgress
                |> Return.andThen (showWarningMessage <| Translations.messageFailedSaved model.lang (Title.toString model.title))

        SaveToRemoteCompleted (Ok diagram) ->
            ( { model | currentDiagram = Just diagram }
            , Route.replaceRoute model.key
                (Route.EditFile (DiagramType.toString diagram.diagram)
                    (diagram.id |> Maybe.withDefault (DiagramId.fromString ""))
                )
            )
                |> Return.andThen stopProgress
                |> Return.andThen (showInfoMessage <| Translations.messageSuccessfullySaved model.lang (Title.toString model.title))

        Shortcuts x ->
            case x of
                "save" ->
                    if Text.isChanged model.diagramModel.text then
                        update Save model

                    else
                        Return.singleton model

                "open" ->
                    ( model, Nav.load <| Route.toString (toRoute model.url) )

                _ ->
                    Return.singleton model

        StartEditTitle ->
            Return.singleton { model | title = Title.edit model.title }
                |> Return.andThen (setFocus "title")

        EndEditTitle code isComposing ->
            if code == Events.keyEnter && not isComposing then
                let
                    diagramModel =
                        model.diagramModel

                    newDiagramModel =
                        { diagramModel | text = Text.change diagramModel.text }
                in
                ( { model | title = Title.view model.title, diagramModel = newDiagramModel }, Ports.focusEditor () )

            else
                Return.singleton model

        EditTitle title ->
            Return.singleton { model | title = Title.edit <| Title.fromString title }

        OnVisibilityChange visible ->
            case visible of
                Hidden ->
                    let
                        newStoryMap =
                            model.settingsModel.settings |> Settings.settingsOfFont.set model.settingsModel.settings.font

                        newSettings =
                            { position = Just model.window.position
                            , font = model.settingsModel.settings.font
                            , diagramId = Maybe.andThen (\d -> Maybe.andThen (\i -> Just <| DiagramId.toString i) d.id) model.currentDiagram
                            , storyMap = newStoryMap.storyMap
                            , text = Just (Text.toString model.diagramModel.text)
                            , title = Just <| Title.toString model.title
                            , editor = model.settingsModel.settings.editor
                            , diagram = model.currentDiagram
                            }

                        ( newSettingsModel, _ ) =
                            Settings.init newSettings
                    in
                    ( { model | settingsModel = newSettingsModel }
                    , Ports.saveSettings (settingsEncoder newSettings)
                    )

                _ ->
                    Return.singleton model

        OnStartWindowResize x ->
            Return.singleton
                { model
                    | window =
                        model.window
                            |> Page.windowOfMoveStart.set True
                            |> Page.windowOfMoveX.set x
                }

        Stop ->
            Return.singleton { model | window = model.window |> Page.windowOfMoveStart.set False }

        OnWindowResize x ->
            Return.return { model | window = { position = model.window.position + x - model.window.moveX, moveStart = True, moveX = x, fullscreen = model.window.fullscreen } } (Ports.layoutEditor 0)

        GetShortUrl (Err e) ->
            showErrorMessage ("Error. " ++ Utils.httpErrorToString e) model
                |> Return.andThen stopProgress

        GetShortUrl (Ok url) ->
            let
                shareModel =
                    model.shareModel

                newShareModel =
                    { shareModel | url = url }
            in
            Return.singleton { model | shareModel = newShareModel }
                |> Return.andThen stopProgress

        OnShareUrl shareInfo ->
            ( model, Ports.encodeShareText shareInfo )

        OnNotification notification ->
            Return.singleton { model | notification = Just notification }

        OnAutoCloseNotification notification ->
            Return.singleton { model | notification = Just notification }
                |> Return.andThen closeNotification

        OnCloseNotification ->
            Return.singleton { model | notification = Nothing }

        OnEncodeShareText path ->
            let
                shareUrl =
                    "https://app.textusm.com/share" ++ path

                embedUrl =
                    "https://app.textusm.com/embed" ++ path

                shareModel =
                    model.shareModel

                newShareModel =
                    { shareModel | embedUrl = embedUrl }
            in
            ( { model | shareModel = newShareModel }, Task.attempt GetShortUrl (UrlShorterApi.urlShorter (Session.getIdToken model.session) model.apiRoot shareUrl) )

        OnDecodeShareText text ->
            Return.return model (Ports.loadText text)

        SwitchWindow w ->
            Return.singleton { model | switchWindow = w }

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    pushUrl (Url.toString url) model

                Browser.External href ->
                    Return.return model (Nav.load href)

        UrlChanged url ->
            changeRouteTo (toRoute url) { model | url = url }

        SignIn provider ->
            Return.return model (Ports.signIn <| LoginProdiver.toString provider)
                |> Return.andThen startProgress

        SignOut ->
            ( { model | session = Session.guest, currentDiagram = Nothing }, Ports.signOut () )

        OnAuthStateChanged (Just user) ->
            let
                newModel =
                    { model | session = Session.signIn user }
            in
            (case ( toRoute model.url, model.currentDiagram ) of
                ( Route.EditFile type_ id_, Just diagram ) ->
                    if (DiagramItem.getId diagram |> DiagramId.toString) /= DiagramId.toString id_ then
                        pushUrl (Route.toString <| Route.EditFile type_ id_) newModel

                    else
                        Return.singleton newModel

                ( Route.EditFile type_ id_, _ ) ->
                    pushUrl (Route.toString <| Route.EditFile type_ id_) newModel

                ( Route.DiagramList, _ ) ->
                    pushUrl (Route.toString <| Route.Home) newModel

                _ ->
                    Return.singleton newModel
            )
                |> Return.andThen stopProgress
                |> Return.andThen (showInfoMessage "Signed In")

        OnAuthStateChanged Nothing ->
            Return.singleton { model | session = Session.guest }
                |> Return.andThen stopProgress

        Progress visible ->
            Return.singleton { model | progress = visible }

        Load (Ok diagram) ->
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
            Return.return
                { model
                    | title = newDiagram.title
                    , currentDiagram = Just newDiagram
                    , diagramModel = model_
                }
                (cmd_ |> Cmd.map UpdateDiagram)
                |> Return.andThen stopProgress
                |> Return.andThen (loadEditor ( Text.toString newDiagram.text, defaultEditorSettings model.settingsModel.settings.editor ))

        EditText text ->
            let
                ( model_, cmd_ ) =
                    Diagram.update (DiagramModel.OnChangeText text) model.diagramModel
            in
            Return.return { model | diagramModel = model_ } (cmd_ |> Cmd.map UpdateDiagram)

        Load (Err _) ->
            stopProgress model
                |> Return.andThen (showErrorMessage "Failed load diagram.")

        GotLocalDiagramJson json ->
            case D.decodeValue DiagramItem.decoder json of
                Ok item ->
                    loadText item model

                Err _ ->
                    Return.singleton model

        ChangePublicStatus isPublic ->
            case model.currentDiagram of
                Just diagram ->
                    let
                        saveTask =
                            Request.save { url = model.apiRoot, idToken = Session.getIdToken model.session } (DiagramItem.toInputItem diagram) isPublic
                                |> Task.mapError (\_ -> diagram)
                    in
                    ( model, Task.attempt ChangePublicStatusCompleted saveTask )
                        |> Return.andThen stopProgress

                _ ->
                    Return.singleton model

        ChangePublicStatusCompleted (Ok d) ->
            Return.singleton { model | currentDiagram = Just d }
                |> Return.andThen stopProgress
                |> Return.andThen (showInfoMessage <| "\"" ++ Title.toString d.title ++ "\"" ++ " published")

        ChangePublicStatusCompleted (Err _) ->
            showErrorMessage "Failed to change publishing settings" model
                |> Return.andThen stopProgress

        CloseFullscreen _ ->
            let
                ( model_, cmd_ ) =
                    Diagram.update DiagramModel.ToggleFullscreen model.diagramModel
            in
            Return.return { model | window = model.window |> Page.windowOfFullscreen.set False, diagramModel = model_ } (cmd_ |> Cmd.map UpdateDiagram)
                |> Return.andThen (loadEditor ( Text.toString model.diagramModel.text, defaultEditorSettings model.settingsModel.settings.editor ))



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ([ Ports.changeText (\text -> UpdateDiagram (DiagramModel.OnChangeText text))
         , Ports.startDownload StartDownload
         , Ports.gotLocalDiagramsJson (\json -> UpdateDiagramList (DiagramList.GotLocalDiagramsJson json))
         , Ports.reload (\_ -> UpdateDiagramList DiagramList.Reload)
         , onVisibilityChange OnVisibilityChange
         , onResize (\width height -> UpdateDiagram (DiagramModel.OnResize width height))
         , onMouseUp <| D.succeed <| UpdateDiagram DiagramModel.Stop
         , Ports.onEncodeShareText OnEncodeShareText
         , Ports.onDecodeShareText OnDecodeShareText
         , Ports.shortcuts Shortcuts
         , Ports.onNotification (\n -> OnAutoCloseNotification (Info n))
         , Ports.onErrorNotification (\n -> OnAutoCloseNotification (Error n))
         , Ports.onWarnNotification (\n -> OnAutoCloseNotification (Warning n))
         , Ports.onAuthStateChanged OnAuthStateChanged
         , Ports.saveToRemote SaveToRemote
         , Ports.removeRemoteDiagram (\diagram -> UpdateDiagramList <| DiagramList.RemoveRemote diagram)
         , Ports.downloadCompleted DownloadCompleted
         , Ports.progress Progress
         , Ports.saveToLocalCompleted SaveToLocalCompleted
         , Ports.gotLocalDiagramJson GotLocalDiagramJson
         , Ports.onCloseFullscreen CloseFullscreen
         ]
            ++ (if model.window.moveStart then
                    [ onMouseUp <| D.succeed Stop
                    , onMouseMove <| D.map OnWindowResize (D.field "pageX" D.int)
                    ]

                else
                    [ Sub.none ]
               )
        )
