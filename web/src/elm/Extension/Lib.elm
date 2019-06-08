port module Extension.Lib exposing (init, main, view)

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
    , backgroundColor : String
    }


type alias InitData =
    { text : String
    , width : Int
    , height : Int
    , settings : FigureModel.Settings
    , showZoomControl : Bool
    , figureType : String
    }


type Msg
    = UpdateFigure FigureModel.Msg


init : InitData -> ( Model, Cmd Msg )
init flags =
    ( { figureModel =
            { items = []
            , hierarchy = 0
            , width = flags.width
            , height = flags.height
            , svg =
                { width = flags.settings.size.width
                , height = flags.settings.size.height
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
            , showZoomControl = flags.showZoomControl
            , figureType =
                if flags.figureType == "BusinessModelCanvas" then
                    FigureModel.BusinessModelCanvas

                else if flags.figureType == "OpportunityCanvas" then
                    FigureModel.OpportunityCanvas

                else
                    FigureModel.UserStoryMap
            , settings = flags.settings
            , error = Nothing
            , comment = Nothing
            , touchDistance = Nothing
            , labels = []
            }
      , text = flags.text
      , backgroundColor = flags.settings.backgroundColor
      }
    , Task.perform identity (Task.succeed (UpdateFigure (FigureModel.OnChangeText flags.text)))
    )


view : Model -> Html Msg
view model =
    div
        [ style "background-color" model.backgroundColor
        ]
        [ div
            [ class "main" ]
            [ lazy Figure.view model.figureModel
                |> Html.map UpdateFigure
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
        UpdateFigure subMsg ->
            case subMsg of
                FigureModel.OnChangeText text ->
                    let
                        figureModel =
                            Figure.update subMsg model.figureModel
                    in
                    case figureModel.error of
                        Just err ->
                            ( { model | text = text, figureModel = figureModel }, errorLine err )

                        Nothing ->
                            ( { model | text = text, figureModel = figureModel }, errorLine "" )

                _ ->
                    ( { model | figureModel = Figure.update subMsg model.figureModel }, Cmd.none )


port errorLine : String -> Cmd msg


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ onResize (\width height -> UpdateFigure (FigureModel.OnResize width height))
        , onMouseUp (D.succeed (UpdateFigure FigureModel.Stop))
        ]
