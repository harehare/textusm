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
            ((if Utils.isPhone width then
                [ div
                    (onClick FileSelect :: menuItemStyle)
                    [ Icon.folderOpen 24
                    , span [ class "tooltip" ] [ span [ class "text" ] [ text "File Open" ] ]
                    ]
                , div
                    (onClick DownloadSvg :: menuItemStyle)
                    [ Icon.download 24
                    , span [ class "tooltip" ] [ span [ class "text" ] [ text "Export" ] ]
                    ]
                ]

              else
                [ div
                    (stopPropagationOn "click" (D.succeed ( OpenMenu OpenFile, True )) :: menuItemStyle)
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
             )
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
                   , case openMenu of
                        Just SaveFile ->
                            menu "35px" [ ( DownloadSvg, "SVG" ), ( DownloadPng, "PNG" ), ( SaveToLocal, "TXT" ) ]

                        Just OpenFile ->
                            menu "0" [ ( FileSelect, "LOCAL" ), ( NoOp, "REMOTE (IN DEVELOPMENT)" ) ]

                        Just Export ->
                            menu "85px" [ ( GetAccessTokenForTrello, "Trello" ), ( NoOp, "Asana (IN DEVELOPMENT)" ) ]

                        _ ->
                            div [] []
                   ]
            )


menu : String -> List ( Msg, String ) -> Html Msg
menu top items =
    div
        [ style "min-width" "80px"
        , style "position" "absolute"
        , style "z-index" "10"
        , style "height" "auto"
        , style "top" top
        , style "left" "56px"
        , style "background-color" "#F5F5F6"
        , style "box-shadow" "0 2px 4px -1px rgba(0,0,0,.2), 0 4px 5px 0 rgba(0,0,0,.14), 0 1px 10px 0 rgba(0,0,0,.12)"
        , class "menu"
        , style "transition" "all 0.2s ease-out"
        ]
        (items
            |> List.map
                (\( m, t ) ->
                    div
                        [ style "font-size" "0.8rem"
                        , style "color" "#4a4a4a"
                        , style "cursor" "pointer"
                        , style "padding" "0 20px"
                        , style "height" "35px"
                        , style "display" "flex"
                        , style "align-items" "center"
                        , style "border-bottom" "solid 0.5px #cfcdcd"
                        , onClick m
                        ]
                        [ div [ class "menu-item" ]
                            [ text t
                            ]
                        ]
                )
        )
