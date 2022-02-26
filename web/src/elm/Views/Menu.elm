module Views.Menu exposing (MenuInfo, MenuItem(..), Props, menu, view)

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
import Css.Media as Media exposing (withMedia)
import Css.Transitions as Transitions
import Events
import Graphql.Enum.Diagram exposing (Diagram(..))
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Events
import Json.Decode as D
import List
import Maybe.Extra exposing (isNothing)
import Message exposing (Lang)
import Models.Color as Color
import Models.DiagramLocation as DiagramLocation
import Models.FileType as FileType
import Models.Model exposing (Menu(..), Msg(..))
import Models.Page as Page
import Models.Text as Text exposing (Text)
import Route exposing (Route)
import Settings exposing (Settings)
import Style.Color as Color
import Style.Font as FontStyle
import Style.Style as Style
import Style.Text as TextStyle
import Utils.Utils as Utils
import Views.Empty as Empty
import Views.Icon as Icon
import Models.ExportDiagram as ExportDiagram


type MenuItem msg
    = Item (MenuInfo msg)


type alias MenuInfo msg =
    { e : msg
    , title : String
    }


type alias Props =
    { page : Page.Page
    , route : Route
    , lang : Lang
    , text : Text
    , width : Int
    , openMenu : Maybe Menu
    , settings : Settings
    }


menuButtonStyle : Css.Style
menuButtonStyle =
    Css.batch
        [ cursor pointer
        , paddingTop <| px 16
        , marginBottom <| px 8
        , withMedia [ Media.all [ Media.maxWidth <| px 480 ] ]
            [ padding <| px 24 ]
        , hover
            [ position relative
            , descendants
                [ class "tooltip"
                    [ visibility visible
                    , opacity <| int 100
                    , Color.textColor
                    ]
                ]
            ]
        ]


