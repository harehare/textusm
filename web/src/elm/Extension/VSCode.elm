port module Extension.VSCode exposing (init, main, view)

import Browser
import Browser.Events exposing (onMouseUp, onResize)
import Components.Figure as Figure
import Html exposing (Html, div)
import Html.Attributes exposing (class, style)
import Html.Lazy exposing (lazy)
import Json.Decode as D
import Models.Figure as FigureModel
import Task



-- Model


type alias Model =
    { figureModel : FigureModel.Model
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
    }


type Msg
    = UpdateFigure FigureModel.Msg


init : InitData -> ( Model, Cmd Msg )
init flags =
    ( { figureModel =
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
            , figureType = FigureModel.UserStoryMap
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
    , Task.perform identity (Task.succeed (UpdateFigure (FigureModel.OnChangeText flags.text)))
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
            [ lazy Figure.view model.figureModel
                |> Html.map UpdateFigure
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
        UpdateFigure subMsg ->
            case subMsg of
                FigureModel.OnChangeText text ->
                    let
                        figureModel =
                            Figure.update subMsg model.figureModel
                    in
                    case figureModel.error of
                        Just err ->
                            ( { model | text = text, figureModel = figureModel }, errorLine err )

                        Nothing ->
                            ( { model | text = text, figureModel = figureModel }, errorLine "" )

                _ ->
                    ( { model | figureModel = Figure.update subMsg model.figureModel }, Cmd.none )



-- Subscription


port errorLine : String -> Cmd msg


port onTextChanged : (String -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ onResize (\width height -> UpdateFigure (FigureModel.OnResize width height))
        , onMouseUp (D.succeed (UpdateFigure FigureModel.Stop))
        , onTextChanged (\text -> UpdateFigure (FigureModel.OnChangeText text))
        ]
