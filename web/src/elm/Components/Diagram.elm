module Components.Diagram exposing (init, update, view)

import Browser.Dom as Dom
import Constants
import Data.FontStyle as FontStyle
import Data.Item as Item exposing (ItemType(..))
import Data.ItemSettings as ItemSettings
import Data.Position as Position exposing (Position)
import Data.Size as Size exposing (Size)
import Data.Text as Text
import Events
import File
import Html exposing (Html, div)
import Html.Attributes as Attr
import Html.Events as Event
import Html.Events.Extra.Touch as Touch
import Html.Events.Extra.Wheel as Wheel
import Json.Decode as D
import List
import List.Extra exposing (getAt, setAt)
import Maybe
import Models.Diagram as Diagram exposing (DragStatus(..), Model, Msg(..), SelectedItem, Settings)
import Models.Views.BusinessModelCanvas as BusinessModelCanvasModel
import Models.Views.ER as ErDiagramModel
import Models.Views.EmpathyMap as EmpathyMapModel
import Models.Views.FourLs as FourLsModel
import Models.Views.FreeForm as FreeFormModel
import Models.Views.GanttChart as GanttChartModel
import Models.Views.Kanban as KanbanModel
import Models.Views.Kpt as KptModel
import Models.Views.OpportunityCanvas as OpportunityCanvasModel
import Models.Views.SequenceDiagram as SequenceDiagramModel
import Models.Views.StartStopContinue as StartStopContinueModel
import Models.Views.Table as TableModel
import Models.Views.UserPersona as UserPersonaModel
import Models.Views.UserStoryMap as UserStoryMapModel
import Return as Return exposing (Return)
import String
import Svg exposing (Svg)
import Svg.Attributes as SvgAttr
import Svg.Events exposing (onClick)
import Svg.Lazy as Lazy
import Task
import TextUSM.Enum.Diagram exposing (Diagram(..))
import Utils.Diagram as DiagramUtils
import Utils.Utils as Utils
import Views.Diagram.BusinessModelCanvas as BusinessModelCanvas
import Views.Diagram.ContextMenu as ContextMenu
import Views.Diagram.ER as ER
import Views.Diagram.EmpathyMap as EmpathyMap
import Views.Diagram.FourLs as FourLs
import Views.Diagram.FreeForm as FreeForm
import Views.Diagram.GanttChart as GanttChart
import Views.Diagram.ImpactMap as ImpactMap
import Views.Diagram.Kanban as Kanban
import Views.Diagram.Kpt as Kpt
import Views.Diagram.MindMap as MindMap
import Views.Diagram.MiniMap as MiniMap
import Views.Diagram.OpportunityCanvas as OpportunityCanvas
import Views.Diagram.SequenceDiagram as SequenceDiagram
import Views.Diagram.SiteMap as SiteMap
import Views.Diagram.StartStopContinue as StartStopContinue
import Views.Diagram.Table as Table
import Views.Diagram.UserPersona as UserPersona
import Views.Diagram.UserStoryMap as UserStoryMap
import Views.Empty as Empty
import Views.Icon as Icon


init : Settings -> Return Msg Model
init settings =
    Return.singleton
        { items = Item.empty
        , data = Diagram.Empty
        , size = ( 0, 0 )
        , svg =
            { width = 0
            , height = 0
            , scale = Maybe.withDefault 1.0 settings.scale
            }
        , moveState = Diagram.NotMove
        , position = ( 0, 20 )
        , movePosition = ( 0, 0 )
        , fullscreen = False
        , showZoomControl = True
        , showMiniMap = False
        , touchDistance = Nothing
        , settings = settings
        , diagramType = UserStoryMap
        , text = Text.empty
        , selectedItem = Nothing
        , contextMenu = Nothing
        , dragStatus = NoDrag
        , dropDownIndex = Nothing
        }


