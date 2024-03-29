module Extension.Lib exposing (InitData, Model, Msg, main)

import Browser
import Browser.Events exposing (onMouseUp, onResize)
import Diagram.Search.Types as Search
import Diagram.State as DiagramState
import Diagram.Types as DiagramModel
import Diagram.Types.CardSize as CardSize
import Diagram.Types.Data as DiagramData
import Diagram.Types.Settings as DiagramSettings
import Diagram.Types.Type as DiagramType
import Diagram.View as DiagramView
import Html.Styled as Html exposing (Html, div)
import Html.Styled.Attributes exposing (style)
import Html.Styled.Lazy exposing (lazy)
import Json.Decode as D
import Json.Encode as E
import Return
import Task
import Types.Color as Color exposing (Color)
import Types.Item as Item
import Types.Property as Property
import Types.Text as Text



-- Model


type alias InitData =
    { text : String
    , width : Int
    , height : Int
    , settings : E.Value
    , showZoomControl : Bool
    , diagramType : String
    , scale : Float
    }


type alias Model =
    { diagramModel : DiagramModel.Model
    , text : String
    , backgroundColor : Color
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
    let
        settings : DiagramSettings.Settings
        settings =
            D.decodeValue DiagramSettings.decoder flags.settings
                |> Result.toMaybe
                |> Maybe.map (\s -> s |> DiagramSettings.zoomControl.set s.toolbar)
                |> Maybe.withDefault DiagramSettings.default
                |> DiagramSettings.toolbar.set (Just False)
    in
    ( { diagramModel =
            { items = Item.empty
            , data = DiagramData.Empty
            , windowSize = ( flags.width, flags.height )
            , diagram =
                { size = ( CardSize.toInt settings.size.width, CardSize.toInt settings.size.height )
                , position = ( 0, 0 )
                , isFullscreen = False
                }
            , moveState = DiagramModel.NotMove
            , movePosition = ( 0, 0 )
            , showZoomControl = flags.showZoomControl
            , showMiniMap = False
            , contextMenu = Nothing
            , diagramType = DiagramType.fromTypeString flags.diagramType
            , text = Text.empty
            , selectedItem = Nothing
            , settings = settings
            , touchDistance = Nothing
            , dragStatus = DiagramModel.NoDrag
            , dropDownIndex = Nothing
            , property = Property.empty
            , search = Search.close
            }
      , text = flags.text
      , backgroundColor = settings.backgroundColor
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
                    Return.singleton model.diagramModel |> DiagramState.update model.diagramModel subMsg
            in
            ( { model | text = text, diagramModel = model_ }, Cmd.none )

        DiagramModel.Select _ ->
            ( model, Cmd.none )

        _ ->
            let
                ( model_, cmd_ ) =
                    Return.singleton model.diagramModel |> DiagramState.update model.diagramModel subMsg
            in
            ( { model | diagramModel = model_ }, cmd_ |> Cmd.map UpdateDiagram )


view : Model -> Html Msg
view model =
    div
        [ style "background-color" <| Color.toString model.backgroundColor
        ]
        [ div
            [ style "display" "flex"
            , style "overflow" "hidden"
            , style "position" "relative"
            , style "width" "100%"
            , style "height" "100%"
            ]
            [ lazy DiagramView.view model.diagramModel
                |> Html.map UpdateDiagram
            ]
        ]
