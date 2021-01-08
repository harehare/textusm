port module Extension.VSCode exposing (init, main, view)

import Browser
import Browser.Events exposing (onMouseUp, onResize)
import Components.Diagram as Diagram
import Data.DiagramType as DiagramType
import Data.Item as Item exposing (ItemType(..))
import Data.Text as Text exposing (Text)
import Html exposing (Html, div)
import Html.Attributes exposing (class, style)
import Html.Lazy exposing (lazy)
import Html5.DragDrop as DragDrop
import Json.Decode as D
import Models.Diagram as DiagramModel
import Return as Return exposing (Return)
import Task
import Utils.Diagram as DiagramUtils
import Utils.Utils as Utils



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
    , cardWidth : Int
    , cardHeight : Int
    }


type Msg
    = UpdateDiagram DiagramModel.Msg
    | GetCanvasSize String


init : InitData -> ( Model, Cmd Msg )
init flags =
    ( { diagramModel =
            { items = Item.empty
            , data = DiagramModel.Empty
            , size = ( 1024, 1024 )
            , svg =
                { width = 0
                , height = 0
                , scale = 1.0
                }
            , moveState = DiagramModel.NotMove
            , position = ( 0, 0 )
            , movePosition = ( 0, 0 )
            , fullscreen = False
            , showZoomControl = True
            , selectedItem = Nothing
            , contextMenu = Nothing
            , diagramType = DiagramType.fromString flags.diagramType
            , dragDrop = DragDrop.init
            , settings =
                { font = flags.fontName
                , size =
                    { width = flags.cardWidth
                    , height = flags.cardHeight
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
            , touchDistance = Nothing
            , text = Text.empty
            , dragStatus = DiagramModel.NoDrag
            , dropDownIndex = Nothing
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
            [ style "display" "flex"
            , style "overflow" "hidden"
            , style "position" "relative"
            , style "width" "100%"
            , style "height" "100%"
            ]
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


updateText : Text -> Model -> Return Msg Model
updateText text model =
    ( model, setText (Text.toString text) )


update : Msg -> Model -> Return Msg Model
update message model =
    case message of
        UpdateDiagram subMsg ->
            let
                ( model_, cmd_ ) =
                    Diagram.update subMsg model.diagramModel
            in
            case subMsg of
                DiagramModel.EndEditSelectedItem _ code isComposing ->
                    if code == 13 && not isComposing then
                        ( { model | diagramModel = model_ }, Cmd.batch [ cmd_ |> Cmd.map UpdateDiagram, setText (Text.toString model_.text) ] )

                    else
                        ( model, Cmd.none )

                DiagramModel.MoveItem _ ->
                    ( { model | diagramModel = model_ }, cmd_ |> Cmd.map UpdateDiagram )
                        |> Return.andThen (updateText model_.text)

                DiagramModel.FontStyleChanged _ ->
                    ( { model | diagramModel = model_ }, cmd_ |> Cmd.map UpdateDiagram )
                        |> Return.andThen (updateText model_.text)

                DiagramModel.ColorChanged _ _ ->
                    ( { model | diagramModel = model_ }, cmd_ |> Cmd.map UpdateDiagram )
                        |> Return.andThen (updateText model_.text)

                DiagramModel.FontSizeChanged _ ->
                    ( { model | diagramModel = model_ }, cmd_ |> Cmd.map UpdateDiagram )
                        |> Return.andThen (updateText model_.text)

                DiagramModel.Stop ->
                    case model.diagramModel.moveState of
                        DiagramModel.ItemMove target ->
                            case target of
                                DiagramModel.TableTarget table ->
                                    ( { model | diagramModel = model_ }, cmd_ |> Cmd.map UpdateDiagram )
                                        |> Return.andThen (updateText model_.text)

                                _ ->
                                    ( { model | diagramModel = model_ }, cmd_ |> Cmd.map UpdateDiagram )

                        _ ->
                            ( { model | diagramModel = model_ }, cmd_ |> Cmd.map UpdateDiagram )

                _ ->
                    ( { model | diagramModel = model_ }, cmd_ |> Cmd.map UpdateDiagram )

        GetCanvasSize diagramType ->
            let
                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    { diagramModel | diagramType = DiagramType.fromString diagramType }

                size =
                    DiagramUtils.getCanvasSize newDiagramModel
            in
            ( model, onGetCanvasSize size )



-- Subscription


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
