module Views.Menu exposing (MenuInfo, MenuItem(..), Props, menu, view, docs)

import Attributes
import Css
    exposing
        ( absolute
        , alignItems
        , backgroundColor
        , bottom
        , calc
        , center
        , column
        , cursor
        , displayFlex
        , fixed
        , flexDirection
        , height
        , hidden
        , hover
        , int
        , justifyContent
        , left
        , marginBottom
        , maxHeight
        , minWidth
        , minus
        , opacity
        , overflow
        , padding
        , padding2
        , paddingTop
        , pointer
        , position
        , px
        , relative
        , rgba
        , right
        , row
        , spaceBetween
        , start
        , top
        , vh
        , visibility
        , visible
        , zIndex
        , zero
        )
import Css.Global exposing (class, descendants)
import Css.Transitions as Transitions
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Events
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Html.Styled.Events exposing (onClick, stopPropagationOn)
import Html.Styled.Lazy as Lazy
import Json.Decode as D
import List
import Message exposing (Lang)
import Models.Color as Color
import Models.Diagram.Item as DiagramItem exposing (DiagramItem)
import Models.Diagram.Location as DiagramLocation
import Models.Diagram.Type exposing (DiagramType(..))
import Models.Exporter as Exporter
import Models.FileType as FileType
import Models.Model exposing (BrowserStatus, Menu(..), Msg(..))
import Models.Page as Page
import Models.Text as Text exposing (Text)
import Models.Theme as Theme
import Route exposing (Route)
import Settings exposing (Settings)
import Style.Breakpoint as Breakpoint
import Style.Color as ColorStyle
import Style.Font as FontStyle
import Style.Style as Style
import Style.Text as TextStyle
import Utils.Utils as Utils
import Views.Empty as Empty
import Views.Icon as Icon


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
    , onCopy : msg
    , onDownload : Exporter.Export -> msg
    , onSaveLocalFile : msg
    , onSave : msg
    , onOpenCurrentFile : msg
    }