view : Props -> Html Msg
view props =
    Html.nav
        [ css
            [ displayFlex
            , flexDirection row
            , alignItems center
            , justifyContent spaceBetween
            , Color.bgMain
            , Style.shadowSm
            , bottom zero
            , Style.widthScreen
            , position fixed
            , zIndex <| int 10
            , minWidth <| px 40
            , withMedia [ Media.all [ Media.minWidth <| px 1024 ] ]
                [ justifyContent start
                , Style.heightScreen
                , position relative
                , flexDirection column
                , Style.wMenu
                ]
            ]
        ]
        [ Html.a
            [ Attr.class "new-menu"
            , Attr.href <| Route.toString <| Route.New
            , Attr.attribute "aria-label" "New"
            ]
            [ Html.div
                [ css [ Style.mlXs, menuButtonStyle ]
                ]
                [ Icon.file Color.iconColor 18
                , Html.span [ Attr.class "tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipNewFile props.lang ] ]
                ]
            ]
        , Html.div
            [ css [ menuButtonStyle ] ]
            [ case props.settings.location of
                Just DiagramLocation.LocalFileSystem ->
                    Html.div
                        [ Events.onClickPreventDefaultOn OpenLocalFile
                        , Attr.attribute "aria-label" "List"
                        ]
                        [ Icon.folderOpen (Color.toString Color.iconColor) 18
                        , Html.span [ Attr.class "tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipOpenFile props.lang ] ]
                        ]

                _ ->
                    Html.a
                        [ Attr.href <| Route.toString Route.DiagramList
                        , Attr.attribute "aria-label" "List"
                        ]
                        [ Icon.folderOpen
                            (if isNothing props.openMenu && props.page == Page.List then
                                Color.toString Color.iconColor

                             else
                                Color.toString Color.disabledIconColor
                            )
                            18
                        , Html.span [ Attr.class "tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipOpenFile props.lang ] ]
                        ]
            ]
        , if Text.isChanged props.text then
            Html.div
                [ case props.settings.location of
                    Just DiagramLocation.LocalFileSystem ->
                        Events.onClick SaveLocalFile

                    _ ->
                        Events.onClick Save
                , css [ menuButtonStyle ]
                ]
                [ Icon.save (Color.toString Color.iconColor) 22
                , Html.span [ Attr.class "tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipSave props.lang ] ]
                ]

          else
            Html.div
                [ css [ menuButtonStyle ] ]
                [ Icon.save (Color.toString Color.disabledIconColor) 22
                , Html.span [ Attr.class "tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipSave props.lang ] ]
                ]
        , Html.div
            [ Events.stopPropagationOn "click" (D.succeed ( OpenMenu Export, True )), css [ menuButtonStyle ] ]
            [ Icon.download
                (case props.openMenu of
                    Just Export ->
                        Color.toString Color.iconColor

                    _ ->
                        Color.toString Color.disabledIconColor
                )
                18
            , Html.span [ Attr.class "tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipExport props.lang ] ]
            ]
        , Html.div
            [ css [ menuButtonStyle ] ]
            [ Html.a [ Attr.href <| Route.toString Route.Settings, Attr.attribute "aria-label" "Settings" ]
                [ Icon.settings
                    (if isNothing props.openMenu && props.page == Page.Settings then
                        Color.iconColor

                     else
                        Color.disabledIconColor
                    )
                    20
                , Html.span [ Attr.class "tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipSettings props.lang ] ]
                ]
            ]
        , if Utils.isPhone props.width then
            case props.openMenu of
                Just Export ->
                    menu Nothing (Just (props.width // 5 * 3)) (Just 50) Nothing (exportMenu props.route)

                _ ->
                    Empty.view

          else
            case props.openMenu of
                Just Export ->
                    menu (Just 125) (Just 40) Nothing Nothing (exportMenu props.route)

                _ ->
                    Empty.view
        ]


exportMenu : Route -> List (MenuItem Msg)
exportMenu route =
    case route of
        Route.Edit ErDiagram ->
            Item
                { e = Download <| ExportDiagram.copyable FileType.ddl
                , title = "DDL"
                }
                :: Item
                    { e = Download <| ExportDiagram.copyable FileType.mermaid
                    , title = "Mermaid"
                    }
                :: baseExportMenu

        Route.EditFile ErDiagram _ ->
            Item
                { e = Download <| ExportDiagram.copyable FileType.ddl
                , title = "DDL"
                }
                :: Item
                    { e = Download <| ExportDiagram.copyable FileType.mermaid
                    , title = "Mermaid"
                    }
                :: baseExportMenu

        Route.Edit SequenceDiagram ->
            Item
                { e = Download <| ExportDiagram.copyable FileType.mermaid
                , title = "Mermaid"
                }
                :: baseExportMenu

        Route.EditFile SequenceDiagram _ ->
            Item
                { e = Download <| ExportDiagram.copyable FileType.mermaid
                , title = "Mermaid"
                }
                :: baseExportMenu

        Route.Edit GanttChart ->
            Item
                { e = Download <| ExportDiagram.copyable FileType.mermaid
                , title = "Mermaid"
                }
                :: baseExportMenu

        Route.EditFile GanttChart _ ->
            Item
                { e = Download <| ExportDiagram.copyable FileType.mermaid
                , title = "Mermaid"
                }
                :: baseExportMenu

        Route.Edit Table ->
            Item
                { e = Download <| ExportDiagram.copyable FileType.markdown
                , title = "Markdown"
                }
                :: baseExportMenu

        Route.EditFile Table _ ->
            Item
                { e = Download <| ExportDiagram.copyable FileType.markdown
                , title = "Markdown"
                }
                :: baseExportMenu

        _ ->
            baseExportMenu


baseExportMenu : List (MenuItem Msg)
baseExportMenu =
    [ Item
        { e = Download <| ExportDiagram.downloadable FileType.svg
        , title = FileType.toString FileType.svg
        }
    , Item
        { e = Download <| ExportDiagram.downloadable FileType.png
        , title = FileType.toString FileType.png
        }
    , Item
        { e = Download <| ExportDiagram.downloadable FileType.pdf
        , title = FileType.toString FileType.pdf
        }
    , Item
        { e = Download <| ExportDiagram.downloadable FileType.plainText
        , title = FileType.toString FileType.plainText
        }
    , Item
        { e = Download <| ExportDiagram.downloadable FileType.html
        , title = FileType.toString FileType.html
        }
    ]


menu : Maybe Int -> Maybe Int -> Maybe Int -> Maybe Int -> List (MenuItem msg) -> Html msg
menu posTop posLeft posBottom posRight items =
    Html.div
        [ css
            [ Maybe.map (\p -> Css.batch [ top <| px <| toFloat <| p ]) posTop |> Maybe.withDefault (Css.batch [])
            , Maybe.map (\p -> Css.batch [ left <| px <| toFloat <| p ]) posLeft |> Maybe.withDefault (Css.batch [])
            , Maybe.map (\p -> Css.batch [ right <| px <| toFloat <| p ]) posRight |> Maybe.withDefault (Css.batch [])
            , Maybe.map (\p -> Css.batch [ bottom <| px <| toFloat <| p ]) posBottom |> Maybe.withDefault (Css.batch [])
            , minWidth <| px 120
            , maxHeight <| calc (vh 100) minus (px 40)
            , Transitions.transition [ Transitions.boxShadow3 200 200 Transitions.easeOut ]
            , Style.m1
            , overflow hidden
            , Color.bgMain
            , position absolute
            , Style.rounded
            , zIndex <| int 10
            , Style.shadowSm
            ]
        ]
        (items
            |> List.map
                (\item ->
                    case item of
                        Item menuItem ->
                            Html.div
                                [ css
                                    [ TextStyle.base
                                    , Color.textColor
                                    , cursor pointer
                                    , displayFlex
                                    , alignItems center
                                    , height <| px 40
                                    , hover
                                        [ backgroundColor <| rgba 0 0 0 0.3
                                        ]
                                    , withMedia [ Media.all [ Media.maxWidth <| px 480 ] ]
                                        [ height <| px 40 ]
                                    ]
                                , Events.onClick menuItem.e
                                ]
                                [ Html.div
                                    [ css
                                        [ cursor pointer
                                        , TextStyle.sm
                                        , FontStyle.fontBold
                                        , padding <| px 16
                                        , withMedia [ Media.all [ Media.maxWidth <| px 480 ] ]
                                            [ padding2 zero (px 16), Style.mt0 ]
                                        ]
                                    ]
                                    [ Html.text menuItem.title
                                    ]
                                ]
                )
        )
