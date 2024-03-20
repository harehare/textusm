module View.Menu exposing (MenuInfo, MenuItem(..), Props, docs, menu, view)

import Attributes
import Css
import Css.Global exposing (class, descendants)
import Css.Transitions as Transitions
import Diagram.Types.Item as DiagramItem exposing (DiagramItem)
import Diagram.Types.Location as DiagramLocation
import Diagram.Types.Type exposing (DiagramType(..))
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Events
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events exposing (onClick, stopPropagationOn)
import Html.Styled.Lazy as Lazy
import Json.Decode as D
import List
import Message exposing (Lang)
import Page.Types as Page
import Route exposing (Route)
import Style.Breakpoint as Breakpoint
import Style.Color as ColorStyle
import Style.Font as FontStyle
import Style.Global as GlobalStyle
import Style.Style as Style
import Style.Text as TextStyle
import Types exposing (BrowserStatus, Menu(..))
import Types.Color as Color
import Types.Export.Diagram as ExportDiagram
import Types.FileType as FileType
import Types.Settings as Settings exposing (Settings)
import Types.Text as Text exposing (Text)
import Types.Theme as Theme
import Utils.Common as Utils
import View.Empty as Empty
import View.Icon as Icon


type alias MenuInfo msg =
    { e : Maybe msg
    , title : String
    }


type MenuItem msg
    = MenuItem (MenuInfo msg)


type alias Props msg =
    { page : Page.Page
    , route : Route
    , lang : Lang
    , text : Text
    , width : Int
    , openMenu : Maybe Menu
    , settings : Settings
    , browserStatus : BrowserStatus
    , currentDiagram : DiagramItem
    , onOpenLocalFile : msg
    , onOpenMenu : Menu -> msg
    , onDownload : ExportDiagram.Export -> msg
    , onSaveLocalFile : msg
    , onSave : msg
    , onOpenCurrentFile : msg
    }


isEditFile : Route -> Bool
isEditFile route =
    case route of
        Route.Edit _ _ _ ->
            True

        Route.EditFile _ _ ->
            True

        Route.EditLocalFile _ _ ->
            True

        _ ->
            False


