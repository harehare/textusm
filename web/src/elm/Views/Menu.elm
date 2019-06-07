module Views.Menu exposing (view)

import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick, stopPropagationOn)
import Json.Decode as D
import List
import Models.Model exposing (Menu(..), Msg(..))
import Utils
import Views.Icon as Icon


view : Int -> Bool -> Bool -> Maybe Menu -> Html Msg
view width fullscreen isEditSettings openMenu =
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
                [ Icon.file 23
                , span [ class "tooltip" ] [ span [ class "text" ] [ text "New File" ] ]
                ]
             , div
                (onClick FileSelect :: menuItemStyle)
                [ Icon.folderOpen 23
                , span [ class "tooltip" ] [ span [ class "text" ] [ text "File Open" ] ]
                ]
             , div
                (stopPropagationOn "click" (D.succeed ( OpenMenu SaveFile, True )) :: menuItemStyle)
                [ Icon.save 26
                , span [ class "tooltip" ] [ span [ class "text" ] [ text "Save File" ] ]
                ]
             , div
                (stopPropagationOn "click" (D.succeed ( OpenMenu Export, True )) :: menuItemStyle)
                [ Icon.export 27 21
                , span [ class "tooltip" ] [ span [ class "text" ] [ text "Export" ] ]
                ]
             ]
                ++ [ if isEditSettings then
                        div
                            (onClick ToggleSettings :: style "margin-left" "4px" :: menuItemStyle)
                            [ Icon.file 23
                            , span [ class "tooltip" ] [ span [ class "text" ] [ text "Edit File" ] ]
                            ]

                     else
                        div
                            (onClick ToggleSettings :: menuItemStyle)
                            [ Icon.settings 25
                            , span [ class "tooltip" ] [ span [ class "text" ] [ text "Settings" ] ]
                            ]
                   , if Utils.isPhone width then
                        case openMenu of
                            Just SaveFile ->
                                menu Nothing (Just (String.fromInt (width // 5 * 2) ++ "px")) (Just "50px") [ ( DownloadSvg, "SVG" ), ( DownloadPng, "PNG" ), ( SaveToLocal, "TXT" ) ]

                            Just Export ->
                                menu Nothing (Just (String.fromInt (width // 5 * 3) ++ "px")) (Just "50px") [ ( GetAccessTokenForTrello, "Trello" ), ( ExportGithub, "Github" ) ]

                            Just NewFile ->
                                menu Nothing (Just "10px") (Just "50px") [ ( NewUserStoryMap, "User Story Map" ), ( NewBusinessModelCanvas, "Business Model Canvas" ) ]

                            _ ->
                                div [] []

                     else
                        case openMenu of
                            Just SaveFile ->
                                menu (Just "70px") Nothing Nothing [ ( DownloadSvg, "SVG" ), ( DownloadPng, "PNG" ), ( SaveToLocal, "TXT" ) ]

                            Just Export ->
                                menu (Just "125px") Nothing Nothing [ ( GetAccessTokenForTrello, "Trello" ), ( ExportGithub, "Github" ) ]

                            Just NewFile ->
                                menu (Just "0") Nothing Nothing [ ( NewUserStoryMap, "User Story Map" ), ( NewBusinessModelCanvas, "Business Model Canvas" ) ]

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
