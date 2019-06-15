module Views.Menu exposing (view)

import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick, stopPropagationOn)
import Json.Decode as D
import List
import Models.Model exposing (Menu(..), Msg(..))
import Route exposing (Route(..))
import Utils
import Views.Icon as Icon


view : Route -> Int -> Bool -> Maybe Menu -> Html Msg
view route width fullscreen openMenu =
    let
        menuItemStyle =
            [ class "menu-button"
            ]
    in
    if fullscreen then
        div [] []

    else
        div
            [ class "menu-bar"
            ]
            ([ div
                ([ stopPropagationOn "click" (D.succeed ( OpenMenu NewFile, True )), style "margin-left" "4px" ] ++ menuItemStyle)
                [ Icon.file 20
                , span [ class "tooltip" ] [ span [ class "text" ] [ text "Current File" ] ]
                ]
             ]
                ++ (if route == Route.List then
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
                        , div
                            (onClick SaveToLocal :: menuItemStyle)
                            [ Icon.save 26
                            , span [ class "tooltip" ] [ span [ class "text" ] [ text "Save" ] ]
                            ]
                        , div
                            (stopPropagationOn "click" (D.succeed ( OpenMenu Export, True )) :: menuItemStyle)
                            [ Icon.export 27 21
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
                                menu Nothing (Just (String.fromInt (width // 5 * 3) ++ "px")) (Just "50px") [ ( DownloadSvg, "SVG" ), ( DownloadPng, "PNG" ), ( SaveToFileSystem, "Text" ), ( GetAccessTokenForTrello, "Trello" ), ( ExportGithub, "Github" ) ]

                            Just NewFile ->
                                menu Nothing (Just "10px") (Just "50px") [ ( NewUserStoryMap, "User Story Map" ), ( NewBusinessModelCanvas, "Business Model Canvas" ), ( NewOpportunityCanvas, "Opportunity Canvas" ) ]

                            _ ->
                                div [] []

                     else
                        case openMenu of
                            Just Export ->
                                menu (Just "125px") Nothing Nothing [ ( DownloadSvg, "SVG" ), ( DownloadPng, "PNG" ), ( SaveToFileSystem, "Text" ), ( GetAccessTokenForTrello, "Trello" ), ( ExportGithub, "Github" ) ]

                            Just NewFile ->
                                menu (Just "0") Nothing Nothing [ ( NewUserStoryMap, "User Story Map" ), ( NewBusinessModelCanvas, "Business Model Canvas" ), ( NewOpportunityCanvas, "Opportunity Canvas" ) ]

                            _ ->
                                div [] []
                   ]
            )


menu : Maybe String -> Maybe String -> Maybe String -> List ( Msg, String ) -> Html Msg
menu top left bottom items =
    div
        [ style "top" (top |> Maybe.withDefault "none")
        , style "left" (left |> Maybe.withDefault "56px")
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
