module Main exposing (init, main, view)

import Api.UrlShorter as UrlShorterApi
import Browser
import Browser.Dom as Dom
import Browser.Events exposing (Visibility(..), onMouseMove, onMouseUp, onResize, onVisibilityChange)
import Browser.Navigation as Nav
import Components.Diagram as Diagram
import Data.DiagramItem as DiagramItem
import Data.DiagramType as DiagramType
import Data.Session as Session
import Data.Size as Size
import Data.Text as Text
import Data.Title as Title
import Events
import File.Download as Download
import GraphQL.Request as Request
import Graphql.Http as Http
import Html exposing (Html, a, div, img, main_, text)
import Html.Attributes exposing (alt, class, href, id, src, style, target)
import Html.Events as E
import Html.Lazy as Lazy
import Json.Decode as D
import List.Extra exposing (find, getAt, removeAt, setAt, splitAt)
import Models.Diagram as DiagramModel
import Models.Model as Page exposing (FileType(..), LoginProvider(..), Model, Msg(..), Notification(..), Page(..), SwitchWindow(..))
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
import Route exposing (Route(..), toRoute)
import Settings exposing (Settings, defaultEditorSettings, defaultSettings, settingsDecoder, settingsEncoder)
import String
import Task
import TextUSM.Enum.Diagram as Diagram
import Time
import Translations
import Url as Url exposing (percentDecode)
import Utils
import Views.Empty as Empty
import Views.Header as Header
import Views.Icon as Icon
import Views.Menu as Menu
import Views.Notification as Notification
import Views.ProgressBar as ProgressBar
import Views.SplitWindow as SplitWindow
import Views.SwitchWindow as SwitchWindow


init : ( ( String, String ), String ) -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        ( ( apiRoot, lang ), settingsJson ) =
            flags

        initSettings =
            D.decodeString settingsDecoder settingsJson
                |> Result.withDefault defaultSettings

        ( diagramListModel, _ ) =
            DiagramList.init Session.guest apiRoot

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
                , apiRoot = apiRoot
                , session = Session.guest
                , currentDiagram = initSettings.diagram
                , page = Page.Main
                , lang = Translations.fromString lang
                }
    in
    ( model, cmds )


bottomNavigationBar : Settings -> String -> String -> String -> Html Msg
bottomNavigationBar settings diagram title path =
    div
        [ class "bottom-nav-bar"
        , style "background-color" settings.storyMap.backgroundColor
        ]
        [ div
            [ style "display" "flex"
            , style "align-items" "center"
            ]
            [ div
                [ style "width"
                    "40px"
                , style "height"
                    "40px"
                , style "display" "flex"
                , style "justify-content" "center"
                , style "align-items" "center"
                ]
                [ a [ href "https://app.textusm.com", target "blank_", style "display" "flex", style "align-items" "center" ]
                    [ img [ src "/images/logo.svg", style "width" "32px", alt "logo" ] [] ]
                ]
            , a [ href <| "https://app.textusm.com/share/" ++ diagram ++ "/" ++ title ++ "/" ++ path, target "blank_", style "color" settings.storyMap.color.label ]
                [ text title ]
            ]
        , div [ class "buttons" ]
            [ div
                [ class "button"
                , E.onClick <| UpdateDiagram DiagramModel.ZoomIn
                ]
                [ Icon.add 24 ]
            , div
                [ class "button"
                , E.onClick <| UpdateDiagram DiagramModel.ZoomOut
                ]
                [ Icon.remove 24 ]
            ]
        ]


