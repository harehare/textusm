port module Extension.Lib exposing (init, main, view)

import Browser
import Browser.Events exposing (onMouseUp, onResize)
import Components.Diagram as Diagram
import Html exposing (Html, div)
import Html.Attributes exposing (class, style)
import Html.Lazy exposing (lazy)
import Html5.DragDrop as DragDrop
import Json.Decode as D
import Models.Diagram as DiagramModel
import Task
import TextUSM.Enum.Diagram as Diagram



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
            { items = []
            , hierarchy = 0
            , width = flags.width
            , height = flags.height
            , selectedItem = Nothing
            , svg =
                { width = flags.settings.size.width
                , height = flags.settings.size.height
                , scale = flags.scale
                }
            , countByHierarchy = []
            , countByTasks = []
            , moveStart = False
            , dragDrop = DragDrop.init
            , x = 0
            , y = 0
            , moveX = 0
            , moveY = 0
            , fullscreen = False
            , showZoomControl = flags.showZoomControl
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

                else if flags.diagramType == "CustomerJourneyMap" then
                    Diagram.CustomerJourneyMap

                else if flags.diagramType == "SiteMap" then
                    Diagram.SiteMap

                else if flags.diagramType == "GanttChart" then
                    Diagram.GanttChart

                else if flags.diagramType == "ImpactMap" then
                    Diagram.ImpactMap

                else
                    Diagram.UserStoryMap
            , settings = flags.settings
            , error = Nothing
            , touchDistance = Nothing
            , labels = []
            , matchParent = False
            , text = Nothing
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
                DiagramModel.ItemClick _ ->
                    ( model, Cmd.none )

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


port errorLine : String -> Cmd msg


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ onResize (\width height -> UpdateDiagram (DiagramModel.OnResize width height))
        , onMouseUp (D.succeed (UpdateDiagram DiagramModel.Stop))
        ]
