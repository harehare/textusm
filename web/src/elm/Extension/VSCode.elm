port module Extension.VSCode exposing (init, main, view)

import Browser
import Browser.Events exposing (onMouseUp, onResize)
import Components.Diagram as Diagram
import Html exposing (Html, div)
import Html.Attributes exposing (class, style)
import Html.Lazy exposing (lazy)
import Html5.DragDrop as DragDrop
import Json.Decode as D
import List.Extra exposing (getAt, setAt, takeWhile)
import Models.Diagram as DiagramModel
import Models.DiagramType as DiagramType
import Task
import Utils



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
    , lineColor : String
    , textColor : String
    , labelColor : String
    , diagramType : String
    }


type Msg
    = UpdateDiagram DiagramModel.Msg
    | GetCanvasSize String


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
            , selectedItem = Nothing
            , diagramType = DiagramType.fromString flags.diagramType
            , dragDrop = DragDrop.init
            , settings =
                { font = flags.fontName
                , size =
                    { width = 140
                    , height = 65
                    }
                , backgroundColor = flags.backgroundColor
                , zoomControl = Just True
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
                    , line = flags.lineColor
                    , label = flags.labelColor
                    , text = Just flags.textColor
                    }
                }
            , error = Nothing
            , touchDistance = Nothing
            , labels = []
            , text = Nothing
            , matchParent = False
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
        , style "width" "100%"
        , style "height" "100%"
        , style "overflow" "hidden"
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
                DiagramModel.EndEditSelectedItem item code isComposing ->
                    if code == 13 && not isComposing then
                        let
                            lines =
                                model.text
                                    |> String.lines

                            currentText =
                                getAt item.lineNo lines

                            prefix =
                                (currentText
                                    |> Maybe.withDefault ""
                                    |> String.toList
                                    |> takeWhile (\c -> c == ' ')
                                    |> List.length
                                    |> String.repeat
                                )
                                    " "

                            text =
                                setAt item.lineNo (prefix ++ String.trimLeft item.text) lines
                                    |> String.join "\n"
                        in
                        ( { model | text = text }
                        , Cmd.batch
                            [ Task.perform identity (Task.succeed (UpdateDiagram (DiagramModel.OnChangeText text)))
                            , Task.perform identity (Task.succeed (UpdateDiagram DiagramModel.DeselectItem))
                            , setText text
                            ]
                        )

                    else
                        ( model, Cmd.none )

                DiagramModel.MoveItem ( fromNo, toNo ) ->
                    let
                        lines =
                            model.text
                                |> String.lines

                        from =
                            getAt fromNo lines
                                |> Maybe.withDefault ""

                        fromPrefix =
                            Utils.getSpacePrefix from

                        to =
                            getAt toNo lines
                                |> Maybe.withDefault ""

                        toPrefix =
                            Utils.getSpacePrefix to

                        text =
                            lines
                                |> setAt fromNo (fromPrefix ++ String.trimLeft to)
                                |> setAt toNo (toPrefix ++ String.trimLeft from)
                                |> String.join "\n"
                    in
                    ( { model | text = text }
                    , Cmd.batch
                        [ Task.perform identity (Task.succeed (UpdateDiagram (DiagramModel.OnChangeText text)))
                        , Task.perform identity (Task.succeed (UpdateDiagram DiagramModel.DeselectItem))
                        , setText text
                        ]
                    )

                DiagramModel.OnChangeText text ->
                    let
                        ( model_, _ ) =
                            Diagram.update subMsg model.diagramModel
                    in
                    case model_.error of
                        Just err ->
                            ( { model | text = text, diagramModel = model_ }, errorLine err )

                        Nothing ->
                            ( { model | text = text, diagramModel = model_ }, errorLine "" )

                _ ->
                    let
                        ( model_, cmd_ ) =
                            Diagram.update subMsg model.diagramModel
                    in
                    ( { model | diagramModel = model_ }, cmd_ |> Cmd.map UpdateDiagram )

        GetCanvasSize diagramType ->
            let
                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    { diagramModel | diagramType = DiagramType.fromString diagramType }

                size =
                    Utils.getCanvasSize newDiagramModel
            in
            ( model, onGetCanvasSize size )



-- Subscription


port errorLine : String -> Cmd msg


port setText : String -> Cmd msg


port onGetCanvasSize : ( Int, Int ) -> Cmd msg


port onTextChanged : (String -> msg) -> Sub msg


port getCanvasSize : (String -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ onResize (\width height -> UpdateDiagram (DiagramModel.OnResize width height))
        , onMouseUp (D.succeed (UpdateDiagram DiagramModel.Stop))
        , onTextChanged (\text -> UpdateDiagram (DiagramModel.OnChangeText text))
        , getCanvasSize GetCanvasSize
        ]