view : Model -> Html Msg
view model =
    main_
        [ style "position" "relative"
        , style "width" "100vw"
        , E.onClick CloseMenu
        ]
        [ Lazy.lazy Header.view { session = model.session, page = model.page, title = model.title, isFullscreen = model.window.fullscreen, currentDiagram = model.currentDiagram, menu = model.openMenu, currentText = model.diagramModel.text, lang = model.lang }
        , Lazy.lazy showNotification model.notification
        , Lazy.lazy2 showProgressbar model.progress model.window.fullscreen
        , div
            [ class "main"
            , if model.window.fullscreen then
                style "height" "100vh"

              else
                style "height" "calc(100vh - 56px)"
            ]
            [ Lazy.lazy Menu.view { page = model.page, route = toRoute model.url, text = model.diagramModel.text, width = Size.getWidth model.diagramModel.size, fullscreen = model.window.fullscreen, openMenu = model.openMenu, lang = model.lang }
            , let
                mainWindow =
                    if Size.getWidth model.diagramModel.size > 0 && Utils.isPhone (Size.getWidth model.diagramModel.size) then
                        Lazy.lazy5 SwitchWindow.view
                            SwitchWindow
                            model.diagramModel.settings.backgroundColor
                            model.switchWindow

                    else
                        Lazy.lazy5 SplitWindow.view
                            OnStartWindowResize
                            model.diagramModel.settings.backgroundColor
                            model.window
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

                Page.Embed diagram title path ->
                    div [ style "width" "100%", style "height" "100%", style "background-color" model.settingsModel.settings.storyMap.backgroundColor ]
                        [ let
                            diagramModel =
                                model.diagramModel
                          in
                          Lazy.lazy Diagram.view diagramModel
                            |> Html.map UpdateDiagram
                        , Lazy.lazy4 bottomNavigationBar model.settingsModel.settings diagram title path
                        ]

                Page.New ->
                    New.view

                Page.NotFound ->
                    NotFound.view

                _ ->
                    mainWindow
                        (div
                            [ style "background-color" "#273037"
                            , style "width" "100%"
                            , style "height" "100%"
                            ]
                            [ div
                                [ id "editor"
                                , style "width" "100%"
                                , style "height" "100%"
                                ]
                                []
                            ]
                        )
                        (Lazy.lazy Diagram.view model.diagramModel
                            |> Html.map UpdateDiagram
                        )
            ]
        ]


main : Program ( ( String, String ), String ) Model Msg
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
        Just notification ->
            Notification.view notification

        Nothing ->
            Empty.view



-- Update


loadText : DiagramItem.DiagramItem -> Cmd Msg
loadText diagram =
    Task.attempt Load <| Task.succeed diagram


