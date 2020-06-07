module Views.Menu exposing (MenuItem(..), menu, view)

import Data.FileType as FileType
import Data.Text as Text exposing (Text)
import Html exposing (Html, a, div, nav, span, text)
import Html.Attributes exposing (class, href, style)
import Html.Events exposing (onClick, stopPropagationOn)
import Json.Decode as D
import List
import Maybe.Extra exposing (isNothing)
import Models.Model exposing (Menu(..), Msg(..), Page(..))
import Route exposing (Route)
import Translations exposing (Lang)
import Utils
import Views.Empty as Empty
import Views.Icon as Icon


type MenuItem msg
    = Item (MenuInfo msg)
    | Separator


type alias MenuInfo msg =
    { e : msg
    , title : String
    }


type alias Props =
    { page : Page
    , route : Route
    , lang : Lang
    , text : Text
    , width : Int
    , fullscreen : Bool
    , openMenu : Maybe Menu
    }


view : Props -> Html Msg
view props =
    if props.fullscreen then
        Empty.view

    else
        nav
            [ class "menu-bar"
            ]
            [ if Text.isChanged props.text then
                div
                    [ style "margin-left" "4px"
                    , class "menu-button"
                    ]
                    [ Icon.file "#848A90" 20
                    , span [ class "tooltip" ] [ span [ class "text" ] [ text "New File" ] ]
                    ]

              else
                a
                    [ href <| Route.toString <| Route.New
                    ]
                    [ div
                        [ style "margin-left" "4px"
                        , class "menu-button"
                        ]
                        [ Icon.file "#F5F5F6" 20
                        , span [ class "tooltip" ] [ span [ class "text" ] [ text <| Translations.toolTipNewFile props.lang ] ]
                        ]
                    ]
            , div
                [ class "menu-button list-button" ]
                [ a
                    [ href <| Route.toString Route.List
                    ]
                    [ Icon.folderOpen
                        (if isNothing props.openMenu && props.page == List then
                            "#F5F5F6"

                         else
                            "#848A90"
                        )
                        20
                    , span [ class "tooltip" ] [ span [ class "text" ] [ text <| Translations.toolTipOpenFile props.lang ] ]
                    ]
                ]
            , if props.page == List then
                Empty.view

              else
                div
                    [ if Text.isChanged props.text then
                        onClick Save

                      else
                        style "" ""
                    , class "menu-button save-button"
                    ]
                    [ Icon.save
                        (if Text.isChanged props.text then
                            "#F5F5F6"

                         else
                            "#848A90"
                        )
                        26
                    , span [ class "tooltip" ] [ span [ class "text" ] [ text <| Translations.toolTipSave props.lang ] ]
                    ]
            , case props.page of
                List ->
                    Empty.view

                Share ->
                    Empty.view

                Tags _ ->
                    Empty.view

                _ ->
                    div
                        [ stopPropagationOn "click" (D.succeed ( OpenMenu Export, True )), class "menu-button" ]
                        [ Icon.download
                            (case props.openMenu of
                                Just Export ->
                                    "#F5F5F6"

                                _ ->
                                    "#848A90"
                            )
                            22
                        , span [ class "tooltip" ] [ span [ class "text" ] [ text <| Translations.toolTipExport props.lang ] ]
                        ]
            , div
                [ class "menu-button" ]
                [ a [ href <| Route.toString Route.Settings ]
                    [ Icon.settings
                        (if isNothing props.openMenu && props.page == Settings then
                            "#F5F5F6"

                         else
                            "#848A90"
                        )
                        25
                    , span [ class "tooltip" ] [ span [ class "text" ] [ text <| Translations.toolTipSettings props.lang ] ]
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
                        menu (Just "125px") (Just "56px") Nothing Nothing (exportMenu props.route)

                    _ ->
                        Empty.view
            ]


exportMenu : Route -> List (MenuItem Msg)
exportMenu route =
    case route of
        Route.Edit "erd" ->
            Item
                { e = Download <| FileType.ddl
                , title = "DDL"
                }
                :: baseExportMenu

        Route.EditFile "erd" _ ->
            Item
                { e = Download <| FileType.ddl
                , title = "DDL"
                }
                :: baseExportMenu

        Route.Edit "table" ->
            Item
                { e = Download <| FileType.markdown
                , title = "MARKDOWN"
                }
                :: baseExportMenu

        Route.EditFile "cjm" _ ->
            Item
                { e = Download <| FileType.markdown
                , title = "MARKDOWN"
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
    div
        [ style "top" (top |> Maybe.withDefault "none")
        , style "left" (left |> Maybe.withDefault "none")
        , style "right" (right |> Maybe.withDefault "none")
        , style "bottom" (bottom |> Maybe.withDefault "none")
        , class "menu"
        ]
        (items
            |> List.map
                (\item ->
                    case item of
                        Item menuItem ->
                            div
                                [ class "menu-item-container"
                                , onClick menuItem.e
                                ]
                                [ div [ class "menu-item" ]
                                    [ text menuItem.title
                                    ]
                                ]

                        Separator ->
                            div
                                [ style "width" "100%"
                                , style "height" "2px"
                                , style "border-bottom" "2px solid rgba(0, 0, 0, 0.1)"
                                ]
                                []
                )
        )
