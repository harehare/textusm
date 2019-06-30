port module Extension.VSCode exposing (init, main, view)

import Browser
import Browser.Events exposing (onMouseUp, onResize)
import Components.Diagram as Diagram
import Html exposing (Html, div)
import Html.Attributes exposing (class, style)
import Html.Lazy exposing (lazy)
import Json.Decode as D
import Models.Diagram as DiagramModel
import Models.DiagramType as DiagramType
import Task



-- Model


type alias Model =
    { diagramModel : DiagramModel.Model
    , text : String
    , backgroundColor : String
    }


type alias InitData =
    { text : String
    , fontName : String
    , backgroundColor : String
    , activityBackgroundColor : String
    , activityColor : String
    , taskBackgroundColor : String
    , taskColor : String
    , storyBackgroundColor : String
    , storyColor : String
    , diagramType : String
    }


type Msg
    = UpdateDiagram DiagramModel.Msg


init : InitData -> ( Model, Cmd Msg )
init flags =
    ( { diagramModel =
            { items = []
            , hierarchy = 0
            , width = 1024
            , height = 1024
            , svg =
                { width = 140
                , height = 65
                , scale = 1.0
                }
            , countByHierarchy = []
            , countByTasks = []
            , moveStart = False
            , x = 0
            , y = 0
            , moveX = 0
            , moveY = 0
            , fullscreen = False
            , showZoomControl = True
            , diagramType =
                if flags.diagramType == "BusinessModelCanvas" then
                    DiagramType.BusinessModelCanvas

                else if flags.diagramType == "OpportunityCanvas" then
                    DiagramType.OpportunityCanvas

                else if flags.diagramType == "4Ls" then
                    DiagramType.FourLs

                else if flags.diagramType == "StartStopContinue" then
                    DiagramType.StartStopContinue

                else if flags.diagramType == "Kpt" then
                    DiagramType.Kpt

                else
                    DiagramType.UserStoryMap
            , settings =
                { font = flags.fontName
                , size =
                    { width = 140
                    , height = 65
                    }
                , backgroundColor = flags.backgroundColor
                , color =
                    { activity =
                        { color = flags.activityColor
                        , backgroundColor = flags.activityBackgroundColor
                        }
                    , task =
                        { color = flags.taskColor
                        , backgroundColor = flags.taskBackgroundColor
                        }
                    , story =
                        { color = flags.storyColor
                        , backgroundColor = flags.storyBackgroundColor
                        }
                    , comment =
                        { color = "#000000"
                        , backgroundColor = "#F1B090"
                        }
                    , line = "#434343"
                    , label = "#8C9FAE"
                    }
                }
            , error = Nothing
            , comment = Nothing
            , touchDistance = Nothing
            , labels = []
            }
      , text = flags.text
      , backgroundColor = flags.backgroundColor
      }
    , Task.perform identity (Task.succeed (UpdateDiagram (DiagramModel.OnChangeText flags.text)))
    )


view : Model -> Html Msg
view model =
    div
        [ style "position" "relative"
        , style "width" "100vw"
        , style "background-color" model.backgroundColor
        ]
        [ div
            [ class "main" ]
            [ lazy Diagram.view model.diagramModel
                |> Html.map UpdateDiagram
            ]
        ]


main : Program InitData Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        UpdateDiagram subMsg ->
            case subMsg of
                DiagramModel.OnChangeText text ->
                    let
                        diagramModel =
                            Diagram.update subMsg model.diagramModel
                    in
                    case diagramModel.error of
                        Just err ->
                            ( { model | text = text, diagramModel = diagramModel }, errorLine err )

                        Nothing ->
                            ( { model | text = text, diagramModel = diagramModel }, errorLine "" )

                _ ->
                    ( { model | diagramModel = Diagram.update subMsg model.diagramModel }, Cmd.none )



-- Subscription


port errorLine : String -> Cmd msg


port onTextChanged : (String -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ onResize (\width height -> UpdateDiagram (DiagramModel.OnResize width height))
        , onMouseUp (D.succeed (UpdateDiagram DiagramModel.Stop))
        , onTextChanged (\text -> UpdateDiagram (DiagramModel.OnChangeText text))
        ]
