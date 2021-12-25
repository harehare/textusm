module Extension.Lib exposing (InitData, Model, Msg, main)

import Browser
import Browser.Events exposing (onMouseUp, onResize)
import Components.Diagram as Diagram
import Graphql.Enum.Diagram as Diagram
import Html.Styled as Html exposing (Html, div)
import Html.Styled.Attributes exposing (style)
import Html.Styled.Lazy exposing (lazy)
import Json.Decode as D
import Models.Diagram as DiagramModel
import Models.Item as Item
import Models.Property as Property
import Models.Text as Text
import Return
import Task



-- Model


type alias Model =
    { diagramModel : DiagramModel.Model
    , text : String
    , backgroundColor : String
    }


type alias InitData =
    { text : String
    , width : Int
    , height : Int
    , settings : DiagramModel.Settings
    , showZoomControl : Bool
    , diagramType : String
    , scale : Float
    }


type Msg
    = UpdateDiagram DiagramModel.Msg


init : InitData -> ( Model, Cmd Msg )
init flags =
    ( { diagramModel =
            { items = Item.empty
            , data = DiagramModel.Empty
            , size = ( flags.width, flags.height )
            , svg =
                { width = flags.settings.size.width
                , height = flags.settings.size.height
                , scale = flags.scale
                }
            , moveState = DiagramModel.NotMove
            , position = ( 0, 0 )
            , movePosition = ( 0, 0 )
            , fullscreen = False
            , showZoomControl = flags.showZoomControl
            , showMiniMap = False
            , contextMenu = Nothing
            , diagramType =
                if flags.diagramType == "BusinessModelCanvas" then
                    Diagram.BusinessModelCanvas

                else if flags.diagramType == "OpportunityCanvas" then
                    Diagram.OpportunityCanvas

                else if flags.diagramType == "4Ls" then
                    Diagram.Fourls

                else if flags.diagramType == "StartStopContinue" then
                    Diagram.StartStopContinue

                else if flags.diagramType == "Kpt" then
                    Diagram.Kpt

                else if flags.diagramType == "UserPersona" then
                    Diagram.UserPersona

                else if flags.diagramType == "MindMap" then
                    Diagram.MindMap

                else if flags.diagramType == "EmpathyMap" then
                    Diagram.EmpathyMap

                else if flags.diagramType == "Table" then
                    Diagram.Table

                else if flags.diagramType == "SiteMap" then
                    Diagram.SiteMap

                else if flags.diagramType == "GanttChart" then
                    Diagram.GanttChart

                else if flags.diagramType == "ImpactMap" then
                    Diagram.ImpactMap

                else if flags.diagramType == "ER" then
                    Diagram.ErDiagram

                else if flags.diagramType == "Kanban" then
                    Diagram.Kanban

                else if flags.diagramType == "SequenceDiagram" then
                    Diagram.SequenceDiagram

                else if flags.diagramType == "Freeform" then
                    Diagram.Freeform

                else if flags.diagramType == "UseCaseDiagram" then
                    Diagram.UseCaseDiagram

                else
                    Diagram.UserStoryMap
            , text = Text.empty
            , selectedItem = Nothing
            , settings = flags.settings
            , touchDistance = Nothing
            , dragStatus = DiagramModel.NoDrag
            , dropDownIndex = Nothing
            , property = Property.empty
            }
      , text = flags.text
      , backgroundColor = flags.settings.backgroundColor
      }
    , Task.perform identity (Task.succeed (UpdateDiagram (DiagramModel.OnChangeText flags.text)))
    )


view : Model -> Html Msg
view model =
    div
        [ style "background-color" model.backgroundColor
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
        , view = \m -> Html.toUnstyled <| view m
        , subscriptions = subscriptions
        }



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        UpdateDiagram subMsg ->
            case subMsg of
                DiagramModel.Select _ ->
                    ( model, Cmd.none )

                DiagramModel.OnChangeText text ->
                    let
                        ( model_, _ ) =
                            Return.singleton model.diagramModel |> Diagram.update subMsg
                    in
                    ( { model | text = text, diagramModel = model_ }, Cmd.none )

                _ ->
                    let
                        ( model_, cmd_ ) =
                            Return.singleton model.diagramModel |> Diagram.update subMsg
                    in
                    ( { model | diagramModel = model_ }, cmd_ |> Cmd.map UpdateDiagram )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ onResize (\width height -> UpdateDiagram (DiagramModel.OnResize width height))
        , onMouseUp (D.succeed (UpdateDiagram DiagramModel.Stop))
        ]