changeRouteTo : Route -> Model -> ( Model, Cmd Msg )
changeRouteTo route model =
    let
        cmds : List (Cmd Msg) -> Cmd Msg
        cmds c =
            Cmd.batch <| Task.perform Init Dom.getViewport :: c
    in
    case route of
        Route.List ->
            if RemoteData.isNotAsked model.diagramListModel.diagramList || List.isEmpty (RemoteData.withDefault [] model.diagramListModel.diagramList) then
                let
                    ( model_, cmd_ ) =
                        DiagramList.init model.session model.diagramListModel.apiRoot
                in
                ( { model
                    | page = Page.List
                    , progress = True
                    , diagramListModel = model_
                  }
                , cmds [ cmd_ |> Cmd.map UpdateDiagramList ]
                )

            else
                ( { model | page = Page.List, progress = False }, Cmd.none )

        Route.Tag ->
            case model.currentDiagram of
                Just diagram ->
                    let
                        ( model_, _ ) =
                            Tags.init (diagram.tags |> Maybe.withDefault [] |> List.map (Maybe.withDefault ""))
                    in
                    ( { model | page = Page.Tags model_ }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        Route.New ->
            ( { model | page = Page.New }, Cmd.none )

        Route.NotFound ->
            ( { model | page = Page.NotFound }, Cmd.none )

        Route.Embed diagram title path ->
            let
                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    { diagramModel
                        | diagramType =
                            DiagramType.fromString diagram
                        , showZoomControl = False
                    }
            in
            ( { model
                | window =
                    { position = model.window.position
                    , moveStart = model.window.moveStart
                    , moveX = model.window.moveX
                    , fullscreen = True
                    }
                , diagramModel = newDiagramModel
                , title = Title.fromString title
                , page = Page.Embed diagram title path
              }
            , cmds [ Ports.decodeShareText path ]
            )

        Route.Share diagram title path ->
            let
                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    { diagramModel
                        | diagramType =
                            DiagramType.fromString diagram
                    }
            in
            ( { model
                | diagramModel = newDiagramModel
                , title = percentDecode title |> Maybe.withDefault "" |> Title.fromString
                , page = Page.Main
              }
            , cmds [ Ports.decodeShareText path ]
            )

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
                    { diagramModel
                        | diagramType =
                            DiagramType.fromString diagram
                    }

                updatedDiagramModel =
                    case maybeSettings of
                        Just settings ->
                            { newDiagramModel
                                | settings = settings.storyMap
                                , showZoomControl = False
                                , fullscreen = True
                                , text = Text.edit newDiagramModel.text (String.replace "\\n" "\n" (Maybe.withDefault "" settings.text))
                            }

                        Nothing ->
                            { newDiagramModel | showZoomControl = False, fullscreen = True }
            in
            case maybeSettings of
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
                    , cmds [ cmd_ |> Cmd.map UpdateSettings ]
                    )

                Nothing ->
                    ( model, cmds [] )

        Route.Edit type_ ->
            let
                diagramType =
                    DiagramType.fromString type_

                defaultText =
                    case diagramType of
                        Diagram.BusinessModelCanvas ->
                            "👥 Key Partners\n📊 Customer Segments\n🎁 Value Proposition\n✅ Key Activities\n🚚 Channels\n💰 Revenue Streams\n🏷️ Cost Structure\n💪 Key Resources\n💙 Customer Relationships"

                        Diagram.OpportunityCanvas ->
                            "Problems\nSolution Ideas\nUsers and Customers\nSolutions Today\nBusiness Challenges\nHow will Users use Solution?\nUser Metrics\nAdoption Strategy\nBusiness Benefits and Metrics\nBudget"

                        Diagram.Fourls ->
                            "Liked\nLearned\nLacked\nLonged for"

                        Diagram.StartStopContinue ->
                            "Start\nStop\nContinue"

                        Diagram.Kpt ->
                            "K\nP\nT"

                        Diagram.UserPersona ->
                            "Name\n    https://app.textusm.com/images/logo.svg\nWho am i...\nThree reasons to use your product\nThree reasons to buy your product\nMy interests\nMy personality\nMy Skills\nMy dreams\nMy relationship with technology"

                        Diagram.EmpathyMap ->
                            "SAYS\nTHINKS\nDOES\nFEELS"

                        Diagram.Table ->
                            "Column1\n    Column2\n    Column3\n    Column4\n    Column5\n    Column6\n    Column7\nRow1\n    Column1\n    Column2\n    Column3\n    Column4\n    Column5\n    Column6\nRow2\n    Column1\n    Column2\n    Column3\n    Column4\n    Column5\n    Column6"

                        Diagram.GanttChart ->
                            "2019-12-26,2020-01-31\n    title1\n        subtitle1\n            2019-12-26, 2019-12-31\n    title2\n        subtitle2\n            2019-12-31, 2020-01-04\n"

                        Diagram.ErDiagram ->
                            "relations\n    # one to one\n    Table1 - Table2\n    # one to many\n    Table1 < Table3\ntables\n    Table1\n        id int pk auto_increment\n        name varchar(255) unique\n        rate float null\n        value double not null\n        values enum(value1,value2) not null\n    Table2\n        id int pk auto_increment\n        name double unique\n    Table3\n        id int pk auto_increment\n        name varchar(255) index\n"

                        Diagram.Kanban ->
                            "TODO\nDOING\nDONE"

                        _ ->
                            ""

                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    { diagramModel | diagramType = diagramType }
            in
            ( { model
                | title = Title.untitled
                , currentDiagram = Nothing
                , diagramModel = DiagramModel.updatedText newDiagramModel (Text.fromString defaultText)
                , page = Page.Main
              }
            , cmds
                [ setEditorLanguage diagramType
                ]
            )

        Route.EditFile _ id_ ->
            let
                loadText_ =
                    if Session.isSignedIn model.session then
                        ( { model | page = Page.Main }
                        , cmds [ Task.attempt Load <| Request.item { url = model.apiRoot, idToken = Session.getIdToken model.session } id_ ]
                        )

                    else
                        ( { model | page = Page.Main }
                        , cmds [ Ports.getDiagram id_ ]
                        )
            in
            case ( model.diagramListModel.diagramList, model.currentDiagram ) of
                ( Success d, _ ) ->
                    let
                        loadItem =
                            find (\diagram -> Maybe.withDefault "" diagram.id == id_) d
                    in
                    case loadItem of
                        Just item ->
                            if item.isRemote then
                                ( { model | page = Page.Main }
                                , Task.attempt Load <| Request.item { url = model.apiRoot, idToken = Session.getIdToken model.session } id_
                                )

                            else
                                ( { model | page = Page.Main }
                                , Task.attempt Load <| Task.succeed item
                                )

                        Nothing ->
                            ( { model | page = Page.NotFound }, Cmd.none )

                ( _, Just diagram ) ->
                    if Maybe.withDefault "" diagram.id == id_ then
                        ( { model | page = Page.Main }
                        , case ( model.page, Size.isZero model.diagramModel.size ) of
                            ( Page.Main, True ) ->
                                cmds []

                            ( Page.Main, False ) ->
                                Cmd.none

                            _ ->
                                cmds []
                        )

                    else
                        loadText_

                _ ->
                    loadText_

        Route.Home ->
            ( { model | page = Page.Main }, cmds [] )

        Route.Settings ->
            ( { model | page = Page.Settings }, Cmd.none )

        Route.Help ->
            ( { model | page = Page.Help }, Cmd.none )

        Route.SharingDiagram ->
            ( { model | page = Page.Share, progress = True }
            , Cmd.batch
                [ Ports.encodeShareText
                    { diagramType =
                        DiagramType.toString model.diagramModel.diagramType
                    , title = Just <| Title.toString model.title
                    , text = Text.toString model.diagramModel.text
                    }
                ]
            )