zoomControl : Bool -> Float -> Html Msg
zoomControl isFullscreen scale =
    let
        s =
            round <| scale * 100.0
    in
    div
        [ Attr.id "zoom-control"
        , Attr.style "position" "absolute"
        , Attr.style "align-items" "center"
        , Attr.style "right" "35px"
        , Attr.style "top" "5px"
        , Attr.style "display" "flex"
        , Attr.style "width" "180px"
        , Attr.style "justify-content" "space-between"
        ]
        [ div
            [ Attr.style "width" "24px"
            , Attr.style "height" "24px"
            , Attr.style "cursor" "pointer"
            , Attr.style "display" "flex"
            , Attr.style "align-items" "center"
            , onClick FitToWindow
            ]
            [ Icon.expandAlt 14
            ]
        , div
            [ Attr.style "width" "24px"
            , Attr.style "height" "24px"
            , Attr.style "cursor" "pointer"
            , Attr.style "display" "flex"
            , Attr.style "align-items" "center"
            , onClick ToggleMiniMap
            ]
            [ Icon.map 14
            ]
        , div
            [ Attr.style "width" "24px"
            , Attr.style "height" "24px"
            , Attr.style "cursor" "pointer"
            , onClick ZoomOut
            ]
            [ Icon.remove 24
            ]
        , div
            [ Attr.style "font-size" "0.7rem"
            , Attr.style "color" "#8C9FAE"
            , Attr.style "cursor" "pointer"
            , Attr.style "font-weight" "600"
            , Attr.class ".select-none"
            ]
            [ Html.text (String.fromInt s ++ "%")
            ]
        , div
            [ Attr.style "width" "24px"
            , Attr.style "height" "24px"
            , Attr.style "cursor" "pointer"
            , onClick ZoomIn
            ]
            [ Icon.add 24
            ]
        , div
            [ Attr.style "width" "24px"
            , Attr.style "height" "24px"
            , Attr.style "cursor" "pointer"
            , onClick ToggleFullscreen
            ]
            [ if isFullscreen then
                Icon.fullscreenExit 24

              else
                Icon.fullscreen 24
            ]
        ]



-- View


