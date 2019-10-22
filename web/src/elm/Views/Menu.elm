module Views.Menu exposing (menu, view)

import Html exposing (Html, div, img, span, text)
import Html.Attributes exposing (alt, class, src, style)
import Html.Events exposing (onClick, stopPropagationOn)
import Json.Decode as D
import List
import Models.DiagramType as DiagramType
import Models.Model exposing (FileType(..), Menu(..), Msg(..))
import Route exposing (Route(..))
import Utils
import Views.Empty as Empty
import Views.Icon as Icon


type alias MenuItem =
    { e : Msg
    , icon : Maybe (Html Msg)
    , title : String
    }


view : Route -> Int -> Bool -> Maybe Menu -> Bool -> Html Msg
view route width fullscreen openMenu canWrite =
    let
        menuItemStyle =
            [ class "menu-button"
            ]
    in
    if fullscreen then
        Empty.view

    else
        div
            [ class "menu-bar"
            ]
            ((if route == Route.List then
                div
                    (onClick MoveToBack :: menuItemStyle)
                    [ Icon.file 20
                    , span [ class "tooltip" ] [ span [ class "text" ] [ text "Current File" ] ]
                    ]

              else
                div
                    (stopPropagationOn "click" (D.succeed ( OpenMenu NewFile, True )) :: style "margin-left" "4px" :: menuItemStyle)
                    [ Icon.file 20
                    , span [ class "tooltip" ] [ span [ class "text" ] [ text "New File" ] ]
                    ]
             )
                :: (if route == Route.List then
                        [ div
                            (onClick FileSelect :: menuItemStyle)
                            [ Icon.folderOpen "#F5F5F6" 20
                            , span [ class "tooltip" ] [ span [ class "text" ] [ text "Open File" ] ]
                            ]
                        ]

                    else
                        [ div
                            (onClick GetDiagrams :: menuItemStyle)
                            [ Icon.folderOpen "#F5F5F6" 20
                            , span [ class "tooltip" ] [ span [ class "text" ] [ text "Files" ] ]
                            ]
                        , if canWrite then
                            div
                                (onClick Save :: menuItemStyle)
                                [ Icon.save 26
                                , span [ class "tooltip" ] [ span [ class "text" ] [ text "Save" ] ]
                                ]

                          else
                            Empty.view
                        , div
                            (stopPropagationOn "click" (D.succeed ( OpenMenu Export, True )) :: menuItemStyle)
                            [ Icon.download 22
                            , span [ class "tooltip" ] [ span [ class "text" ] [ text "Export" ] ]
                            ]
                        ]
                   )
                ++ [ div
                        (onClick EditSettings :: menuItemStyle)
                        [ Icon.settings
                            "#F5F5F6"
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
            )


newMenu : List MenuItem
newMenu =
    [ { e = New DiagramType.UserStoryMap
      , title = "User Story Map"
      , icon = Just <| img [ src "/images/user_story_map.svg", style "width" "56px", alt "logo" ] []
      }
    , { e = New DiagramType.BusinessModelCanvas
      , title = "Business Model Canvas"
      , icon = Just <| img [ src "/images/business_model_canvas.svg", style "width" "56px", alt "logo" ] []
      }
    , { e = New DiagramType.OpportunityCanvas
      , title = "Opportunity Canvas"
      , icon = Just <| img [ src "/images/opportunity_canvas.svg", style "width" "56px", alt "logo" ] []
      }
    , { e = New DiagramType.UserPersona
      , title = "User Persona"
      , icon = Just <| img [ src "/images/user_persona.svg", style "width" "56px", alt "logo" ] []
      }
    , { e = New DiagramType.FourLs
      , title = "4Ls Retrospective"
      , icon = Just <| img [ src "/images/4ls.svg", style "width" "56px", alt "logo" ] []
      }
    , { e = New DiagramType.StartStopContinue
      , title = "Start, Stop, Continue Retrospective"
      , icon = Just <| img [ src "/images/start_stop_continue.svg", style "width" "56px", alt "logo" ] []
      }
    , { e = New DiagramType.Kpt
      , title = "KPT Retrospective"
      , icon = Just <| img [ src "/images/kpt.svg", style "width" "56px", alt "logo" ] []
      }
    , { e = New DiagramType.Markdown
      , title = "Markdown"
      , icon = Just <| img [ src "/images/markdown.svg", style "width" "56px", alt "logo" ] []
      }
    , { e = New DiagramType.MindMap
      , title = "Mind Map"
      , icon = Just <| img [ src "/images/mind_map.svg", style "width" "56px", alt "logo" ] []
      }
    , { e = New DiagramType.EmpathyMap
      , title = "Empathy Map"
      , icon = Just <| img [ src "/images/empathy_map.svg", style "width" "56px", alt "logo" ] []
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
