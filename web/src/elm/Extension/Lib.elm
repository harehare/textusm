module Extension.Lib exposing (InitData, Model, Msg, main)

import Browser
import Browser.Events exposing (onMouseUp, onResize)
import Components.Diagram as Diagram
import Html.Styled as Html exposing (Html, div)
import Html.Styled.Attributes exposing (style)
import Html.Styled.Lazy exposing (lazy)
import Json.Decode as D
import Models.Diagram as DiagramModel
import Models.Diagram.Search as Search
import Models.DiagramData as DiagramData
import Models.DiagramSettings as DiagramSettings
import Models.DiagramType exposing (DiagramType(..))
import Models.Item as Item
import Models.Property as Property
import Models.Text as Text
import Return
import Task



-- Model


type alias InitData =
    { text : String
    , width : Int
    , height : Int
    , settings : DiagramSettings.Settings
    , showZoomControl : Bool
    , diagramType : String
    , scale : Float
    }


type alias Model =
    { diagramModel : DiagramModel.Model
    , text : String
    , backgroundColor : String
    }


type Msg
    = UpdateDiagram DiagramModel.Msg


main : Program InitData Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = \m -> Html.toUnstyled <| view m
        , subscriptions = subscriptions
        }


init : InitData -> ( Model, Cmd Msg )
init flags =
    ( { diagramModel =
            { items = Item.empty
            , data = DiagramData.Empty
            , size = ( flags.width, flags.height )
            , svg =
                { size = ( flags.settings.size.width, flags.settings.size.height )
                , scale = flags.scale
                }
            , moveState = DiagramModel.NotMove
            , position = ( 0, 0 )
            , movePosition = ( 0, 0 )
            , isFullscreen = False
            , showZoomControl = flags.showZoomControl
            , showMiniMap = False
            , contextMenu = Nothing
            , diagramType =
                if flags.diagramType == "BusinessModelCanvas" then
                    BusinessModelCanvas

                else if flags.diagramType == "OpportunityCanvas" then
                    OpportunityCanvas

                else if flags.diagramType == "4Ls" then
                    Fourls

                else if flags.diagramType == "StartStopContinue" then
                    StartStopContinue

                else if flags.diagramType == "Kpt" then
                    Kpt

                else if flags.diagramType == "UserPersona" then
                    UserPersona

                else if flags.diagramType == "MindMap" then
                    MindMap

                else if flags.diagramType == "EmpathyMap" then
                    EmpathyMap

                else if flags.diagramType == "Table" then
                    Table

                else if flags.diagramType == "SiteMap" then
                    SiteMap

                else if flags.diagramType == "GanttChart" then
                    GanttChart

                else if flags.diagramType == "ImpactMap" then
                    ImpactMap

                else if flags.diagramType == "ER" then
                    ErDiagram

                else if flags.diagramType == "Kanban" then
                    Kanban

                else if flags.diagramType == "SequenceDiagram" then
                    SequenceDiagram

                else if flags.diagramType == "Freeform" then
                    Freeform

                else if flags.diagramType == "UseCaseDiagram" then
                    UseCaseDiagram

                else
                    UserStoryMap
            , text = Text.empty
            , selectedItem = Nothing
            , settings = flags.settings
            , touchDistance = Nothing
            , dragStatus = DiagramModel.NoDrag
            , dropDownIndex = Nothing
            , property = Property.empty
            , search = Search.close
            }
      , text = flags.text
      , backgroundColor = flags.settings.backgroundColor
      }
    , Task.perform identity (Task.succeed (UpdateDiagram (DiagramModel.ChangeText flags.text)))
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ onResize (\width height -> UpdateDiagram (DiagramModel.Resize width height))
        , onMouseUp (D.succeed (UpdateDiagram DiagramModel.Stop))
        ]



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update (UpdateDiagram subMsg) model =
    case subMsg of
        DiagramModel.ChangeText text ->
            let
                ( model_, _ ) =
                    Return.singleton model.diagramModel |> Diagram.update subMsg
            in
            ( { model | text = text, diagramModel = model_ }, Cmd.none )

        DiagramModel.Select _ ->
            ( model, Cmd.none )

        _ ->
            let
                ( model_, cmd_ ) =
                    Return.singleton model.diagramModel |> Diagram.update subMsg
            in
            ( { model | diagramModel = model_ }, cmd_ |> Cmd.map UpdateDiagram )


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
