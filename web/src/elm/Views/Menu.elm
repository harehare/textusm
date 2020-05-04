module Views.Menu exposing (MenuItem(..), menu, view)

import Data.Text as Text exposing (Text)
import Html exposing (Html, div, nav, span, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick, stopPropagationOn)
import Json.Decode as D
import List
import Maybe.Extra exposing (isNothing)
import Models.Model exposing (FileType(..), Menu(..), Msg(..), Page(..))
import Route exposing (Route)
import TextUSM.Enum.Diagram as Diagram exposing (Diagram(..))
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


view : Page -> Route -> Text -> Int -> Bool -> Maybe Menu -> Html Msg
view page route text_ width fullscreen openMenu =
    let
        menuItemStyle =
            [ class "menu-button"
            ]

        currentFileToolTip =
            span [ class "tooltip" ] [ span [ class "text" ] [ text "Current File" ] ]
    in
    if fullscreen then
        Empty.view

    else
        nav
            [ class "menu-bar"
            ]
            [ div
                ((case page of
                    List ->
                        onClick BackToEdit

                    Settings ->
                        onClick BackToEdit

                    Help ->
                        onClick BackToEdit

                    Share ->
                        onClick BackToEdit

                    Tags _ ->
                        onClick BackToEdit

                    _ ->
                        stopPropagationOn "click" (D.succeed ( OpenMenu NewFile, True ))
                 )
                    :: style "margin-left" "4px"
                    :: menuItemStyle
                )
                [ Icon.file
                    (case page of
                        Help ->
                            "#848A90"

                        Settings ->
                            "#848A90"

                        List ->
                            "#848A90"

                        Tags _ ->
                            "#848A90"

                        _ ->
                            "#F5F5F6"
                    )
                    20
                , case page of
                    List ->
                        currentFileToolTip

                    Settings ->
                        currentFileToolTip

                    Help ->
                        currentFileToolTip

                    Tags _ ->
                        currentFileToolTip

                    _ ->
                        span [ class "tooltip" ] [ span [ class "text" ] [ text "New File" ] ]
                ]
            , if page == List then
                Empty.view

              else
                div
                    (onClick FileSelect :: menuItemStyle)
                    [ Icon.folderOpen "#848A90" 20
                    , span [ class "tooltip" ] [ span [ class "text" ] [ text "Open File" ] ]
                    ]
            , div
                (onClick GetDiagrams :: class "list-button" :: menuItemStyle)
                [ Icon.viewComfy
                    (if isNothing openMenu && page == List then
                        "#F5F5F6"

                     else
                        "#848A90"
                    )
                    28
                , span [ class "tooltip" ] [ span [ class "text" ] [ text "Diagrams" ] ]
                ]
            , if page == List then
                Empty.view

              else
                div
                    ((if Text.isChanged text_ then
                        onClick Save

                      else
                        class ""
                     )
                        :: class "save-button"
                        :: menuItemStyle
                    )
                    [ Icon.save
                        (if Text.isChanged text_ then
                            "#F5F5F6"

                         else
                            "#848A90"
                        )
                        26
                    , span [ class "tooltip" ] [ span [ class "text" ] [ text "Save" ] ]
                    ]
            , case page of
                List ->
                    Empty.view

                Share ->
                    Empty.view

                Tags _ ->
                    Empty.view

                _ ->
                    div
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
                    (if isNothing openMenu && page == Settings then
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
                        menu Nothing (Just (String.fromInt (width // 5 * 3) ++ "px")) (Just "50px") Nothing (exportMenu route)

                    Just NewFile ->
                        menu Nothing (Just "10px") (Just "30px") Nothing newMenu

                    _ ->
                        Empty.view

              else
                case openMenu of
                    Just Export ->
                        menu (Just "125px") (Just "56px") Nothing Nothing (exportMenu route)

                    Just NewFile ->
                        menu (Just "0") (Just "56px") Nothing Nothing newMenu

                    _ ->
                        Empty.view
            ]


newMenu : List (MenuItem Msg)
newMenu =
    [ Item
        { e = New Diagram.UserStoryMap
        , title = "User Story Map"
        }
    , Item
        { e = New Diagram.CustomerJourneyMap
        , title = "Customer Journey Map"
        }
    , Item
        { e = New Diagram.EmpathyMap
        , title = "Empathy Map"
        }
    , Item
        { e = New Diagram.ImpactMap
        , title = "Impact Map"
        }
    , Item
        { e = New Diagram.MindMap
        , title = "Mind Map"
        }
    , Item
        { e = New Diagram.SiteMap
        , title = "Site Map"
        }
    , Separator
    , Item
        { e = New Diagram.BusinessModelCanvas
        , title = "Business Model Canvas"
        }
    , Item
        { e = New Diagram.OpportunityCanvas
        , title = "Opportunity Canvas"
        }
    , Item
        { e = New Diagram.UserPersona
        , title = "User Persona"
        }
    , Item
        { e = New Diagram.GanttChart
        , title = "Gantt Chart"
        }
    , Item
        { e = New Diagram.ErDiagram
        , title = "ER Diagram(beta)"
        }
    , Item
        { e = New Diagram.Kanban
        , title = "Kanban"
        }
    , Item
        { e = New Diagram.Markdown
        , title = "Markdown"
        }
    , Separator
    , Item
        { e = New Diagram.Kpt
        , title = "KPT Retrospective"
        }
    , Item
        { e = New Diagram.StartStopContinue
        , title = "Start, Stop, Continue Retrospective"
        }
    , Item
        { e = New Diagram.Fourls
        , title = "4Ls Retrospective"
        }
    ]


exportMenu : Route -> List (MenuItem Msg)
exportMenu route =
    case route of
        Route.Edit "erd" ->
            Item
                { e = Download DDL
                , title = "DDL"
                }
                :: baseExportMenu

        Route.EditFile "erd" _ ->
            Item
                { e = Download DDL
                , title = "DDL"
                }
                :: baseExportMenu

        Route.Edit "cjm" ->
            Item
                { e = Download MarkdownTable
                , title = "Markdown"
                }
                :: baseExportMenu

        Route.EditFile "cjm" _ ->
            Item
                { e = Download MarkdownTable
                , title = "MARKDOWN"
                }
                :: baseExportMenu

        _ ->
            baseExportMenu


baseExportMenu : List (MenuItem Msg)
baseExportMenu =
    [ Item
        { e = Download Svg
        , title = "SVG"
        }
    , Item
        { e = Download Png
        , title = "PNG"
        }
    , Item
        { e = Download Pdf
        , title = "PDF"
        }
    , Item
        { e = SaveToFileSystem
        , title = "TEXT"
        }
    , Item
        { e = Download HTML
        , title = "HTML"
        }
    ]


menu : Maybe String -> Maybe String -> Maybe String -> Maybe String -> List (MenuItem Msg) -> Html Msg
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
