module Views.Menu exposing (menu, view)

import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick, stopPropagationOn)
import Json.Decode as D
import List
import Models.DiagramType as DiagramType
import Models.Model exposing (FileType(..), Menu(..), Msg(..))
import Route exposing (Route(..))
import Utils
import Views.Empty as Empty
import Views.Icon as Icon


view : Route -> Int -> Bool -> Maybe Menu -> Bool -> Bool -> Html Msg
view route width fullscreen openMenu isOnline canWrite =
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


newMenu : List ( Msg, String )
newMenu =
    [ ( New DiagramType.UserStoryMap, "User Story Map" )
    , ( New DiagramType.BusinessModelCanvas, "Business Model Canvas" )
    , ( New DiagramType.OpportunityCanvas, "Opportunity Canvas" )
    , ( New DiagramType.UserPersona, "User Persona" )
    , ( New DiagramType.FourLs, "4Ls Retrospective" )
    , ( New DiagramType.StartStopContinue, "Start, Stop, Continue Retrospective" )
    , ( New DiagramType.Kpt, "KPT Retrospective" )
    , ( New DiagramType.Markdown, "Markdown" )
    , ( New DiagramType.MindMap, "Mind Map" )
    ]


exportMenu : List ( Msg, String )
exportMenu =
    [ ( Download Svg, "SVG" )
    , ( Download Png, "PNG" )
    , ( Download Pdf, "PDF" )
    , ( SaveToFileSystem, "Text" )
    ]


menu : Maybe String -> Maybe String -> Maybe String -> Maybe String -> List ( Msg, String ) -> Html Msg
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
                (\( m, t ) ->
                    div
                        [ class "menu-item-container"
                        , onClick m
                        ]
                        [ div [ class "menu-item" ]
                            [ text t
                            ]
                        ]
                )
        )
