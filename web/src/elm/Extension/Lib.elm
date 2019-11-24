port module Extension.Lib exposing (init, main, view)

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
    , width : Int
    , height : Int
    , settings : DiagramModel.Settings
    , showZoomControl : Bool
    , showMiniMap : Bool
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
            , svg =
                { width = flags.settings.size.width
                , height = flags.settings.size.height
                , scale = flags.scale
                }
            , countByHierarchy = []
            , countByTasks = []
            , moveStart = False
            , x = 0
            , y = 0
            , moveX = 0
            , moveY = 0
            , fullscreen = False
            , showZoomControl = flags.showZoomControl
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

                else if flags.diagramType == "UserPersona" then
                    DiagramType.UserPersona

                else if flags.diagramType == "MindMap" then
                    DiagramType.MindMap

                else if flags.diagramType == "EmpathyMap" then
                    DiagramType.EmpathyMap

                else if flags.diagramType == "CustomerJourneyMap" then
                    DiagramType.CustomerJourneyMap

                else if flags.diagramType == "SiteMap" then
                    DiagramType.SiteMap

                else
                    DiagramType.UserStoryMap
            , settings = flags.settings
            , error = Nothing
            , touchDistance = Nothing
            , labels = []
            , matchParent = False
            , showMiniMap = flags.showMiniMap
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
                DiagramModel.OnChangeText text ->
                    let
                        ( model_, cmd_ ) =
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