update : Msg -> Model -> ( Model, Cmd Msg )
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
                    ( { model | shareModel = model_, page = Page.Share }, cmd_ )

                _ ->
                    ( model, Cmd.none )

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
                    ( { model
                        | page = Page.Tags model_
                        , currentDiagram = Just newDiagram
                        , diagramModel = DiagramModel.updatedText model.diagramModel (Text.change <| Text.fromString diagram.text)
                      }
                    , cmd_ |> Cmd.map UpdateTags
                    )

                _ ->
                    ( model, Cmd.none )

        UpdateSettings msg ->
            let
                ( model_, cmd_ ) =
                    Settings.update msg model.settingsModel

                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    { diagramModel | settings = model_.settings.storyMap }
            in
            ( { model
                | page = Page.Settings
                , diagramModel = newDiagramModel
                , settingsModel = model_
              }
            , cmd_
            )

        UpdateDiagram msg ->
            case msg of
                DiagramModel.OnResize _ _ ->
                    let
                        ( model_, cmd_ ) =
                            Diagram.update msg model.diagramModel
                    in
                    ( { model | diagramModel = model_ }
                    , Cmd.batch
                        [ cmd_ |> Cmd.map UpdateDiagram
                        ]
                    )

                DiagramModel.MoveItem ( fromNo, toNo ) ->
                    let
                        lines =
                            Text.lines model.diagramModel.text

                        from =
                            getAt fromNo lines
                                |> Maybe.withDefault ""

                        newLines =
                            removeAt fromNo lines

                        ( left, right ) =
                            splitAt
                                (if fromNo < toNo then
                                    toNo - 1

                                 else
                                    toNo
                                )
                                newLines

                        text =
                            left
                                ++ from
                                :: right
                                |> String.join "\n"
                    in
                    ( model
                    , Cmd.batch
                        [ Task.perform identity (Task.succeed (UpdateDiagram DiagramModel.DeselectItem))
                        , Ports.loadText text
                        ]
                    )

                DiagramModel.EndEditSelectedItem item code isComposing ->
                    if code == 13 && not isComposing then
                        let
                            lines =
                                Text.lines model.diagramModel.text

                            currentText =
                                getAt item.lineNo lines

                            prefix =
                                currentText
                                    |> Maybe.withDefault ""
                                    |> Utils.getSpacePrefix

                            text =
                                setAt item.lineNo (prefix ++ String.trimLeft item.text) lines
                                    |> String.join "\n"
                        in
                        ( model
                        , Cmd.batch
                            [ Task.perform identity (Task.succeed (UpdateDiagram DiagramModel.DeselectItem))
                            , Ports.loadText text
                            ]
                        )

                    else
                        ( model, Cmd.none )

                DiagramModel.ToggleFullscreen ->
                    let
                        window =
                            model.window

                        newWindow =
                            { window | fullscreen = not window.fullscreen }

                        ( model_, cmd_ ) =
                            Diagram.update msg model.diagramModel
                    in
                    ( { model | window = newWindow, diagramModel = model_ }
                    , Cmd.batch
                        [ cmd_ |> Cmd.map UpdateDiagram
                        , if newWindow.fullscreen then
                            Ports.openFullscreen ()

                          else
                            Ports.closeFullscreen ()
                        ]
                    )

                _ ->
                    let
                        ( model_, cmd_ ) =
                            Diagram.update msg model.diagramModel
                    in
                    ( { model | diagramModel = model_ }, cmd_ |> Cmd.map UpdateDiagram )

        UpdateDiagramList subMsg ->
            case subMsg of
                DiagramList.Select diagram ->
                    ( { model
                        | progress = True
                      }
                    , Nav.pushUrl model.key
                        (Route.toString <|
                            EditFile (DiagramType.toString diagram.diagram)
                                (Maybe.withDefault "" diagram.id)
                        )
                    )

                DiagramList.Removed (Err e) ->
                    case e of
                        Http.GraphqlError _ _ ->
                            ( model, Notification.showErrorMessage <| Translations.messageFailed model.lang )

                        Http.HttpError Http.Timeout ->
                            ( model, Notification.showErrorMessage <| Translations.messageRequestTimeout model.lang )

                        Http.HttpError Http.NetworkError ->
                            ( model, Notification.showErrorMessage <| Translations.messageNetworkError model.lang )

                        Http.HttpError _ ->
                            ( model, Notification.showErrorMessage <| Translations.messageFailed model.lang )

                DiagramList.GotDiagrams (Err _) ->
                    ( model, Notification.showErrorMessage <| Translations.messageFailed model.lang )

                _ ->
                    let
                        ( model_, cmd_ ) =
                            DiagramList.update subMsg model.diagramListModel
                    in
                    ( { model | progress = False, diagramListModel = model_ }
                    , cmd_ |> Cmd.map UpdateDiagramList
                    )

        Init window ->
            let
                ( model_, cmd_ ) =
                    Diagram.update (DiagramModel.Init model.diagramModel.settings window (Text.toString model.diagramModel.text)) model.diagramModel
            in
            ( { model
                | diagramModel = model_
                , progress = False
              }
            , Cmd.batch
                [ case model.currentDiagram of
                    Just diagram ->
                        loadText diagram

                    Nothing ->
                        loadText DiagramItem.empty
                , cmd_ |> Cmd.map UpdateDiagram
                ]
            )

        DownloadCompleted ( x, y ) ->
            let
                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    { diagramModel | position = ( x, y ), matchParent = False }
            in
            ( { model | diagramModel = newDiagramModel }, Cmd.none )

        Download fileType ->
            case fileType of
                Ddl ->
                    let
                        ( _, tables ) =
                            ER.fromItems model.diagramModel.items

                        ddl =
                            List.map ER.tableToString tables
                                |> String.join "\n"
                    in
                    ( model, Download.string (Title.toString model.title ++ ".sql") "text/plain" ddl )

                MarkdownTable ->
                    ( model, Download.string (Title.toString model.title ++ ".md") "text/plain" (Table.toString (Table.fromItems model.diagramModel.items)) )

                PlainText ->
                    ( model, Download.string (Title.toString model.title) "text/plain" (Text.toString model.diagramModel.text) )

                _ ->
                    let
                        ( width, height ) =
                            Utils.getCanvasSize model.diagramModel

                        diagramModel =
                            model.diagramModel

                        newDiagramModel =
                            { diagramModel | position = ( 0, 0 ), matchParent = True }

                        ( sub, extension ) =
                            case fileType of
                                Png ->
                                    ( Ports.downloadPng, ".png" )

                                Pdf ->
                                    ( Ports.downloadPdf, ".pdf" )

                                Svg ->
                                    ( Ports.downloadSvg, ".svg" )

                                Html ->
                                    ( Ports.downloadHtml, ".html" )

                                _ ->
                                    ( Ports.downloadSvg, ".svg" )
                    in
                    ( { model | diagramModel = newDiagramModel }
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
                    { diagramListModel | diagramList = RemoteData.NotAsked }
            in
            if Title.isUntitled model.title then
                update StartEditTitle model

            else
                let
                    newDiagramModel =
                        DiagramModel.updatedText model.diagramModel (Text.saved model.diagramModel.text)
                in
                ( { model
                    | diagramListModel = newDiagramListModel
                    , diagramModel = newDiagramModel
                  }
                , Cmd.batch
                    [ Ports.saveDiagram <|
                        DiagramItem.encoder
                            { id = Maybe.andThen .id model.currentDiagram
                            , title = Title.toString model.title
                            , text = Text.toString newDiagramModel.text
                            , thumbnail = Nothing
                            , diagram = newDiagramModel.diagramType
                            , isRemote = isRemote
                            , isPublic = False
                            , isBookmark = False
                            , tags = Maybe.andThen .tags model.currentDiagram
                            , updatedAt = Time.millisToPosix 0
                            , createdAt = Time.millisToPosix 0
                            }
                    , Cmd.none
                    ]
                )

        SaveToLocalCompleted diagramJson ->
            case D.decodeString DiagramItem.decoder diagramJson of
                Ok item ->
                    ( { model | currentDiagram = Just item }
                    , Cmd.batch
                        [ Notification.showInfoMessage <| Translations.messageSuccessfullySaved model.lang item.title
                        , Route.replaceRoute model.key
                            (Route.EditFile (DiagramType.toString item.diagram) (Maybe.withDefault "" item.id))
                        ]
                    )

                Err _ ->
                    ( model, Cmd.none )

        SaveToRemote diagramJson ->
            let
                result =
                    D.decodeString DiagramItem.decoder diagramJson
                        |> Result.andThen
                            (\diagram ->
                                Ok
                                    (Request.save { url = model.apiRoot, idToken = Session.getIdToken model.session } (DiagramItem.toInputItem diagram)
                                        |> Task.mapError (\_ -> diagram)
                                    )
                            )
            in
            case result of
                Ok saveTask ->
                    ( { model | progress = True }, Task.attempt SaveToRemoteCompleted saveTask )

                Err _ ->
                    ( { model | progress = True }, Notification.showWarningMessage ("Successfully \"" ++ Title.toString model.title ++ "\" saved.") )

        SaveToRemoteCompleted (Err _) ->
            let
                item =
                    { id = Nothing
                    , title = Title.toString model.title
                    , text = Text.toString model.diagramModel.text
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
            ( { model | progress = False, currentDiagram = Just item }
            , Cmd.batch
                [ Notification.showWarningMessage <| Translations.messageFailedSaved model.lang (Title.toString model.title)
                , Ports.saveDiagram <| DiagramItem.encoder item
                ]
            )

        SaveToRemoteCompleted (Ok diagram) ->
            ( { model | currentDiagram = Just diagram, progress = False }
            , Cmd.batch
                [ Notification.showInfoMessage <| Translations.messageSuccessfullySaved model.lang (Title.toString model.title)
                , Route.replaceRoute model.key
                    (Route.EditFile (DiagramType.toString diagram.diagram) (Maybe.withDefault "" diagram.id))
                ]
            )

        Shortcuts x ->
            case x of
                "save" ->
                    if Text.isChanged model.diagramModel.text then
                        update Save model

                    else
                        ( model, Cmd.none )

                "open" ->
                    ( model, Nav.load <| Route.toString (toRoute model.url) )

                _ ->
                    ( model, Cmd.none )

        StartEditTitle ->
            ( { model | title = Title.edit model.title }, Task.attempt (\_ -> NoOp) <| Dom.focus "title" )

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
                ( model, Cmd.none )

        EditTitle title ->
            ( { model | title = Title.edit <| Title.fromString title }, Cmd.none )

        OnVisibilityChange visible ->
            case visible of
                Hidden ->
                    let
                        newStoryMap =
                            model.settingsModel.settings |> Settings.settingsOfFont.set model.settingsModel.settings.font

                        newSettings =
                            { position = Just model.window.position
                            , font = model.settingsModel.settings.font
                            , diagramId = Maybe.andThen .id model.currentDiagram
                            , storyMap = newStoryMap.storyMap
                            , text = Just (Text.toString model.diagramModel.text)
                            , title =
                                Just <| Title.toString model.title
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
                    ( model, Cmd.none )

        OnStartWindowResize x ->
            let
                window =
                    model.window

                newWindow =
                    { window | moveStart = True, moveX = x }
            in
            ( { model | window = newWindow }, Cmd.none )

        Stop ->
            let
                window =
                    model.window

                newWindow =
                    { window | moveStart = False }
            in
            ( { model | window = newWindow }, Cmd.none )

        OnWindowResize x ->
            ( { model
                | window =
                    { position = model.window.position + x - model.window.moveX
                    , moveStart = True
                    , moveX = x
                    , fullscreen = model.window.fullscreen
                    }
              }
            , Ports.layoutEditor 0
            )

        GetShortUrl (Err e) ->
            ( { model | progress = False }, Notification.showErrorMessage ("Error. " ++ Utils.httpErrorToString e) )

        GetShortUrl (Ok url) ->
            let
                shareModel =
                    model.shareModel

                newShareModel =
                    { shareModel | url = url }
            in
            ( { model
                | progress = False
                , shareModel = newShareModel
              }
            , Cmd.none
            )

        OnShareUrl shareInfo ->
            ( model
            , Ports.encodeShareText shareInfo
            )

        OnNotification notification ->
            ( { model | notification = Just notification }, Cmd.none )

        OnAutoCloseNotification notification ->
            ( { model | notification = Just notification }, Utils.delay 3000 OnCloseNotification )

        OnCloseNotification ->
            ( { model | notification = Nothing }, Cmd.none )

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
            ( model, Ports.loadText text )

        SwitchWindow w ->
            ( { model | switchWindow = w }, Ports.layoutEditor 100 )

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            changeRouteTo (toRoute url) { model | url = url }

        SignIn provider ->
            ( { model | progress = True }
            , Ports.signIn <|
                case provider of
                    Google ->
                        "Google"

                    Github ->
                        "Github"
            )

        SignOut ->
            ( { model | session = Session.guest, currentDiagram = Nothing }, Ports.signOut () )

        OnAuthStateChanged (Just user) ->
            let
                newModel =
                    { model | session = Session.signIn user, progress = False }
            in
            case ( toRoute model.url, model.currentDiagram ) of
                ( Route.EditFile type_ id_, Just diagram ) ->
                    if Maybe.withDefault "" diagram.id /= id_ then
                        ( newModel, Nav.pushUrl model.key (Route.toString <| Route.EditFile type_ id_) )

                    else
                        ( newModel, Cmd.none )

                ( Route.EditFile type_ id_, _ ) ->
                    ( newModel, Nav.pushUrl model.key (Route.toString <| Route.EditFile type_ id_) )

                ( Route.List, _ ) ->
                    let
                        diagramListModel =
                            model.diagramListModel

                        newDiagramListModel =
                            { diagramListModel | diagramList = NotAsked }
                    in
                    ( { newModel | diagramListModel = newDiagramListModel }, Nav.pushUrl model.key (Route.toString <| Route.List) )

                _ ->
                    ( newModel, Cmd.none )

        OnAuthStateChanged Nothing ->
            ( { model | session = Session.guest, progress = False }, Cmd.none )

        Progress visible ->
            ( { model | progress = visible }, Cmd.none )

        Load (Ok diagram) ->
            let
                newDiagram =
                    case diagram.id of
                        Just _ ->
                            diagram

                        Nothing ->
                            { diagram
                                | title = Title.toString model.title
                                , text = Text.toString model.diagramModel.text
                                , diagram = model.diagramModel.diagramType
                            }

                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    { diagramModel
                        | diagramType = newDiagram.diagram
                        , text = Text.fromString newDiagram.text
                    }

                ( model_, cmd_ ) =
                    Diagram.update (DiagramModel.OnChangeText newDiagram.text) newDiagramModel
            in
            ( { model
                | progress = False
                , title = Title.fromString newDiagram.title
                , currentDiagram = Just newDiagram
                , diagramModel = model_
              }
            , Cmd.batch
                [ Ports.loadEditor ( newDiagram.text, defaultEditorSettings model.settingsModel.settings.editor )
                , cmd_ |> Cmd.map UpdateDiagram
                , setEditorLanguage newDiagram.diagram
                ]
            )

        Load (Err _) ->
            ( { model | progress = False }, Notification.showErrorMessage "Failed load diagram." )

        GotLocalDiagramJson json ->
            case D.decodeString DiagramItem.decoder json of
                Ok item ->
                    ( model, loadText item )

                Err _ ->
                    ( model, Cmd.none )


setEditorLanguage : Diagram.Diagram -> Cmd Msg
setEditorLanguage diagram =
    if diagram == Diagram.Markdown then
        Ports.setEditorLanguage "markdown"

    else
        Ports.setEditorLanguage "userStoryMap"



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ([ Ports.changeText (\text -> UpdateDiagram (DiagramModel.OnChangeText text))
         , Ports.startDownload StartDownload
         , Ports.gotLocalDiagramsJson (\json -> UpdateDiagramList (DiagramList.GotLocalDiagramsJson json))
         , Ports.removedDiagram (\_ -> UpdateDiagramList DiagramList.Reload)
         , onVisibilityChange OnVisibilityChange
         , onResize (\width height -> UpdateDiagram (DiagramModel.OnResize width height))
         , onMouseUp (D.succeed (UpdateDiagram DiagramModel.Stop))
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
         ]
            ++ (if model.window.moveStart then
                    [ onMouseUp (D.succeed Stop)
                    , onMouseMove (D.map OnWindowResize (D.field "pageX" D.int))
                    ]

                else
                    [ Sub.none ]
               )
        )
