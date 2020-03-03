module Views.Menu exposing (MenuItem(..), menu, view)

import Html exposing (Html, div, nav, span, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick, stopPropagationOn)
import Json.Decode as D
import List
import Maybe.Extra exposing (isNothing)
import Models.Model exposing (FileType(..), Menu(..), Msg(..))
import Route exposing (Route(..))
import TextUSM.Enum.Diagram as Diagram
import Utils
import Views.Empty as Empty
import Views.Icon as Icon


type MenuItem
    = Item MenuInfo
    | Separator


type alias MenuInfo =
    { e : Msg
    , icon : Maybe (Html Msg)
    , title : String
    }


view : Route -> Int -> Bool -> Maybe Menu -> Html Msg
view route width fullscreen openMenu =
    let
        menuItemStyle =
            [ class "menu-button"
            ]
    in
    if fullscreen then
        Empty.view

    else
        nav
            [ class "menu-bar"
            ]
            [ div
                (stopPropagationOn "click" (D.succeed ( OpenMenu NewFile, True )) :: style "margin-left" "4px" :: menuItemStyle)
                [ Icon.file
                    (case openMenu of
                        Just NewFile ->
                            "#F5F5F6"

                        _ ->
                            "#848A90"
                    )
                    20
                , span [ class "tooltip" ] [ span [ class "text" ] [ text "New File" ] ]
                ]
            , div
                (onClick FileSelect :: menuItemStyle)
                [ Icon.folderOpen "#848A90" 20
                , span [ class "tooltip" ] [ span [ class "text" ] [ text "Open File" ] ]
                ]
            , div
                (onClick GetDiagrams :: class "list-button" :: menuItemStyle)
                [ Icon.viewComfy
                    (if isNothing openMenu && route == List then
                        "#F5F5F6"

                     else
                        "#848A90"
                    )
                    28
                , span [ class "tooltip" ] [ span [ class "text" ] [ text "Diagrams" ] ]
                ]
            , div
                (onClick Save :: class "save-button" :: menuItemStyle)
                [ Icon.save
                    "#848A90"
                    26
                , span [ class "tooltip" ] [ span [ class "text" ] [ text "Save" ] ]
                ]
            , div
                (stopPropagationOn "click" (D.succeed ( OpenMenu Export, True )) :: menuItemStyle)
                [ Icon.download
                    (case openMenu of
                        Just Export ->
                            "#F5F5F6"

                        _ ->
                            "#848A90"
                    )
                    22
                , span [ class "tooltip" ] [ span [ class "text" ] [ text "Export" ] ]
                ]
            , div
                (onClick (NavRoute Route.Settings) :: menuItemStyle)
                [ Icon.settings
                    (if isNothing openMenu && route == Settings then
                        "#F5F5F6"

                     else
                        "#848A90"
                    )
                    25
                , span [ class "tooltip" ] [ span [ class "text" ] [ text "Settings" ] ]
                ]
            , if Utils.isPhone width then
                case openMenu of
                    Just Export ->
                        menu Nothing (Just (String.fromInt (width // 5 * 3) ++ "px")) (Just "50px") Nothing exportMenu

                    Just NewFile ->
                        menu Nothing (Just "10px") (Just "30px") Nothing newMenu

                    _ ->
                        Empty.view

              else
                case openMenu of
                    Just Export ->
                        menu (Just "125px") (Just "56px") Nothing Nothing exportMenu

                    Just NewFile ->
                        menu (Just "0") (Just "56px") Nothing Nothing newMenu

                    _ ->
                        Empty.view
            ]


newMenu : List MenuItem
newMenu =
    [ Item
        { e = New Diagram.UserStoryMap
        , title = "User Story Map"
        , icon = Nothing
        }
    , Item
        { e = New Diagram.CustomerJourneyMap
        , title = "Customer Journey Map"
        , icon = Nothing
        }
    , Item
        { e = New Diagram.EmpathyMap
        , title = "Empathy Map"
        , icon = Nothing
        }
    , Item
        { e = New Diagram.ImpactMap
        , title = "Impact Map"
        , icon = Nothing
        }
    , Item
        { e = New Diagram.MindMap
        , title = "Mind Map"
        , icon = Nothing
        }
    , Item
        { e = New Diagram.SiteMap
        , title = "Site Map"
        , icon = Nothing
        }
    , Separator
    , Item
        { e = New Diagram.BusinessModelCanvas
        , title = "Business Model Canvas"
        , icon = Nothing
        }
    , Item
        { e = New Diagram.OpportunityCanvas
        , title = "Opportunity Canvas"
        , icon = Nothing
        }
    , Item
        { e = New Diagram.UserPersona
        , title = "User Persona"
        , icon = Nothing
        }
    , Item
        { e = New Diagram.GanttChart
        , title = "Gantt Chart"
        , icon = Nothing
        }
    , Item
        { e = New Diagram.Markdown
        , title = "Markdown"
        , icon = Nothing
        }
    , Separator
    , Item
        { e = New Diagram.Kpt
        , title = "KPT Retrospective"
        , icon = Nothing
        }
    , Item
        { e = New Diagram.StartStopContinue
        , title = "Start, Stop, Continue Retrospective"
        , icon = Nothing
        }
    , Item
        { e = New Diagram.Fourls
        , title = "4Ls Retrospective"
        , icon = Nothing
        }
    ]


exportMenu : List MenuItem
exportMenu =
    [ Item
        { e = Download Svg
        , title = "SVG"
        , icon = Nothing
        }
    , Item
        { e = Download Png
        , title = "PNG"
        , icon = Nothing
        }
    , Item
        { e = Download Pdf
        , title = "PDF"
        , icon = Nothing
        }
    , Item
        { e = SaveToFileSystem
        , title = "Text"
        , icon = Nothing
        }
    , Item
        { e = Download HTML
        , title = "HTML"
        , icon = Nothing
        }
    ]


menu : Maybe String -> Maybe String -> Maybe String -> Maybe String -> List MenuItem -> Html Msg
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
                                [ menuItem.icon |> Maybe.withDefault (text "")
                                , div [ class "menu-item" ]
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
