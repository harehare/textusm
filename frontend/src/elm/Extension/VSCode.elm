port module Extension.VSCode exposing (InitData, Model, Msg, main)

import Browser
import Browser.Events exposing (onMouseUp, onResize)
import Components.Diagram as Diagram
import Diagram.Types.CardSize as CardSize
import Diagram.Types.Data as DiagramData
import Diagram.Types.Scale as Scale
import Diagram.Types.Search as Search
import Diagram.Types.Type as DiagramType
import Html.Styled as Html exposing (Html, div)
import Html.Styled.Attributes exposing (style)
import Html.Styled.Lazy exposing (lazy)
import Json.Decode as D
import Models.Color as Color
import Models.Diagram as DiagramModel
import Models.Item as Item
import Models.Property as Property
import Models.Size as Size exposing (Size)
import Models.Text as Text exposing (Text)
import Return exposing (Return)
import Task



-- Model


port getCanvasSize : (String -> msg) -> Sub msg


port onGetCanvasSize : ( Int, Int ) -> Cmd msg


port onTextChanged : (String -> msg) -> Sub msg


port setText : String -> Cmd msg


port zoom : (Bool -> msg) -> Sub msg


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
    , toolbar : Bool
    , showGrid : Bool
    }



-- Update


type alias Model =
    { diagramModel : DiagramModel.Model
    , text : String
    , backgroundColor : String
    }


type Msg
    = UpdateDiagram DiagramModel.Msg
    | GetCanvasSize String



-- Subscription


main : Program InitData Model Msg
main =
    Browser.element
        { init = init
        , update = \msg m -> Return.singleton m |> update m msg
        , view = \m -> Html.toUnstyled <| view m
        , subscriptions = subscriptions
        }


init : InitData -> ( Model, Cmd Msg )
init flags =
    ( { diagramModel =
            { items = Item.empty
            , data = DiagramData.Empty
            , windowSize = ( 1024, 1024 )
            , diagram =
                { size = Size.zero
                , position = ( 0, 0 )
                , isFullscreen = False
                }
            , moveState = DiagramModel.NotMove
            , movePosition = ( 0, 0 )
            , showZoomControl = False
            , showMiniMap = False
            , selectedItem = Nothing
            , contextMenu = Nothing
            , diagramType = DiagramType.fromString flags.diagramType
            , settings =
                { font = flags.fontName
                , size =
                    { width = CardSize.fromInt flags.cardWidth
                    , height = CardSize.fromInt flags.cardHeight
                    }
                , backgroundColor = Color.fromString flags.backgroundColor
                , zoomControl = Just flags.toolbar
                , scale = Just Scale.default
                , color =
                    { activity =
                        { color = Color.fromString flags.activityColor
                        , backgroundColor = Color.fromString flags.activityBackgroundColor
                        }
                    , task =
                        { color = Color.fromString flags.taskColor
                        , backgroundColor = Color.fromString flags.taskBackgroundColor
                        }
                    , story =
                        { color = Color.fromString flags.storyColor
                        , backgroundColor = Color.fromString flags.storyBackgroundColor
                        }
                    , line = Color.fromString flags.lineColor
                    , label = Color.fromString flags.labelColor
                    , text = Just <| Color.fromString flags.textColor
                    }
                , toolbar = Just flags.toolbar
                , lockEditing = Nothing
                , showGrid = Just flags.showGrid
                }
            , touchDistance = Nothing
            , text = Text.empty
            , dragStatus = DiagramModel.NoDrag
            , dropDownIndex = Nothing
            , property = Property.empty
            , search = Search.close
            }
      , text = flags.text
      , backgroundColor = flags.backgroundColor
      }
    , Task.perform identity (Task.succeed (UpdateDiagram (DiagramModel.ChangeText flags.text)))
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ onResize (\width height -> UpdateDiagram (DiagramModel.Resize width height))
        , onMouseUp (D.succeed (UpdateDiagram DiagramModel.Stop))
        , onTextChanged (\text -> UpdateDiagram (DiagramModel.ChangeText text))
        , getCanvasSize GetCanvasSize
        , zoom <|
            \z ->
                if z then
                    UpdateDiagram <| DiagramModel.ZoomIn Scale.step

                else
                    UpdateDiagram <| DiagramModel.ZoomOut Scale.step
        ]


update : Model -> Msg -> Return.ReturnF Msg Model
update model message =
    case message of
        UpdateDiagram subMsg ->
            let
                ( model_, cmd_ ) =
                    Return.singleton model.diagramModel |> Diagram.update model.diagramModel subMsg

                m : Model
                m =
                    { model | diagramModel = model_ }
            in
            Return.map (\_ -> m)
                >> Return.command (cmd_ |> Cmd.map UpdateDiagram)
                >> (case subMsg of
                        DiagramModel.EndEditSelectedItem _ ->
                            Return.andThen (updateText model_.text)

                        DiagramModel.ColorChanged _ _ ->
                            Return.andThen (updateText model_.text)

                        DiagramModel.FontStyleChanged _ ->
                            Return.andThen (updateText model_.text)

                        DiagramModel.FontSizeChanged _ ->
                            Return.andThen (updateText model_.text)

                        DiagramModel.Stop ->
                            case m.diagramModel.moveState of
                                DiagramModel.ItemMove _ ->
                                    Return.andThen (updateText model_.text)

                                DiagramModel.ItemResize _ _ ->
                                    Return.andThen (updateText model_.text)

                                _ ->
                                    Return.zero

                        _ ->
                            Return.zero
                   )

        GetCanvasSize diagramType ->
            let
                diagramModel : DiagramModel.Model
                diagramModel =
                    model.diagramModel

                newDiagramModel : DiagramModel.Model
                newDiagramModel =
                    { diagramModel | diagramType = DiagramType.fromString diagramType }

                size : Size
                size =
                    DiagramModel.size newDiagramModel
            in
            Return.command <| onGetCanvasSize size


updateText : Text -> Model -> Return Msg Model
updateText text model =
    Return.return model <| setText (Text.toString text)


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
