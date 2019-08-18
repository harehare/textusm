module Views.Menu exposing (menu, view)

import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick, stopPropagationOn)
import Json.Decode as D
import List
import Models.Model exposing (Menu(..), Msg(..))
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
                    , span [ class "tooltip" ] [ span [ class "text" ] [ text "Current File" ] ]
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
                                menu Nothing (Just (String.fromInt (width // 5 * 3) ++ "px")) (Just "50px") Nothing (exportMenu route isOnline)

                            Just NewFile ->
                                menu Nothing (Just "10px") (Just "50px") Nothing newMenu

                            _ ->
                                Empty.view

                     else
                        case openMenu of
                            Just Export ->
                                menu (Just "125px") (Just "56px") Nothing Nothing (exportMenu route isOnline)

                            Just NewFile ->
                                menu (Just "0") (Just "56px") Nothing Nothing newMenu

                            _ ->
                                Empty.view
                   ]
            )


newMenu : List ( Msg, String )
newMenu =
    [ ( NewUserStoryMap, "User Story Map" )
    , ( NewBusinessModelCanvas, "Business Model Canvas" )
    , ( NewOpportunityCanvas, "Opportunity Canvas" )
    , ( NewCostBenfitAnalysis, "Cost-benfit analysis" )
    , ( NewUserPersona, "User Persona" )
    , ( NewFourLs, "4Ls Retrospective" )
    , ( NewStartStopContinue, "Start, Stop, Continue Retrospective" )
    , ( NewKpt, "KPT Retrospective" )
    , ( NewMarkdown, "Markdown" )
    ]


exportMenu : Route -> Bool -> List ( Msg, String )
exportMenu route isOnline =
    [ ( DownloadSvg, "SVG" )
    , ( DownloadPng, "PNG" )
    , ( DownloadPdf, "PDF" )
    , ( SaveToFileSystem, "Text" )
    ]
        ++ (if (route == Route.UserStoryMap || route == Route.Home) && isOnline then
                [ ( GetAccessTokenForTrello, "Trello" )
                , ( GetAccessTokenForGitHub, "Github" )
                ]

            else
                []
           )


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