isEditFile : Route -> Bool
isEditFile route =
    case route of
        Route.Edit _ ->
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
        , Attributes.dataTest "new-menu"
        ]
        [ Html.div
            [ Attr.css
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
        Route.Edit _ ->
            Lazy.lazy newMenu lang

        Route.EditFile _ _ ->
            Lazy.lazy newMenu lang

        Route.EditLocalFile _ _ ->
            Lazy.lazy newMenu lang

        _ ->
            case diagramItem.id of
                Just _ ->
                    Html.div
                        [ Attr.class "edit-menu"
                        , onClick onOpenCurrentFile
                        , Attr.attribute "aria-label" "Edit"
                        , Attributes.dataTest "edit-menu"
                        ]
                        [ Html.div
                            [ Attr.css
                                [ menuButtonStyle
                                ]
                            ]
                            [ Icon.edit Color.iconColor 20
                            , Html.span [ Attr.class "tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipEditFile lang ] ]
                            ]
                        ]

                Nothing ->
                    newMenu lang


menu : { bottom : Maybe Int, left : Maybe Int, right : Maybe Int, top : Maybe Int } -> List (MenuItem msg) -> Html msg
menu pos items =
    Html.div
        [ Attr.css
            [ Maybe.map (\p -> Css.batch [ top <| px <| toFloat <| p ]) pos.top |> Maybe.withDefault (Css.batch [])
            , Maybe.map (\p -> Css.batch [ left <| px <| toFloat <| p ]) pos.left |> Maybe.withDefault (Css.batch [])
            , Maybe.map (\p -> Css.batch [ right <| px <| toFloat <| p ]) pos.right |> Maybe.withDefault (Css.batch [])
            , Maybe.map (\p -> Css.batch [ bottom <| px <| toFloat <| p ]) pos.bottom |> Maybe.withDefault (Css.batch [])
            , minWidth <| px 128
            , maxHeight <| calc (vh 100) minus (px 40)
            , Transitions.transition [ Transitions.boxShadow3 200 200 Transitions.easeOut ]
            , Style.m1
            , overflow hidden
            , ColorStyle.bgMenuColor
            , position absolute
            , Style.rounded
            , zIndex <| int 10
            , Style.shadowSm
            ]
        ]
        (items
            |> List.map
                (\(MenuItem menuItem) ->
                    Html.div
                        [ Attr.css
                            [ TextStyle.base
                            , ColorStyle.textColor
                            , cursor pointer
                            , displayFlex
                            , alignItems center
                            , height <| px 40
                            , hover
                                [ backgroundColor <| rgba 0 0 0 0.3
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
                            |> Attributes.dataTest
                        ]
                        [ Html.div
                            [ Attr.css
                                [ Breakpoint.style
                                    [ cursor pointer
                                    , TextStyle.sm
                                    , FontStyle.fontBold
                                    , padding2 zero (px 16)
                                    , Style.mt0
                                    ]
                                    [ Breakpoint.large [ padding <| px 16 ]
                                    ]
                                ]
                            ]
                            [ Html.text menuItem.title
                            ]
                        ]
                )
        )


view : Props msg -> Html msg
view { page, lang, width, route, text, openMenu, settings, browserStatus, currentDiagram, onOpenLocalFile, onOpenMenu, onCopy, onDownload, onSave, onSaveLocalFile, onOpenCurrentFile } =
    Html.nav
        [ Attr.css
            [ Breakpoint.style
                [ displayFlex
                , flexDirection row
                , alignItems center
                , justifyContent spaceBetween
                , ColorStyle.bgMain
                , Style.shadowSm
                , bottom zero
                , Style.widthScreen
                , position fixed
                , zIndex <| int 10
                , minWidth <| px 40
                , ColorStyle.bgMenuColor
                ]
                [ Breakpoint.large
                    [ justifyContent start
                    , Style.heightScreen
                    , position relative
                    , flexDirection column
                    , Style.wMenu
                    ]
                ]
            ]
        , Attributes.dataTest "menu"
        ]
        [ editMenu { diagramItem = currentDiagram, lang = lang, route = route, onOpenCurrentFile = onOpenCurrentFile }
        , Html.div
            [ Attr.css [ menuButtonStyle ] ]
            [ case settings.location of
                Just DiagramLocation.LocalFileSystem ->
                    Html.div
                        [ Events.onClickPreventDefaultOn onOpenLocalFile
                        , Attr.attribute "aria-label" "List"
                        , Attributes.dataTest "list-menu"
                        ]
                        [ Icon.folderOpen (Color.toString Color.iconColor) 18
                        , Html.span [ Attr.class "tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipOpenFile lang ] ]
                        ]

                _ ->
                    Html.a
                        [ Attr.href <| Route.toString Route.DiagramList
                        , Attr.attribute "aria-label" "List"
                        , Attributes.dataTest "list-menu"
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
        , if Text.isChanged text then
            Html.div
                [ case settings.location of
                    Just DiagramLocation.LocalFileSystem ->
                        onClick onSaveLocalFile

                    _ ->
                        onClick onSave
                , Attr.css [ menuButtonStyle ]
                , Attributes.dataTest "save-menu"
                ]
                [ Icon.save (Color.toString Color.iconColor) 22
                , Html.span [ Attr.class "tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipSave lang ] ]
                ]

          else
            Html.div
                [ Attr.css [ menuButtonStyle ]
                , Attributes.dataTest "disabled-save-menu"
                ]
                [ Icon.save (Color.toString Color.disabledIconColor) 22
                , Html.span [ Attr.class "tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipSave lang ] ]
                ]
        , Html.div
            [ if isEditFile route then
                stopPropagationOn "click" (D.succeed ( onOpenMenu Export, True ))

              else
                Attr.style "" ""
            , Attr.css [ menuButtonStyle ]
            , Attributes.dataTest "download-menu"
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
        , if not (isEditFile route) || Text.isChanged text then
            Html.div
                [ Attr.css [ menuButtonStyle ]
                , Attributes.dataTest "copy-menu"
                ]
                [ Icon.copy Color.disabledIconColor 19
                , Html.span [ Attr.class "tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipCopy lang ] ]
                ]

          else
            Html.div
                [ Attr.css [ menuButtonStyle ]
                , Events.onClickStopPropagation onCopy
                , Attributes.dataTest "copy-menu"
                ]
                [ Icon.copy Color.iconColor 19
                , Html.span [ Attr.class "tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipCopy lang ] ]
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


baseExportMenu : { browserStatus : BrowserStatus, onDownload : Exporter.Export -> msg } -> List (MenuItem msg)
baseExportMenu { browserStatus, onDownload } =
    [ MenuItem
        { e = Just <| onDownload <| Exporter.downloadable FileType.svg
        , title = FileType.toString FileType.svg
        }
    , MenuItem
        { e = Just <| onDownload <| Exporter.downloadable FileType.png
        , title = FileType.toString FileType.png
        }
    , MenuItem
        { e = Just <| onDownload <| Exporter.downloadable FileType.pdf
        , title = FileType.toString FileType.pdf
        }
    , MenuItem
        { e = Just <| onDownload <| Exporter.downloadable FileType.plainText
        , title = FileType.toString FileType.plainText
        }
    , MenuItem
        { e = Just <| onDownload <| Exporter.downloadable FileType.html
        , title = FileType.toString FileType.html
        }
    ]
        ++ (if browserStatus.canUseClipboardItem then
                [ MenuItem
                    { e = Just <| onDownload <| Exporter.copyable FileType.png
                    , title = "Copy " ++ FileType.toString FileType.png
                    }
                , MenuItem
                    { e = Just <| onDownload <| Exporter.copyable FileType.Base64
                    , title = "Copy " ++ FileType.toString FileType.Base64
                    }
                ]

            else
                []
           )


exportMenu : { route : Route, browserStatus : BrowserStatus, onDownload : Exporter.Export -> msg } -> List (MenuItem msg)
exportMenu { route, browserStatus, onDownload } =
    case route of
        Route.Edit GanttChart ->
            MenuItem
                { e = Just <| onDownload <| Exporter.copyable FileType.mermaid
                , title = "Mermaid"
                }
                :: baseExportMenu { browserStatus = browserStatus, onDownload = onDownload }

        Route.Edit ErDiagram ->
            MenuItem
                { e = Just <| onDownload <| Exporter.copyable FileType.ddl
                , title = "DDL"
                }
                :: MenuItem
                    { e = Just <| onDownload <| Exporter.copyable FileType.mermaid
                    , title = "Mermaid"
                    }
                :: baseExportMenu { browserStatus = browserStatus, onDownload = onDownload }

        Route.Edit Table ->
            MenuItem
                { e = Just <| onDownload <| Exporter.copyable FileType.markdown
                , title = "Markdown"
                }
                :: baseExportMenu { browserStatus = browserStatus, onDownload = onDownload }

        Route.Edit SequenceDiagram ->
            MenuItem
                { e = Just <| onDownload <| Exporter.copyable FileType.mermaid
                , title = "Mermaid"
                }
                :: baseExportMenu { browserStatus = browserStatus, onDownload = onDownload }

        Route.EditFile GanttChart _ ->
            MenuItem
                { e = Just <| onDownload <| Exporter.copyable FileType.mermaid
                , title = "Mermaid"
                }
                :: baseExportMenu { browserStatus = browserStatus, onDownload = onDownload }

        Route.EditFile ErDiagram _ ->
            MenuItem
                { e = Just <| onDownload <| Exporter.copyable FileType.ddl
                , title = "DDL"
                }
                :: MenuItem
                    { e = Just <| onDownload <| Exporter.copyable FileType.mermaid
                    , title = "Mermaid"
                    }
                :: baseExportMenu { browserStatus = browserStatus, onDownload = onDownload }

        Route.EditFile Table _ ->
            MenuItem
                { e = Just <| onDownload <| Exporter.copyable FileType.markdown
                , title = "Markdown"
                }
                :: baseExportMenu { browserStatus = browserStatus, onDownload = onDownload }

        Route.EditFile SequenceDiagram _ ->
            MenuItem
                { e = Just <| onDownload <| Exporter.copyable FileType.mermaid
                , title = "Mermaid"
                }
                :: baseExportMenu { browserStatus = browserStatus, onDownload = onDownload }

        _ ->
            baseExportMenu { browserStatus = browserStatus, onDownload = onDownload }


menuButtonStyle : Css.Style
menuButtonStyle =
    Css.batch
        [ Breakpoint.style
            [ cursor pointer
            , marginBottom <| px 8
            , padding <| px 16
            , marginBottom zero
            ]
            [ Breakpoint.large [ padding <| px 0, paddingTop <| px 16 ] ]
        , hover
            [ position relative
            , descendants
                [ class "tooltip"
                    [ visibility visible
                    , opacity <| int 100
                    , ColorStyle.textColor
                    ]
                ]
            ]
        ]


docs : Chapter x
docs =
    Chapter.chapter "Menu"
        |> Chapter.renderComponent
            (view
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
                , onCopy = Actions.logAction "onCopy"
                , onDownload = \_ -> Actions.logAction "onDownload"
                , onSaveLocalFile = Actions.logAction "onSaveLocalFile"
                , onSave = Actions.logAction "onSave"
                , onOpenCurrentFile = Actions.logAction "onOpenCurrentFile"
                }
                |> Html.toUnstyled
            )
