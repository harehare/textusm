port module Extension.VSCode exposing (InitData, Model, Msg, main)

import Browser
import Browser.Events exposing (onMouseUp, onResize)
import Components.Diagram as Diagram
import Html.Styled as Html exposing (Html, div)
import Html.Styled.Attributes exposing (style)
import Html.Styled.Lazy exposing (lazy)
import Json.Decode as D
import Models.Diagram as DiagramModel
import Models.DiagramType as DiagramType
import Models.Item as Item
import Models.Property as Property
import Models.Size exposing (Size)
import Models.Text as Text exposing (Text)
import Return exposing (Return)
import Task
import Utils.Diagram as DiagramUtils



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
            , showZoomControl = False
            , showMiniMap = False
            , selectedItem = Nothing
            , contextMenu = Nothing
            , diagramType = DiagramType.fromString flags.diagramType
            , settings =
                { font = flags.fontName
                , size =
                    { width = flags.cardWidth
                    , height = flags.cardHeight
                    }
                , backgroundColor = flags.backgroundColor
                , zoomControl = Just False
                , scale = Just 1.0
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
            , property = Property.empty
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
        , update = \msg m -> Return.singleton m |> update msg
        , view = \m -> Html.toUnstyled <| view m
        , subscriptions = subscriptions
        }



-- Update


updateText : Text -> Model -> Return Msg Model
updateText text model =
    Return.return model <| setText (Text.toString text)


update : Msg -> Return.ReturnF Msg Model
update message =
    case message of
        UpdateDiagram subMsg ->
            Return.andThen <|
                \m ->
                    let
                        ( model_, cmd_ ) =
                            Return.singleton m.diagramModel |> Diagram.update subMsg

                        model : Model
                        model =
                            { m | diagramModel = model_ }
                    in
                    Return.return model
                        (cmd_ |> Cmd.map UpdateDiagram)
                        |> (case subMsg of
                                DiagramModel.EndEditSelectedItem _ ->
                                    Return.andThen (updateText model_.text)

                                DiagramModel.FontStyleChanged _ ->
                                    Return.andThen (updateText model_.text)

                                DiagramModel.ColorChanged _ _ ->
                                    Return.andThen (updateText model_.text)

                                DiagramModel.FontSizeChanged _ ->
                                    Return.andThen (updateText model_.text)

                                DiagramModel.Stop ->
                                    case m.diagramModel.moveState of
                                        DiagramModel.ItemMove target ->
                                            case target of
                                                DiagramModel.TableTarget _ ->
                                                    Return.andThen (updateText model_.text)

                                                DiagramModel.ItemTarget _ ->
                                                    Return.andThen (updateText model_.text)

                                        DiagramModel.ItemResize _ _ ->
                                            Return.andThen (updateText model_.text)

                                        _ ->
                                            Return.zero

                                _ ->
                                    Return.zero
                           )

        GetCanvasSize diagramType ->
            Return.andThen <|
                \m ->
                    let
                        diagramModel : DiagramModel.Model
                        diagramModel =
                            m.diagramModel

                        newDiagramModel : DiagramModel.Model
                        newDiagramModel =
                            { diagramModel | diagramType = DiagramType.fromString diagramType }

                        size : Size
                        size =
                            DiagramUtils.getCanvasSize newDiagramModel
                    in
                    Return.return m <| onGetCanvasSize size



-- Subscription


port setText : String -> Cmd msg


port onGetCanvasSize : ( Int, Int ) -> Cmd msg


port onTextChanged : (String -> msg) -> Sub msg


port getCanvasSize : (String -> msg) -> Sub msg


port zoom : (Bool -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ onResize (\width height -> UpdateDiagram (DiagramModel.OnResize width height))
        , onMouseUp (D.succeed (UpdateDiagram DiagramModel.Stop))
        , onTextChanged (\text -> UpdateDiagram (DiagramModel.OnChangeText text))
        , getCanvasSize GetCanvasSize
        , zoom <|
            \z ->
                if z then
                    UpdateDiagram <| DiagramModel.ZoomIn 0.01

                else
                    UpdateDiagram <| DiagramModel.ZoomOut 0.01
        ]
