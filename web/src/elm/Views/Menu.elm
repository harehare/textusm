module Views.Menu exposing (MenuItem(..), menu, view)

import Graphql.Enum.Diagram exposing (Diagram(..))
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode as D
import List
import Maybe.Extra exposing (isNothing)
import Message exposing (Lang)
import Models.Color as Color
import Models.FileType as FileType
import Models.Model exposing (Menu(..), Msg(..))
import Models.Page as Page
import Models.Text as Text exposing (Text)
import Route exposing (Route)
import Utils.Utils as Utils
import Views.Empty as Empty
import Views.Icon as Icon


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
    , fullscreen : Bool
    , openMenu : Maybe Menu
    }


view : Props -> Html Msg
view props =
    let
        isReadOnly =
            case props.route of
                Route.ViewFile _ _ ->
                    True

                _ ->
                    False
    in
    if isReadOnly || props.fullscreen then
        Empty.view

    else
        Html.nav
            [ Attr.class "flex"
            , Attr.class "flex-row"
            , Attr.class "items-center"
            , Attr.class "justify-between"
            , Attr.class "bg-main"
            , Attr.class "shadow-sm"
            , Attr.class "bottom-0"
            , Attr.class "w-screen"
            , Attr.class "fixed"
            , Attr.class "lg:justify-start"
            , Attr.class "lg:h-screen"
            , Attr.class "lg:relative"
            , Attr.class "lg:flex-col"
            , Attr.class "lg:w-menu"
            , Attr.class "z-10"
            , Attr.style "min-width" "40px"
            ]
            [ Html.a
                [ Attr.href <| Route.toString <| Route.New
                , Attr.attribute "aria-label" "New"
                ]
                [ Html.div
                    [ Attr.class "ml-xs"
                    , Attr.class "menu-button"
                    ]
                    [ Icon.file (Color.toString Color.iconColor) 18
                    , Html.span [ Attr.class "tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipNewFile props.lang ] ]
                    ]
                ]
            , Html.div
                [ Attr.class "menu-button list-button" ]
                [ Html.a
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
            , let
                canSave =
                    Text.isChanged props.text
              in
              Html.div
                [ if canSave then
                    Events.onClick Save

                  else
                    Attr.style "" ""
                , Attr.class "menu-button save-button"
                ]
                [ Icon.save
                    (if canSave then
                        Color.toString Color.iconColor

                     else
                        Color.toString Color.disabledIconColor
                    )
                    22
                , Html.span [ Attr.class "tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipSave props.lang ] ]
                ]
            , Html.div
                [ Events.stopPropagationOn "click" (D.succeed ( OpenMenu Export, True )), Attr.class "menu-button" ]
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
                [ Attr.class "menu-button" ]
                [ Html.a [ Attr.href <| Route.toString Route.Settings, Attr.attribute "aria-label" "Settings" ]
                    [ Icon.settings
                        (if isNothing props.openMenu && props.page == Page.Settings then
                            Color.toString Color.iconColor

                         else
                            Color.toString Color.disabledIconColor
                        )
                        20
                    , Html.span [ Attr.class "tooltip" ] [ Html.span [ Attr.class "text" ] [ Html.text <| Message.toolTipSettings props.lang ] ]
                    ]
                ]
            , if Utils.isPhone props.width then
                case props.openMenu of
                    Just Export ->
                        menu Nothing (Just (String.fromInt (props.width // 5 * 3) ++ "px")) (Just "50px") Nothing (exportMenu props.route)

                    _ ->
                        Empty.view

              else
                case props.openMenu of
                    Just Export ->
                        menu (Just "125px") (Just "40px") Nothing Nothing (exportMenu props.route)

                    _ ->
                        Empty.view
            ]


exportMenu : Route -> List (MenuItem Msg)
exportMenu route =
    case route of
        Route.Edit ErDiagram ->
            Item
                { e = Download <| FileType.ddl
                , title = "DDL"
                }
                :: baseExportMenu

        Route.EditFile ErDiagram _ ->
            Item
                { e = Download <| FileType.ddl
                , title = "DDL"
                }
                :: baseExportMenu

        Route.Edit Table ->
            Item
                { e = Download <| FileType.markdown
                , title = "Markdown"
                }
                :: baseExportMenu

        Route.EditFile Table _ ->
            Item
                { e = Download <| FileType.markdown
                , title = "Markdown"
                }
                :: baseExportMenu

        _ ->
            baseExportMenu


baseExportMenu : List (MenuItem Msg)
baseExportMenu =
    [ Item
        { e = Download <| FileType.svg
        , title = FileType.toString FileType.svg
        }
    , Item
        { e = Download <| FileType.png
        , title = FileType.toString FileType.png
        }
    , Item
        { e = Download <| FileType.pdf
        , title = FileType.toString FileType.pdf
        }
    , Item
        { e = Download <| FileType.plainText
        , title = FileType.toString FileType.plainText
        }
    , Item
        { e = Download <| FileType.html
        , title = FileType.toString FileType.html
        }
    ]


menu : Maybe String -> Maybe String -> Maybe String -> Maybe String -> List (MenuItem msg) -> Html msg
menu top left bottom right items =
    Html.div
        [ Attr.style "top" (top |> Maybe.withDefault "none")
        , Attr.style "left" (left |> Maybe.withDefault "none")
        , Attr.style "right" (right |> Maybe.withDefault "none")
        , Attr.style "bottom" (bottom |> Maybe.withDefault "none")
        , Attr.style "min-width" "120px"
        , Attr.style "max-height" "calc(100vh - 40px)"
        , Attr.style "transition" "all 0.2s ease-out"
        , Attr.class "m-1"
        , Attr.class "overflow-hidden"
        , Attr.class "bg-main"
        , Attr.class "absolute"
        , Attr.class "rounded"
        , Attr.class "z-10"
        , Attr.class "shadow-md"
        ]
        (items
            |> List.map
                (\item ->
                    case item of
                        Item menuItem ->
                            Html.div
                                [ Attr.class "menu-item-container"
                                , Events.onClick menuItem.e
                                ]
                                [ Html.div [ Attr.class "menu-item" ]
                                    [ Html.text menuItem.title
                                    ]
                                ]
                )
        )