newMenu : Lang -> Html msg
newMenu lang =
    Html.a
        [ Attr.class "new-menu"
        , Attr.href <| Route.toString <| Route.New
        , Attr.attribute "aria-label" "New"
        , Attributes.dataTestId "new-menu"
        , css [ Style.hoverAnimation ]
        ]
        [ Html.div
            [ css
                [ Style.mlXs
                , menuButtonStyle
                ]
            ]
            [ Icon.file Color.iconColor 18
            , Html.span [ Attr.class "tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipNewFile lang ] ]
            ]
        ]


editMenu : { diagramItem : DiagramItem, lang : Lang, route : Route, onOpenCurrentFile : msg } -> Html msg
editMenu { diagramItem, lang, route, onOpenCurrentFile } =
    case route of
        Route.Edit _ _ _ ->
            Lazy.lazy newMenu lang

        Route.EditFile _ _ ->
            Lazy.lazy newMenu lang

        Route.EditLocalFile _ _ ->
            Lazy.lazy newMenu lang

        Route.NotFound ->
            Lazy.lazy newMenu lang

        _ ->
            case diagramItem.id of
                Just _ ->
                    Html.div
                        [ Attr.class "edit-menu"
                        , onClick onOpenCurrentFile
                        , Attr.attribute "aria-label" "Edit"
                        , Attributes.dataTestId "edit-menu"
                        ]
                        [ Html.div [ css [ menuButtonStyle ] ]
                            [ Icon.edit Color.iconColor 20
                            , Html.span [ Attr.class "tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipEditFile lang ] ]
                            ]
                        ]

                Nothing ->
                    newMenu lang


menu : { bottom : Maybe Int, left : Maybe Int, right : Maybe Int, top : Maybe Int } -> List (MenuItem msg) -> Html msg
menu pos items =
    Html.div
        [ css
            [ Maybe.map (\p -> Css.batch [ Css.top <| Css.px <| toFloat <| p ]) pos.top |> Maybe.withDefault (Css.batch [])
            , Maybe.map (\p -> Css.batch [ Css.left <| Css.px <| toFloat <| p ]) pos.left |> Maybe.withDefault (Css.batch [])
            , Maybe.map (\p -> Css.batch [ Css.right <| Css.px <| toFloat <| p ]) pos.right |> Maybe.withDefault (Css.batch [])
            , Maybe.map (\p -> Css.batch [ Css.bottom <| Css.px <| toFloat <| p ]) pos.bottom |> Maybe.withDefault (Css.batch [])
            , Css.minWidth <| Css.px 128
            , Css.maxHeight <| Css.calc (Css.vh 100) Css.minus (Css.px 40)
            , Transitions.transition [ Transitions.boxShadow3 200 200 Transitions.easeOut ]
            , Style.m1
            , Css.overflow Css.hidden
            , ColorStyle.bgMenuColor
            , Css.position Css.absolute
            , Style.rounded
            , Css.zIndex <| Css.int 10
            , Style.shadowSm
            ]
        ]
        (items
            |> List.map
                (\(MenuItem menuItem) ->
                    Html.div
                        [ css
                            [ TextStyle.base
                            , ColorStyle.textColor
                            , Css.cursor Css.pointer
                            , Css.displayFlex
                            , Css.alignItems Css.center
                            , Css.height <| Css.px 40
                            , Css.hover
                                [ Css.backgroundColor <| Css.rgba 0 0 0 0.3
                                ]
                            ]
                        , case menuItem.e of
                            Just e ->
                                onClick e

                            Nothing ->
                                Attr.class ""
                        , menuItem.title
                            ++ "-menu-item"
                            |> String.replace " " ""
                            |> String.toLower
                            |> Attributes.dataTestId
                        ]
                        [ Html.div
                            [ css
                                [ Breakpoint.style
                                    [ Css.cursor Css.pointer
                                    , TextStyle.sm
                                    , FontStyle.fontBold
                                    , Css.padding2 Css.zero (Css.px 16)
                                    , Style.mt0
                                    ]
                                    [ Breakpoint.large [ Css.padding <| Css.px 16 ]
                                    ]
                                ]
                            ]
                            [ Html.text menuItem.title
                            ]
                        ]
                )
        )


view : Props msg -> Html msg
view { page, lang, width, route, text, openMenu, settings, browserStatus, currentDiagram, onOpenLocalFile, onOpenMenu, onDownload, onSave, onSaveLocalFile, onOpenCurrentFile } =
    Html.nav
        [ css
            [ Breakpoint.style
                [ Css.displayFlex
                , Css.flexDirection Css.row
                , Css.alignItems Css.center
                , Css.justifyContent Css.spaceBetween
                , ColorStyle.bgMain
                , Style.shadowSm
                , Css.bottom Css.zero
                , Style.widthScreen
                , Css.position Css.fixed
                , Css.zIndex <| Css.int 10
                , Css.minWidth <| Css.px 40
                , ColorStyle.bgMenuColor
                ]
                [ Breakpoint.large
                    [ Css.justifyContent Css.start
                    , Style.heightScreen
                    , Css.position Css.relative
                    , Css.flexDirection Css.column
                    , Style.wMenu
                    ]
                ]
            ]
        , Attributes.dataTestId "menu"
        ]
        [ editMenu { diagramItem = currentDiagram, lang = lang, route = route, onOpenCurrentFile = onOpenCurrentFile }
        , Html.div
            [ css [ menuButtonStyle ] ]
            [ case settings.location of
                Just DiagramLocation.LocalFileSystem ->
                    Html.div
                        [ Events.onClickPreventDefaultOn onOpenLocalFile
                        , Attr.attribute "aria-label" "List"
                        , Attributes.dataTestId "list-menu"
                        , css [ Style.hoverAnimation ]
                        ]
                        [ Icon.folderOpen (Color.toString Color.iconColor) 18
                        , Html.span [ Attr.class "tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipOpenFile lang ] ]
                        ]

                _ ->
                    Html.div [ css [ Style.hoverAnimation ] ]
                        [ Html.a
                            [ Attr.href <| Route.toString Route.DiagramList
                            , Attr.attribute "aria-label" "List"
                            , Attributes.dataTestId "list-menu"
                            ]
                            [ Icon.folderOpen
                                (if page == Page.List then
                                    Color.toString Color.disabledIconColor

                                 else
                                    Color.toString Color.iconColor
                                )
                                18
                            , Html.span [ Attr.class "tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipOpenFile lang ] ]
                            ]
                        ]
            ]
        , if Text.isChanged text then
            Html.div
                [ case settings.location of
                    Just DiagramLocation.LocalFileSystem ->
                        onClick onSaveLocalFile

                    _ ->
                        onClick onSave
                , css [ menuButtonStyle ]
                , Attributes.dataTestId "save-menu"
                , css [ Style.hoverAnimation ]
                ]
                [ Icon.save (Color.toString Color.iconColor) 22
                , Html.span [ Attr.class "tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipSave lang ] ]
                ]

          else
            Html.div
                [ css [ menuButtonStyle ]
                , Attributes.dataTestId "disabled-save-menu"
                ]
                [ Icon.save (Color.toString Color.disabledIconColor) 22
                , Html.span [ Attr.class "tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipSave lang ] ]
                ]
        , Html.div
            [ if isEditFile route then
                stopPropagationOn "click" (D.succeed ( onOpenMenu Export, True ))

              else
                Attr.style "" ""
            , css [ menuButtonStyle ]
            , Attributes.dataTestId "download-menu"
            , css [ Style.hoverAnimation ]
            ]
            [ Icon.download
                (if isEditFile route then
                    Color.toString Color.iconColor

                 else
                    Color.toString Color.disabledIconColor
                )
                18
            , Html.span [ Attr.class "tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipExport lang ] ]
            ]
        , if Utils.isPhone width then
            case openMenu of
                Just Export ->
                    menu { bottom = Just 50, left = Just (width // 5 * 3), right = Nothing, top = Nothing } (exportMenu { route = route, browserStatus = browserStatus, onDownload = onDownload })

                _ ->
                    Empty.view

          else
            case openMenu of
                Just Export ->
                    menu { bottom = Nothing, left = Just 40, right = Nothing, top = Just 125 } (exportMenu { route = route, browserStatus = browserStatus, onDownload = onDownload })

                _ ->
                    Empty.view
        ]


baseExportMenu : { browserStatus : BrowserStatus, onDownload : ExportDiagram.Export -> msg } -> List (MenuItem msg)
baseExportMenu { browserStatus, onDownload } =
    [ MenuItem
        { e = Just <| onDownload <| ExportDiagram.downloadable FileType.svg
        , title = FileType.toString FileType.svg
        }
    , MenuItem
        { e = Just <| onDownload <| ExportDiagram.downloadable FileType.png
        , title = FileType.toString FileType.png
        }
    , MenuItem
        { e = Just <| onDownload <| ExportDiagram.downloadable FileType.pdf
        , title = FileType.toString FileType.pdf
        }
    , MenuItem
        { e = Just <| onDownload <| ExportDiagram.downloadable FileType.plainText
        , title = FileType.toString FileType.plainText
        }
    , MenuItem
        { e = Just <| onDownload <| ExportDiagram.downloadable FileType.html
        , title = FileType.toString FileType.html
        }
    ]
        ++ (if browserStatus.canUseClipboardItem then
                [ MenuItem
                    { e = Just <| onDownload <| ExportDiagram.copyable FileType.png
                    , title = "Copy " ++ FileType.toString FileType.png
                    }
                , MenuItem
                    { e = Just <| onDownload <| ExportDiagram.copyable FileType.Base64
                    , title = "Copy " ++ FileType.toString FileType.Base64
                    }
                ]

            else
                []
           )


exportMenu : { route : Route, browserStatus : BrowserStatus, onDownload : ExportDiagram.Export -> msg } -> List (MenuItem msg)
exportMenu { route, browserStatus, onDownload } =
    case route of
        Route.Edit GanttChart _ _ ->
            MenuItem
                { e = Just <| onDownload <| ExportDiagram.copyable FileType.mermaid
                , title = "Mermaid"
                }
                :: baseExportMenu { browserStatus = browserStatus, onDownload = onDownload }

        Route.Edit ErDiagram _ _ ->
            MenuItem
                { e = Just <| onDownload <| ExportDiagram.copyable FileType.ddl
                , title = "DDL"
                }
                :: MenuItem
                    { e = Just <| onDownload <| ExportDiagram.copyable FileType.mermaid
                    , title = "Mermaid"
                    }
                :: baseExportMenu { browserStatus = browserStatus, onDownload = onDownload }

        Route.Edit Table _ _ ->
            MenuItem
                { e = Just <| onDownload <| ExportDiagram.copyable FileType.markdown
                , title = "Markdown"
                }
                :: baseExportMenu { browserStatus = browserStatus, onDownload = onDownload }

        Route.Edit SequenceDiagram _ _ ->
            MenuItem
                { e = Just <| onDownload <| ExportDiagram.copyable FileType.mermaid
                , title = "Mermaid"
                }
                :: baseExportMenu { browserStatus = browserStatus, onDownload = onDownload }

        Route.EditFile GanttChart _ ->
            MenuItem
                { e = Just <| onDownload <| ExportDiagram.copyable FileType.mermaid
                , title = "Mermaid"
                }
                :: baseExportMenu { browserStatus = browserStatus, onDownload = onDownload }

        Route.EditFile ErDiagram _ ->
            MenuItem
                { e = Just <| onDownload <| ExportDiagram.copyable FileType.ddl
                , title = "DDL"
                }
                :: MenuItem
                    { e = Just <| onDownload <| ExportDiagram.copyable FileType.mermaid
                    , title = "Mermaid"
                    }
                :: baseExportMenu { browserStatus = browserStatus, onDownload = onDownload }

        Route.EditFile Table _ ->
            MenuItem
                { e = Just <| onDownload <| ExportDiagram.copyable FileType.markdown
                , title = "Markdown"
                }
                :: baseExportMenu { browserStatus = browserStatus, onDownload = onDownload }

        Route.EditFile SequenceDiagram _ ->
            MenuItem
                { e = Just <| onDownload <| ExportDiagram.copyable FileType.mermaid
                , title = "Mermaid"
                }
                :: baseExportMenu { browserStatus = browserStatus, onDownload = onDownload }

        _ ->
            baseExportMenu { browserStatus = browserStatus, onDownload = onDownload }


menuButtonStyle : Css.Style
menuButtonStyle =
    Css.batch
        [ Breakpoint.style
            [ Css.cursor Css.pointer
            , Css.marginBottom <| Css.px 8
            , Css.padding <| Css.px 16
            , Css.marginBottom Css.zero
            ]
            [ Breakpoint.large [ Css.padding <| Css.px 0, Css.paddingTop <| Css.px 16 ] ]
        , Css.hover
            [ Css.position Css.relative
            , descendants
                [ class "tooltip"
                    [ Css.visibility Css.visible
                    , Css.opacity <| Css.int 100
                    , ColorStyle.textColor
                    ]
                ]
            ]
        ]


docs : Chapter x
docs =
    Chapter.chapter "Menu"
        |> Chapter.renderComponent
            (Html.div []
                [ GlobalStyle.style
                , view
                    { page = Page.Main
                    , route = Route.Home
                    , lang = Message.En
                    , text = Text.empty
                    , width = 128
                    , openMenu = Nothing
                    , settings = Settings.defaultSettings Theme.Dark
                    , browserStatus =
                        { isOnline = True
                        , isDarkMode = True
                        , canUseClipboardItem = True
                        , canUseNativeFileSystem = True
                        }
                    , currentDiagram = DiagramItem.empty
                    , onOpenLocalFile = Actions.logAction "onOpenLocalFile"
                    , onOpenMenu = \_ -> Actions.logAction "onOpenMenu"
                    , onDownload = \_ -> Actions.logAction "onDownload"
                    , onSaveLocalFile = Actions.logAction "onSaveLocalFile"
                    , onSave = Actions.logAction "onSave"
                    , onOpenCurrentFile = Actions.logAction "onOpenCurrentFile"
                    }
                ]
                |> Html.toUnstyled
            )
