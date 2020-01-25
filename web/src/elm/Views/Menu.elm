module Views.Menu exposing (menu, view)

import Html exposing (Html, div, img, nav, span, text)
import Html.Attributes exposing (alt, class, src, style)
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


type alias MenuItem =
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
                        menu Nothing (Just "10px") (Just "50px") Nothing newMenu

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
    [ { e = New Diagram.UserStoryMap
      , title = "User Story Map"
      , icon = Just <| img [ src "/images/user_story_map.svg", style "width" "56px", alt "logo" ] []
      }
    , { e = New Diagram.BusinessModelCanvas
      , title = "Business Model Canvas"
      , icon = Just <| img [ src "/images/business_model_canvas.svg", style "width" "56px", alt "logo" ] []
      }
    , { e = New Diagram.OpportunityCanvas
      , title = "Opportunity Canvas"
      , icon = Just <| img [ src "/images/opportunity_canvas.svg", style "width" "56px", alt "logo" ] []
      }
    , { e = New Diagram.UserPersona
      , title = "User Persona"
      , icon = Just <| img [ src "/images/user_persona.svg", style "width" "56px", alt "logo" ] []
      }
    , { e = New Diagram.Fourls
      , title = "4Ls Retrospective"
      , icon = Just <| img [ src "/images/4ls.svg", style "width" "56px", alt "logo" ] []
      }
    , { e = New Diagram.StartStopContinue
      , title = "Start, Stop, Continue Retrospective"
      , icon = Just <| img [ src "/images/start_stop_continue.svg", style "width" "56px", alt "logo" ] []
      }
    , { e = New Diagram.Kpt
      , title = "KPT Retrospective"
      , icon = Just <| img [ src "/images/kpt.svg", style "width" "56px", alt "logo" ] []
      }
    , { e = New Diagram.Markdown
      , title = "Markdown"
      , icon = Just <| img [ src "/images/markdown.svg", style "width" "56px", alt "logo" ] []
      }
    , { e = New Diagram.MindMap
      , title = "Mind Map"
      , icon = Just <| img [ src "/images/mind_map.svg", style "width" "56px", alt "logo" ] []
      }
    , { e = New Diagram.EmpathyMap
      , title = "Empathy Map"
      , icon = Just <| img [ src "/images/empathy_map.svg", style "width" "56px", alt "logo" ] []
      }
    , { e = New Diagram.CustomerJourneyMap
      , title = "Customer Journey Map"
      , icon = Just <| img [ src "/images/customer_journey_map.svg", style "width" "56px", alt "logo" ] []
      }
    , { e = New Diagram.SiteMap
      , title = "Site Map"
      , icon = Just <| img [ src "/images/site_map.svg", style "width" "56px", alt "logo" ] []
      }
    , { e = New Diagram.GanttChart
      , title = "Gantt Chart"
      , icon = Just <| img [ src "/images/gantt_chart.svg", style "width" "56px", alt "logo" ] []
      }
    ]


exportMenu : List MenuItem
exportMenu =
    [ { e = Download Svg
      , title = "SVG"
      , icon = Nothing
      }
    , { e = Download Png
      , title = "PNG"
      , icon = Nothing
      }
    , { e = Download Pdf
      , title = "PDF"
      , icon = Nothing
      }
    , { e = SaveToFileSystem
      , title = "Text"
      , icon = Nothing
      }
    , { e = Download HTML
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
                    div
                        [ class "menu-item-container"
                        , onClick item.e
                        ]
                        [ item.icon |> Maybe.withDefault (text "")
                        , div [ class "menu-item" ]
                            [ text item.title
                            ]
                        ]
                )
        )
