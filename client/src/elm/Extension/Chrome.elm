module Extension.Chrome exposing (init, main, view)

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
    }


type Msg
    = UpdateFigure FigureModel.Msg


init : String -> ( Model, Cmd Msg )
init flags =
    ( { figureModel =
            { items = []
            , hierarchy = 0
            , width = 1024
            , height = 360
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
            , settings =
                { font = "apple-system, BlinkMacSystemFont, Helvetica Neue, Hiragino Kaku Gothic ProN, 游ゴシック Medium, YuGothic, YuGothicM, メイリオ, Meiryo, sans-serif"
                , size =
                    { width = 140
                    , height = 65
                    }
                , backgroundColor = "#F5F5F6"
                , color =
                    { activity =
                        { color = "#FFFFFF"
                        , backgroundColor = "#266B9A"
                        }
                    , task =
                        { color = "#FFFFFF"
                        , backgroundColor = "#3E9BCD"
                        }
                    , story =
                        { color = "#000000"
                        , backgroundColor = "#FFFFFF"
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
            }
      , text = flags
      }
    , Task.perform identity (Task.succeed (UpdateFigure (FigureModel.OnChangeText flags)))
    )


view : Model -> Html Msg
view model =
    div
        [ style "position" "relative"
        , style "width" "100%"
        , style "height" "360px"
        , style "background-color" "#F5F5F6"
        , style "margin" "16px 0"
        , style "overflow" "hidden"
        ]
        [ div
            [ class "main" ]
            [ lazy Figure.view model.figureModel
                |> Html.map UpdateFigure
            ]
        ]


main : Program String Model Msg
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
            ( { model | figureModel = Figure.update subMsg model.figureModel }, Cmd.none )



-- Subscription


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ onResize (\width height -> UpdateFigure (FigureModel.OnResize width height))
        , onMouseUp (D.succeed (UpdateFigure FigureModel.Stop))
        ]
