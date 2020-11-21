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
import Utils.Utils as Utils
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


selectedColor : String
selectedColor =
    "#F5F5F6"


notSelectedColor : String
notSelectedColor =
    "#848A90"


view : Props -> Html Msg
view props =
    let
        newMenuColor =
            if Text.isSaved props.text || isNothing props.openMenu && props.page == New then
                selectedColor

            else
                notSelectedColor
    in
    if props.fullscreen then
        Empty.view

    else
        nav
            [ class "flex flex-row items-center justify-start bg-main shadow-sm bottom-0 fixed lg:relative lg:flex-col lg:w-menu"
            , style "min-width" "56px"
            ]
            [ if Text.isChanged props.text then
                div
                    [ style "margin-left" "4px"
                    , class "menu-button"
                    ]
                    [ Icon.file newMenuColor 20
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
                        [ Icon.file newMenuColor 20
                        , span [ class "tooltip" ] [ span [ class "text" ] [ text <| Translations.toolTipNewFile props.lang ] ]
                        ]
                    ]
            , div
                [ class "menu-button list-button" ]
                [ a
                    [ href <| Route.toString Route.DiagramList
                    ]
                    [ Icon.folderOpen
                        (if isNothing props.openMenu && props.page == List then
                            selectedColor

                         else
                            notSelectedColor
                        )
                        20
                    , span [ class "tooltip" ] [ span [ class "text" ] [ text <| Translations.toolTipOpenFile props.lang ] ]
                    ]
                ]
            , div
                [ if Text.isChanged props.text then
                    onClick Save

                  else
                    style "" ""
                , class "menu-button save-button"
                ]
                [ Icon.save
                    (if Text.isChanged props.text then
                        selectedColor

                     else
                        notSelectedColor
                    )
                    26
                , span [ class "tooltip" ] [ span [ class "text" ] [ text <| Translations.toolTipSave props.lang ] ]
                ]
            , div
                [ stopPropagationOn "click" (D.succeed ( OpenMenu Export, True )), class "menu-button" ]
                [ Icon.download
                    (case props.openMenu of
                        Just Export ->
                            selectedColor

                        _ ->
                            notSelectedColor
                    )
                    22
                , span [ class "tooltip" ] [ span [ class "text" ] [ text <| Translations.toolTipExport props.lang ] ]
                ]
            , div
                [ class "menu-button" ]
                [ a [ href <| Route.toString Route.Settings ]
                    [ Icon.settings
                        (if isNothing props.openMenu && props.page == Settings then
                            selectedColor

                         else
                            notSelectedColor
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
                , title = "Markdown"
                }
                :: baseExportMenu

        Route.EditFile "table" _ ->
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
    div
        [ style "top" (top |> Maybe.withDefault "none")
        , style "left" (left |> Maybe.withDefault "none")
        , style "right" (right |> Maybe.withDefault "none")
        , style "bottom" (bottom |> Maybe.withDefault "none")
        , style "min-width" "120px"
        , style "position" "absolute"
        , style "z-index" "10"
        , style "max-height" "calc(100vh - 40px)"
        , style "background-color" "var(--main-color)"
        , style "border-radius" "8px"
        , style "box-shadow" "0 2px 4px -1px rgba(0, 0, 0, 0.2), 0 4px 5px 0 rgba(0, 0, 0, 0.14), 0 1px 10px 0 rgba(0, 0, 0, 0.12)"
        , style "transition" "all 0.2s ease-out"
        , style "margin" "4px"
        , style "overflow-y" "auto"
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
