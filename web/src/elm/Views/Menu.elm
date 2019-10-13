module Views.Menu exposing (menu, view)

import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick, stopPropagationOn)
import Json.Decode as D
import List
import Models.Diagram as DiagramModel
import Models.DiagramType as DiagramType
import Models.Item as Item
import Models.Model exposing (FileType(..), Menu(..), Msg(..))
import Route exposing (Route(..))
import Utils
import Views.Empty as Empty
import Views.Icon as Icon
import Views.Thumbnail as Thumbnail


type alias MenuItem =
    { e : Msg
    , icon : Maybe (Html DiagramModel.Msg)
    , title : String
    }


view : DiagramModel.Model -> Route -> Int -> Bool -> Maybe Menu -> Bool -> Bool -> Html Msg
view model route width fullscreen openMenu isOnline canWrite =
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
                                menu Nothing (Just "10px") (Just "50px") Nothing (newMenu model)

                            _ ->
                                Empty.view

                     else
                        case openMenu of
                            Just Export ->
                                menu (Just "125px") (Just "56px") Nothing Nothing exportMenu

                            Just NewFile ->
                                menu (Just "0") (Just "56px") Nothing Nothing (newMenu model)

                            _ ->
                                Empty.view
                   ]
            )


getThunbmailSize : DiagramModel.Model -> DiagramType.DiagramType -> ( String, String )
getThunbmailSize model diagramType =
    Utils.getCanvasSize { model | diagramType = diagramType }
        |> Tuple.mapFirst (\x -> String.fromInt x)
        |> Tuple.mapSecond (\x -> String.fromInt x)


newMenu : DiagramModel.Model -> List MenuItem
newMenu model =
    let
        newModel =
            { model | x = 0, y = 0, matchParent = True }
    in
    [ { e = New DiagramType.UserStoryMap
      , title = "User Story Map"
      , icon = Just <| Thumbnail.view newModel DiagramType.UserStoryMap (getThunbmailSize model DiagramType.UserStoryMap)
      }
    , { e = New DiagramType.BusinessModelCanvas
      , title = "Business Model Canvas"
      , icon = Just <| Thumbnail.view newModel DiagramType.BusinessModelCanvas (getThunbmailSize model DiagramType.BusinessModelCanvas)
      }
    , { e = New DiagramType.OpportunityCanvas
      , title = "Opportunity Canvas"
      , icon = Just <| Thumbnail.view newModel DiagramType.OpportunityCanvas (getThunbmailSize model DiagramType.OpportunityCanvas)
      }
    , { e = New DiagramType.UserPersona
      , title = "User Persona"
      , icon = Just <| Thumbnail.view newModel DiagramType.UserPersona (getThunbmailSize model DiagramType.UserPersona)
      }
    , { e = New DiagramType.FourLs
      , title = "4Ls Retrospective"
      , icon = Just <| Thumbnail.view newModel DiagramType.FourLs (getThunbmailSize model DiagramType.FourLs)
      }
    , { e = New DiagramType.StartStopContinue
      , title = "Start, Stop, Continue Retrospective"
      , icon = Just <| Thumbnail.view newModel DiagramType.StartStopContinue (getThunbmailSize model DiagramType.StartStopContinue)
      }
    , { e = New DiagramType.Kpt
      , title = "KPT Retrospective"
      , icon = Just <| Thumbnail.view newModel DiagramType.Kpt (getThunbmailSize model DiagramType.Kpt)
      }
    , { e = New DiagramType.Markdown
      , title = "Markdown"
      , icon = Just <| Thumbnail.view newModel DiagramType.Markdown (getThunbmailSize model DiagramType.Markdown)
      }
    , { e = New DiagramType.MindMap
      , title = "Mind Map"
      , icon = Just <| Thumbnail.view newModel DiagramType.MindMap (getThunbmailSize model DiagramType.MindMap)
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
                        [ item.icon |> Maybe.withDefault (text "") |> Html.map NoOpDiagram
                        , div [ class "menu-item" ]
                            [ text item.title
                            ]
                        ]
                )
        )
