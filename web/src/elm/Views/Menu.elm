module Views.Menu exposing (MenuInfo, MenuItem(..), Props, menu, view)

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
import Events
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Html.Styled.Events exposing (onClick, stopPropagationOn)
import Json.Decode as D
import List
import Message exposing (Lang)
import Models.Color as Color
import Models.Diagram.Item exposing (DiagramItem)
import Models.Diagram.Location as DiagramLocation
import Models.Diagram.Type exposing (DiagramType(..))
import Models.Exporter as Exporter
import Models.FileType as FileType
import Models.Model exposing (BrowserStatus, Menu(..), Msg(..))
import Models.Page as Page
import Models.Text as Text exposing (Text)
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
    { e : msg
    , title : String
    }


type MenuItem msg
    = MenuItem (MenuInfo msg)


type alias Props =
    { page : Page.Page
    , route : Route
    , lang : Lang
    , text : Text
    , width : Int
    , openMenu : Maybe Menu
    , settings : Settings
    , browserStatus : BrowserStatus
    , currentDiagram : DiagramItem
    }


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
                        , onClick menuItem.e
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


view : Props -> Html Msg
view { page, lang, width, route, text, openMenu, settings, browserStatus, currentDiagram } =
    let
        newMenu : Html msg
        newMenu =
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

        isEditFile : Bool
        isEditFile =
            case route of
                Route.Edit _ ->
                    True

                Route.EditFile _ _ ->
                    True

                Route.EditLocalFile _ _ ->
                    True

                _ ->
                    False
    in
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
        [ case route of
            Route.Edit _ ->
                newMenu

            Route.EditFile _ _ ->
                newMenu

            Route.EditLocalFile _ _ ->
                newMenu

            _ ->
                case currentDiagram.id of
                    Just _ ->
                        Html.div
                            [ Attr.class "edit-menu"
                            , onClick OpenCurrentFile
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
                        newMenu
        , Html.div
            [ Attr.css [ menuButtonStyle ] ]
            [ case settings.location of
                Just DiagramLocation.LocalFileSystem ->
                    Html.div
                        [ Events.onClickPreventDefaultOn OpenLocalFile
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
                        onClick SaveLocalFile

                    _ ->
                        onClick Save
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
            [ if isEditFile then
                stopPropagationOn "click" (D.succeed ( OpenMenu Export, True ))

              else
                Attr.style "" ""
            , Attr.css [ menuButtonStyle ]
            , Attributes.dataTest "download-menu"
            ]
            [ Icon.download
                (if isEditFile then
                    Color.toString Color.iconColor

                 else
                    Color.toString Color.disabledIconColor
                )
                18
            , Html.span [ Attr.class "tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipExport lang ] ]
            ]
        , if not isEditFile || Text.isChanged text then
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
                , Events.onClickStopPropagation Copy
                , Attributes.dataTest "copy-menu"
                ]
                [ Icon.copy Color.iconColor 19
                , Html.span [ Attr.class "tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipCopy lang ] ]
                ]
        , if Utils.isPhone width then
            case openMenu of
                Just Export ->
                    menu { bottom = Just 50, left = Just (width // 5 * 3), right = Nothing, top = Nothing } (exportMenu route browserStatus)

                _ ->
                    Empty.view

          else
            case openMenu of
                Just Export ->
                    menu { bottom = Nothing, left = Just 40, right = Nothing, top = Just 125 } (exportMenu route browserStatus)

                _ ->
                    Empty.view
        ]


baseExportMenu : BrowserStatus -> List (MenuItem Msg)
baseExportMenu browserStatus =
    [ MenuItem
        { e = Download <| Exporter.downloadable FileType.svg
        , title = FileType.toString FileType.svg
        }
    , MenuItem
        { e = Download <| Exporter.downloadable FileType.png
        , title = FileType.toString FileType.png
        }
    , MenuItem
        { e = Download <| Exporter.downloadable FileType.pdf
        , title = FileType.toString FileType.pdf
        }
    , MenuItem
        { e = Download <| Exporter.downloadable FileType.plainText
        , title = FileType.toString FileType.plainText
        }
    , MenuItem
        { e = Download <| Exporter.downloadable FileType.html
        , title = FileType.toString FileType.html
        }
    ]
        ++ (if browserStatus.canUseClipboardItem then
                [ MenuItem
                    { e = Download <| Exporter.copyable FileType.png
                    , title = "Copy " ++ FileType.toString FileType.png
                    }
                , MenuItem
                    { e = Download <| Exporter.copyable FileType.Base64
                    , title = "Copy " ++ FileType.toString FileType.Base64
                    }
                ]

            else
                []
           )


exportMenu : Route -> BrowserStatus -> List (MenuItem Msg)
exportMenu route browserStatus =
    case route of
        Route.Edit GanttChart ->
            MenuItem
                { e = Download <| Exporter.copyable FileType.mermaid
                , title = "Mermaid"
                }
                :: baseExportMenu browserStatus

        Route.Edit ErDiagram ->
            MenuItem
                { e = Download <| Exporter.copyable FileType.ddl
                , title = "DDL"
                }
                :: MenuItem
                    { e = Download <| Exporter.copyable FileType.mermaid
                    , title = "Mermaid"
                    }
                :: baseExportMenu browserStatus

        Route.Edit Table ->
            MenuItem
                { e = Download <| Exporter.copyable FileType.markdown
                , title = "Markdown"
                }
                :: baseExportMenu browserStatus

        Route.Edit SequenceDiagram ->
            MenuItem
                { e = Download <| Exporter.copyable FileType.mermaid
                , title = "Mermaid"
                }
                :: baseExportMenu browserStatus

        Route.EditFile GanttChart _ ->
            MenuItem
                { e = Download <| Exporter.copyable FileType.mermaid
                , title = "Mermaid"
                }
                :: baseExportMenu browserStatus

        Route.EditFile ErDiagram _ ->
            MenuItem
                { e = Download <| Exporter.copyable FileType.ddl
                , title = "DDL"
                }
                :: MenuItem
                    { e = Download <| Exporter.copyable FileType.mermaid
                    , title = "Mermaid"
                    }
                :: baseExportMenu browserStatus

        Route.EditFile Table _ ->
            MenuItem
                { e = Download <| Exporter.copyable FileType.markdown
                , title = "Markdown"
                }
                :: baseExportMenu browserStatus

        Route.EditFile SequenceDiagram _ ->
            MenuItem
                { e = Download <| Exporter.copyable FileType.mermaid
                , title = "Mermaid"
                }
                :: baseExportMenu browserStatus

        _ ->
            baseExportMenu browserStatus


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