view : Model -> Html Msg
view model =
    let
        svgWidth =
            if model.fullscreen then
                Basics.toFloat
                    (Basics.max model.svg.width (Size.getWidth model.size))
                    |> round

            else
                Basics.toFloat
                    (Size.getWidth model.size)
                    |> round

        svgHeight =
            if model.fullscreen then
                Basics.toFloat
                    (Basics.max model.svg.height (Size.getHeight model.size))
                    |> round

            else
                Basics.toFloat
                    (Size.getHeight model.size)
                    |> round

        centerPosition =
            case model.diagramType of
                MindMap ->
                    Tuple.mapBoth (\x -> x + (svgWidth // 3)) (\y -> y + (svgHeight // 3)) model.position

                ImpactMap ->
                    Tuple.mapBoth (\x -> x + Constants.itemMargin) (\y -> y + (svgHeight // 3)) model.position

                _ ->
                    model.position

        mainSvg =
            Lazy.lazy (diagramView model.diagramType) model
    in
    div
        [ Attr.id "usm-area"
        , Attr.style "position" "relative"
        , case model.moveState of
            Diagram.BoardMove ->
                Attr.style "cursor" "grabbing"

            _ ->
                Attr.style "cursor" "grab"
        , Events.onDrop DropFiles
        , Events.onMouseUp <| \_ -> Stop
        , Event.preventDefaultOn "dragover" <|
            D.succeed ( ChangeDragStatus DragOver, True )
        , Event.preventDefaultOn "dragleave" <|
            D.succeed ( ChangeDragStatus NoDrag, True )
        , case model.dragStatus of
            DragOver ->
                Attr.class "drag-over"

            NoDrag ->
                Attr.class ""
        ]
        [ if model.settings.zoomControl |> Maybe.withDefault model.showZoomControl then
            Lazy.lazy2 zoomControl model.fullscreen model.svg.scale

          else
            Empty.view
        , Lazy.lazy MiniMap.view
            { showMiniMap = model.showMiniMap
            , diagramType = model.diagramType
            , scale = model.svg.scale
            , svgSize = ( svgWidth, svgHeight )
            , viewport = model.size
            , position = centerPosition
            , diagramSvg = mainSvg
            }
        , Lazy.lazy4 svgView model centerPosition ( svgWidth, svgHeight ) mainSvg
        ]


diagramView : Diagram -> Model -> Svg Msg
diagramView diagramType =
    case diagramType of
        UserStoryMap ->
            UserStoryMap.view

        BusinessModelCanvas ->
            BusinessModelCanvas.view

        OpportunityCanvas ->
            OpportunityCanvas.view

        Fourls ->
            FourLs.view

        StartStopContinue ->
            StartStopContinue.view

        Kpt ->
            Kpt.view

        UserPersona ->
            UserPersona.view

        MindMap ->
            MindMap.view

        EmpathyMap ->
            EmpathyMap.view

        Table ->
            Table.view

        SiteMap ->
            SiteMap.view

        GanttChart ->
            GanttChart.view

        ImpactMap ->
            ImpactMap.view

        ErDiagram ->
            ER.view

        Kanban ->
            Kanban.view

        SequenceDiagram ->
            SequenceDiagram.view

        Freeform ->
            FreeForm.view


svgView : Model -> Position -> Size -> Svg Msg -> Svg Msg
svgView model centerPosition ( svgWidth, svgHeight ) mainSvg =
    Svg.svg
        [ Attr.id "usm"
        , SvgAttr.width
            (String.fromInt
                (if Utils.isPhone (Size.getWidth model.size) || model.fullscreen then
                    svgWidth

                 else if Size.getWidth model.size - 56 > 0 then
                    Size.getWidth model.size - 56

                 else
                    0
                )
            )
        , SvgAttr.height
            (String.fromInt <|
                if model.fullscreen then
                    svgHeight

                else
                    Size.getHeight model.size
            )
        , SvgAttr.viewBox ("0 0 " ++ String.fromInt svgWidth ++ " " ++ String.fromInt svgHeight)
        , Attr.style "background-color" model.settings.backgroundColor
        , case model.selectedItem of
            Just _ ->
                Attr.style "" ""

            Nothing ->
                Events.onWheel chooseZoom
        , onDragStart model.selectedItem (Utils.isPhone <| Size.getWidth model.size)
        , onDragMove model.touchDistance model.moveState (Utils.isPhone <| Size.getWidth model.size)
        , onClick <| Select Nothing
        ]
        [ if String.isEmpty model.settings.font then
            Svg.g [] []

          else
            Svg.defs [] [ Svg.style [] [ Svg.text ("@import url('https://fonts.googleapis.com/css?family=" ++ model.settings.font ++ "&display=swap');") ] ]
        , Svg.defs []
            [ Svg.filter [ SvgAttr.id "shadow", SvgAttr.height "130%" ]
                [ Svg.feGaussianBlur [ SvgAttr.in_ "SourceAlpha", SvgAttr.stdDeviation "3" ] []
                , Svg.feOffset [ SvgAttr.dx "2", SvgAttr.dy "2", SvgAttr.result "offsetblur" ] []
                , Svg.feComponentTransfer []
                    [ Svg.feFuncA [ SvgAttr.type_ "linear", SvgAttr.slope "0.5" ] []
                    ]
                , Svg.feMerge []
                    [ Svg.feMergeNode [] []
                    , Svg.feMergeNode [ SvgAttr.in_ "SourceGraphic" ] []
                    ]
                ]
            ]
        , case model.data of
            Diagram.UserStoryMap userStoryMap ->
                Svg.text_
                    [ SvgAttr.x "8"
                    , SvgAttr.y "8"
                    , SvgAttr.fontSize "12"
                    , SvgAttr.fontFamily <| Diagram.fontStyle model.settings
                    , SvgAttr.fill (model.settings.color.text |> Maybe.withDefault model.settings.color.label)
                    ]
                    [ Svg.text <| UserStoryMapModel.getReleaseLevel userStoryMap "title" "" ]

            _ ->
                Svg.g [] []
        , Svg.g
            [ SvgAttr.transform <|
                "translate("
                    ++ String.fromInt (Position.getX centerPosition)
                    ++ ","
                    ++ String.fromInt (Position.getY centerPosition)
                    ++ ") scale("
                    ++ String.fromFloat
                        (if isInfinite model.svg.scale then
                            1.0

                         else
                            model.svg.scale
                        )
                    ++ ","
                    ++ String.fromFloat
                        (if isInfinite model.svg.scale then
                            1.0

                         else
                            model.svg.scale
                        )
                    ++ ")"
            , SvgAttr.fill model.settings.backgroundColor
            , SvgAttr.style "will-change: transform;"
            ]
            [ mainSvg ]
        , case ( model.selectedItem, model.contextMenu ) of
            ( Just item_, Just ( contextMenu, position ) ) ->
                ContextMenu.view
                    { state = contextMenu
                    , item = item_
                    , position =
                        ( floor <| toFloat (Position.getX position + Position.getX centerPosition) * model.svg.scale
                        , floor <| toFloat (Position.getY position + Position.getY centerPosition) * model.svg.scale
                        )
                    , dropDownIndex = model.dropDownIndex
                    , onMenuSelect = SelectContextMenu
                    , onColorChanged = ColorChanged Diagram.ColorSelectMenu
                    , onBackgroundColorChanged = ColorChanged Diagram.BackgroundColorSelectMenu
                    , onFontStyleChanged = FontStyleChanged
                    , onFontSizeChanged = FontSizeChanged
                    , onToggleDropDownList = ToggleDropDownList
                    }

            _ ->
                Empty.view
        ]


onDragStart : SelectedItem -> Bool -> Svg.Attribute Msg
onDragStart item isPhone =
    case ( item, isPhone ) of
        ( Nothing, True ) ->
            Touch.onStart <|
                \event ->
                    if List.length event.changedTouches > 1 then
                        let
                            p1 =
                                getAt 0 event.changedTouches
                                    |> Maybe.map .pagePos
                                    |> Maybe.withDefault ( 0, 0 )

                            p2 =
                                getAt 1 event.changedTouches
                                    |> Maybe.map .pagePos
                                    |> Maybe.withDefault ( 0, 0 )
                        in
                        StartPinch (Utils.calcDistance p1 p2)

                    else
                        let
                            ( x, y ) =
                                touchCoordinates event
                        in
                        Start Diagram.BoardMove ( round x, round y )

        ( Nothing, False ) ->
            Events.onMouseDown <|
                \event ->
                    let
                        ( x, y ) =
                            event.pagePos
                    in
                    Start Diagram.BoardMove ( round x, round y )

        _ ->
            Attr.style "" ""


onDragMove : Maybe Float -> Diagram.MoveState -> Bool -> Svg.Attribute Msg
onDragMove distance moveState isPhone =
    case ( moveState, isPhone ) of
        ( Diagram.NotMove, _ ) ->
            Attr.style "" ""

        ( _, True ) ->
            Touch.onMove <|
                \event ->
                    if List.length event.changedTouches > 1 then
                        let
                            p1 =
                                getAt 0 event.changedTouches
                                    |> Maybe.map .pagePos
                                    |> Maybe.withDefault ( 0, 0 )

                            p2 =
                                getAt 1 event.changedTouches
                                    |> Maybe.map .pagePos
                                    |> Maybe.withDefault ( 0, 0 )
                        in
                        case distance of
                            Just x ->
                                let
                                    newDistance =
                                        Utils.calcDistance p1 p2
                                in
                                if newDistance / x > 1.0 then
                                    PinchIn newDistance

                                else if newDistance / x < 1.0 then
                                    PinchOut newDistance

                                else
                                    NoOp

                            Nothing ->
                                StartPinch (Utils.calcDistance p1 p2)

                    else
                        let
                            ( x, y ) =
                                touchCoordinates event
                        in
                        Move ( round x, round y )

        ( _, False ) ->
            Events.onMouseMove <|
                \event ->
                    let
                        ( x, y ) =
                            event.pagePos
                    in
                    Move ( round x, round y )


chooseZoom : Wheel.Event -> Msg
chooseZoom wheelEvent =
    if wheelEvent.deltaY > 0 then
        ZoomOut

    else
        ZoomIn


touchCoordinates : Touch.Event -> ( Float, Float )
touchCoordinates touchEvent =
    List.head touchEvent.changedTouches
        |> Maybe.map .clientPos
        |> Maybe.withDefault ( 0, 0 )



-- Update


updateDiagram : Size -> Model -> String -> Model
updateDiagram ( width, height ) base text =
    let
        ( hierarchy, items ) =
            Item.fromString text

        data =
            case base.diagramType of
                UserStoryMap ->
                    Diagram.UserStoryMap <| UserStoryMapModel.from text hierarchy items

                Table ->
                    Diagram.Table <| TableModel.from items

                Kpt ->
                    Diagram.Kpt <| KptModel.from items

                BusinessModelCanvas ->
                    Diagram.BusinessModelCanvas <| BusinessModelCanvasModel.from items

                EmpathyMap ->
                    Diagram.EmpathyMap <| EmpathyMapModel.from items

                Fourls ->
                    Diagram.FourLs <| FourLsModel.from items

                Kanban ->
                    Diagram.Kanban <| KanbanModel.from items

                OpportunityCanvas ->
                    Diagram.OpportunityCanvas <| OpportunityCanvasModel.from items

                StartStopContinue ->
                    Diagram.StartStopContinue <| StartStopContinueModel.from items

                UserPersona ->
                    Diagram.UserPersona <| UserPersonaModel.from items

                ErDiagram ->
                    Diagram.ErDiagram <| ErDiagramModel.from items

                MindMap ->
                    Diagram.MindMap items hierarchy

                ImpactMap ->
                    Diagram.ImpactMap items hierarchy

                SiteMap ->
                    Diagram.SiteMap items hierarchy

                SequenceDiagram ->
                    Diagram.SequenceDiagram <| SequenceDiagramModel.from items

                Freeform ->
                    Diagram.FreeForm <| FreeFormModel.from items

                GanttChart ->
                    Diagram.GanttChart <| GanttChartModel.from items

        newModel =
            { base | items = items, data = data }

        ( svgWidth, svgHeight ) =
            DiagramUtils.getCanvasSize newModel
    in
    { newModel
        | size = ( width, height )
        , svg =
            { width = svgWidth
            , height = svgHeight
            , scale = base.svg.scale
            }
        , movePosition = Position.zero
        , text = Text.edit base.text text
    }


clearPosition : Model -> Return Msg Model
clearPosition model =
    Return.singleton { model | movePosition = Position.zero }


setFocus : String -> Model -> Return Msg Model
setFocus id model =
    Return.return model (Task.attempt (\_ -> NoOp) <| Dom.focus id)


setText : String -> Model -> Return Msg Model
setText text model =
    Return.singleton { model | text = Text.change <| Text.fromString text }


closeDropDown : Model -> Return Msg Model
closeDropDown model =
    Return.singleton { model | dropDownIndex = Nothing }


setLine : Int -> List String -> String -> Model -> Return Msg Model
setLine lineNo lines line model =
    setText
        (setAt lineNo line lines
            |> String.join "\n"
        )
        model


selectItem : SelectedItem -> Model -> Return Msg Model
selectItem item model =
    Return.singleton { model | selectedItem = item }


stopMove : Model -> Return Msg Model
stopMove model =
    Return.singleton
        { model
            | moveState = Diagram.NotMove
            , movePosition = Position.zero
            , touchDistance = Nothing
        }


clearSelectedItem : Model -> Return Msg Model
clearSelectedItem model =
    Return.singleton { model | selectedItem = Nothing }


setTouchDistance : Maybe Float -> Model -> Return Msg Model
setTouchDistance distance model =
    Return.singleton { model | touchDistance = distance }


zoomIn : Model -> Return Msg Model
zoomIn model =
    if model.svg.scale <= 10.0 then
        Return.singleton
            { model
                | svg =
                    { width = model.svg.width
                    , height = model.svg.height
                    , scale = model.svg.scale + 0.01
                    }
            }

    else
        Return.singleton model


zoomOut : Model -> Return Msg Model
zoomOut model =
    if model.svg.scale > 0.01 then
        Return.singleton
            { model
                | svg =
                    { width = model.svg.width
                    , height = model.svg.height
                    , scale = model.svg.scale - 0.01
                    }
            }

    else
        Return.singleton model


update : Msg -> Model -> Return Msg Model
update message model =
    Return.singleton model
        |> (case message of
                NoOp ->
                    Return.zero

                Init settings window text ->
                    let
                        width =
                            round window.viewport.width

                        height =
                            round window.viewport.height - 50
                    in
                    Return.andThen (\m -> Return.singleton <| updateDiagram ( width, height ) m text)
                        >> Return.andThen (\m -> Return.singleton { m | settings = settings })

                ZoomIn ->
                    Return.andThen zoomIn

                ZoomOut ->
                    Return.andThen zoomOut

                PinchIn distance ->
                    Return.andThen (setTouchDistance <| Just distance)
                        >> Return.andThen zoomIn

                PinchOut distance ->
                    Return.andThen (setTouchDistance <| Just distance)
                        >> Return.andThen zoomOut

                OnChangeText text ->
                    Return.andThen <| \m -> Return.singleton <| updateDiagram m.size m text

                Start moveState pos ->
                    Return.andThen <|
                        \m ->
                            Return.singleton
                                { m
                                    | moveState = moveState
                                    , movePosition = pos
                                }

                Stop ->
                    (case model.moveState of
                        Diagram.ItemMove target ->
                            case target of
                                Diagram.TableTarget table ->
                                    let
                                        (ErDiagramModel.Table _ _ _ lineNo) =
                                            table
                                    in
                                    Return.andThen (setLine lineNo (Text.lines model.text) (ErDiagramModel.tableToLineString table))

                                Diagram.ItemTarget item ->
                                    Return.andThen (setLine (Item.getLineNo item) (Text.lines model.text) (Item.toLineString item))

                        _ ->
                            Return.zero
                    )
                        >> Return.andThen stopMove

                Move ( x, y ) ->
                    if not (Diagram.isMoving model.moveState) || (x == Position.getX model.movePosition && y == Position.getY model.movePosition) then
                        Return.zero

                    else
                        case model.moveState of
                            Diagram.BoardMove ->
                                Return.andThen <|
                                    \m ->
                                        Return.singleton
                                            { m
                                                | position =
                                                    ( Position.getX model.position + round (toFloat (x - Position.getX model.movePosition) * model.svg.scale)
                                                    , Position.getY model.position + round (toFloat (y - Position.getY model.movePosition) * model.svg.scale)
                                                    )
                                                , movePosition = ( x, y )
                                            }

                            Diagram.ItemMove target ->
                                case target of
                                    Diagram.TableTarget table ->
                                        let
                                            (ErDiagramModel.Table name columns position lineNo) =
                                                table

                                            newPosition =
                                                Just
                                                    (position
                                                        |> Maybe.andThen
                                                            (\p ->
                                                                Just
                                                                    ( Position.getX p + round (toFloat (x - Position.getX model.movePosition) / model.svg.scale)
                                                                    , Position.getY p + round (toFloat (y - Position.getY model.movePosition) / model.svg.scale)
                                                                    )
                                                            )
                                                        |> Maybe.withDefault ( x - Position.getX model.movePosition, y - Position.getY model.movePosition )
                                                    )
                                        in
                                        Return.andThen <|
                                            \m ->
                                                Return.singleton
                                                    { m
                                                        | moveState =
                                                            Diagram.ItemMove <|
                                                                Diagram.TableTarget (ErDiagramModel.Table name columns newPosition lineNo)
                                                        , movePosition = ( x, y )
                                                    }

                                    Diagram.ItemTarget item ->
                                        let
                                            offset =
                                                Item.getOffset item

                                            newPosition =
                                                ( Position.getX offset + round (toFloat (x - Position.getX model.movePosition) / model.svg.scale)
                                                , Position.getY offset + round (toFloat (y - Position.getY model.movePosition) / model.svg.scale)
                                                )
                                        in
                                        Return.andThen <|
                                            \m ->
                                                Return.singleton
                                                    { m
                                                        | moveState =
                                                            Diagram.ItemMove
                                                                (Diagram.ItemTarget <|
                                                                    Item.withItemSettings
                                                                        (Just (Item.getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.withOffset newPosition))
                                                                        item
                                                                )
                                                        , movePosition = ( x, y )
                                                    }

                            _ ->
                                Return.zero

                MoveTo position ->
                    Return.andThen (\m -> Return.singleton { m | position = position })
                        >> Return.andThen clearPosition

                ToggleFullscreen ->
                    Return.andThen (\m -> Return.singleton { m | fullscreen = not model.fullscreen })
                        >> Return.andThen clearPosition

                OnResize width height ->
                    Return.andThen (\m -> Return.singleton { m | size = ( width, height - 56 ) })
                        >> Return.andThen clearPosition

                StartPinch distance ->
                    Return.andThen <| \m -> Return.singleton { m | touchDistance = Just distance }

                EditSelectedItem text ->
                    Return.andThen <| \m -> Return.singleton { m | selectedItem = Maybe.andThen (\item_ -> Just (item_ |> Item.withTextOnly (" " ++ String.trimLeft text))) m.selectedItem }

                FitToWindow ->
                    let
                        ( windowWidth, windowHeight ) =
                            model.size

                        ( canvasWidth, canvasHeight ) =
                            DiagramUtils.getCanvasSize model

                        ( widthRatio, heightRatio ) =
                            ( toFloat (round (toFloat windowWidth / toFloat canvasWidth / 0.05)) * 0.05, toFloat (round (toFloat windowHeight / toFloat canvasHeight / 0.05)) * 0.05 )

                        svgModel =
                            model.svg

                        newSvgModel =
                            { svgModel | scale = min widthRatio heightRatio }

                        position =
                            ( windowWidth // 2 - round (toFloat canvasWidth / 2 * widthRatio), windowHeight // 2 - round (toFloat canvasHeight / 2 * heightRatio) )
                    in
                    Return.andThen <| \m -> Return.singleton { m | svg = newSvgModel, position = position }

                Select (Just ( item, position )) ->
                    if Item.isImage <| Item.getText item then
                        Return.zero

                    else
                        Return.andThen (\m -> Return.singleton { m | selectedItem = Just item, contextMenu = Just ( Diagram.CloseMenu, position ) })
                            >> Return.andThen (setFocus "edit-item")

                Select Nothing ->
                    Return.andThen <| \m -> Return.singleton { m | selectedItem = Nothing }

                EndEditSelectedItem item ->
                    case model.selectedItem of
                        Just selectedItem ->
                            let
                                lines =
                                    Text.lines model.text

                                currentText =
                                    getAt (Item.getLineNo item) lines

                                prefix =
                                    currentText
                                        |> Maybe.withDefault ""
                                        |> DiagramUtils.getSpacePrefix

                                text =
                                    setAt (Item.getLineNo item)
                                        (prefix
                                            ++ (item
                                                    |> Item.withItemSettings
                                                        (Item.getItemSettings selectedItem)
                                                    |> Item.toLineString
                                                    |> String.trimLeft
                                               )
                                        )
                                        lines
                                        |> String.join "\n"
                            in
                            Return.andThen (setText text)
                                >> Return.andThen clearSelectedItem

                        Nothing ->
                            Return.zero

                SelectContextMenu menu ->
                    Return.andThen <| \m -> Return.singleton { m | contextMenu = Maybe.andThen (\c -> Just <| Tuple.mapFirst (\_ -> menu) c) m.contextMenu }

                FontSizeChanged size ->
                    case model.selectedItem of
                        Nothing ->
                            Return.zero

                        Just item ->
                            let
                                lines =
                                    Text.lines model.text

                                currentText =
                                    getAt (Item.getLineNo item) lines

                                ( mainText, settings ) =
                                    currentText
                                        |> Maybe.withDefault ""
                                        |> Item.spiltText

                                text =
                                    Item.new
                                        |> Item.withText mainText
                                        |> Item.withItemSettings (Just (settings |> ItemSettings.withFontSize size))
                                        |> Item.toLineString

                                prefix =
                                    currentText
                                        |> Maybe.withDefault ""
                                        |> DiagramUtils.getSpacePrefix

                                updateText =
                                    setAt (Item.getLineNo item) (prefix ++ String.trimLeft text) lines
                                        |> String.join "\n"
                            in
                            case model.selectedItem of
                                Just item_ ->
                                    Return.andThen closeDropDown
                                        >> Return.andThen (setText updateText)
                                        >> Return.andThen
                                            (selectItem
                                                (Just
                                                    (item_
                                                        |> Item.withItemSettings
                                                            (Item.getItemSettings item_
                                                                |> Maybe.andThen (\s -> Just (ItemSettings.withFontSize size <| s))
                                                            )
                                                    )
                                                )
                                            )

                                _ ->
                                    Return.zero

                ColorChanged menu color ->
                    case model.selectedItem of
                        Nothing ->
                            Return.zero

                        Just item ->
                            let
                                lines =
                                    Text.lines model.text

                                currentText =
                                    getAt (Item.getLineNo item) lines

                                ( mainText, settings ) =
                                    currentText
                                        |> Maybe.withDefault ""
                                        |> Item.spiltText

                                text =
                                    case menu of
                                        Diagram.ColorSelectMenu ->
                                            Item.new
                                                |> Item.withText mainText
                                                |> Item.withItemSettings (Just (settings |> ItemSettings.withForegroundColor (Just color)))
                                                |> Item.toLineString

                                        Diagram.BackgroundColorSelectMenu ->
                                            Item.new
                                                |> Item.withText mainText
                                                |> Item.withItemSettings (Just (ItemSettings.withBackgroundColor (Just color) settings))
                                                |> Item.toLineString

                                        _ ->
                                            currentText |> Maybe.withDefault ""

                                prefix =
                                    currentText
                                        |> Maybe.withDefault ""
                                        |> DiagramUtils.getSpacePrefix

                                updateText =
                                    setAt (Item.getLineNo item) (prefix ++ String.trimLeft text) lines
                                        |> String.join "\n"
                            in
                            case ( model.selectedItem, menu ) of
                                ( Just item_, Diagram.ColorSelectMenu ) ->
                                    Return.andThen (\m -> Return.singleton { m | contextMenu = Maybe.andThen (\c -> Just <| Tuple.mapFirst (\_ -> Diagram.CloseMenu) c) m.contextMenu })
                                        >> Return.andThen (setText updateText)
                                        >> Return.andThen
                                            (selectItem
                                                (Just
                                                    (item_
                                                        |> Item.withItemSettings
                                                            (Item.getItemSettings item_
                                                                |> Maybe.andThen (\s -> Just (ItemSettings.withForegroundColor (Just color) s))
                                                            )
                                                    )
                                                )
                                            )

                                ( Just item_, Diagram.BackgroundColorSelectMenu ) ->
                                    Return.andThen (\m -> Return.singleton { m | contextMenu = Maybe.andThen (\c -> Just <| Tuple.mapFirst (\_ -> Diagram.CloseMenu) c) m.contextMenu })
                                        >> Return.andThen (setText updateText)
                                        >> Return.andThen
                                            (selectItem
                                                (Just
                                                    (item_
                                                        |> Item.withItemSettings
                                                            (Item.getItemSettings item_
                                                                |> Maybe.andThen (\s -> Just (ItemSettings.withBackgroundColor (Just color) s))
                                                            )
                                                    )
                                                )
                                            )

                                _ ->
                                    Return.zero

                FontStyleChanged style ->
                    case model.selectedItem of
                        Just item ->
                            let
                                lines =
                                    Text.lines model.text

                                currentText =
                                    getAt (Item.getLineNo item) lines
                                        |> Maybe.withDefault ""

                                prefix =
                                    currentText
                                        |> DiagramUtils.getSpacePrefix

                                ( text, settings ) =
                                    currentText
                                        |> Item.spiltText

                                updateLine =
                                    Item.new
                                        |> Item.withText (prefix ++ (String.trimLeft text |> FontStyle.apply style))
                                        |> Item.withItemSettings (Just settings)
                                        |> Item.toLineString

                                updateText =
                                    setAt (Item.getLineNo item) updateLine lines
                                        |> String.join "\n"
                            in
                            Return.andThen (setText updateText)

                        Nothing ->
                            Return.zero

                DropFiles files ->
                    Return.andThen <|
                        \m ->
                            Return.return
                                { m | dragStatus = NoDrag }
                                (List.filter (\file -> File.mime file |> String.startsWith "text/") files
                                    |> List.head
                                    |> Maybe.map File.toString
                                    |> Maybe.withDefault (Task.succeed "")
                                    |> Task.perform LoadFile
                                )

                LoadFile file ->
                    if String.isEmpty file then
                        Return.zero

                    else
                        Return.andThen <| \m -> Return.singleton { m | text = Text.fromString file }

                ChangeDragStatus status ->
                    Return.andThen <| \m -> Return.singleton { m | dragStatus = status }

                ToggleDropDownList id ->
                    let
                        activeIndex =
                            if (model.dropDownIndex |> Maybe.withDefault "") == id then
                                Nothing

                            else
                                Just id
                    in
                    Return.andThen <| \m -> Return.singleton { m | dropDownIndex = activeIndex }

                ToggleMiniMap ->
                    Return.andThen <| \m -> Return.singleton { m | showMiniMap = not m.showMiniMap }
           )
