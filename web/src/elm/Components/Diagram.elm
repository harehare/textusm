module Components.Diagram exposing (init, update, view)

import Browser.Dom as Dom
import Constants
import Data.FontStyle as FontStyle
import Data.Item as Item exposing (Item, ItemType(..), Items)
import Data.ItemSettings as ItemSettings
import Data.Position as Position
import Data.Size as Size exposing (Size)
import Data.Text as Text
import Events
import File
import Html exposing (Html, div)
import Html.Attributes as Attr
import Html.Events as Event
import Html.Events.Extra.Mouse as Mouse
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
import Models.Views.Kanban as KanbanModel
import Models.Views.Kpt as KptModel
import Models.Views.OpportunityCanvas as OpportunityCanvasModel
import Models.Views.SequenceDiagram as SequenceDiagramModel
import Models.Views.StartStopContinue as StartStopContinueModel
import Models.Views.Table as TableModel
import Models.Views.UserPersona as UserPersonaModel
import Models.Views.UserStoryMap as UserStoryMapModel
import Ports
import Return as Return exposing (Return)
import String
import Svg exposing (Svg, defs, feComponentTransfer, feFuncA, feGaussianBlur, feMerge, feMergeNode, feOffset, filter, g, svg, text)
import Svg.Attributes exposing (class, dx, dy, fill, height, id, in_, result, slope, stdDeviation, style, transform, type_, viewBox, width)
import Svg.Events exposing (onClick)
import Svg.Lazy exposing (lazy, lazy2)
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
        [ id "zoom-control"
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
            , class ".select-none"
            ]
            [ text (String.fromInt s ++ "%")
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
    div
        [ Attr.id "usm-area"
        , Attr.style "position" "relative"
        , case model.moveState of
            Diagram.BoardMove ->
                Attr.style "cursor" "grabbing"

            _ ->
                Attr.style "cursor" "grab"
        , Events.onDrop DropFiles
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
            lazy2 zoomControl model.fullscreen model.svg.scale

          else
            Empty.view
        , lazy MiniMap.view model
        , lazy svgView model
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


svgView : Model -> Svg Msg
svgView model =
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

        mainSvg =
            lazy (diagramView model.diagramType) model

        centerPosition =
            case model.diagramType of
                MindMap ->
                    Tuple.mapBoth (\x -> x + (svgWidth // 3)) (\y -> y + (svgHeight // 3)) model.position

                ImpactMap ->
                    Tuple.mapBoth (\x -> x + Constants.itemMargin) (\y -> y + (svgHeight // 3)) model.position

                _ ->
                    model.position
    in
    svg
        [ Attr.id "usm"
        , width
            (String.fromInt
                (if Utils.isPhone (Size.getWidth model.size) || model.fullscreen then
                    svgWidth

                 else if Size.getWidth model.size - 56 > 0 then
                    Size.getWidth model.size - 56

                 else
                    0
                )
            )
        , height
            (String.fromInt <|
                if model.fullscreen then
                    svgHeight

                else
                    Size.getHeight model.size
            )
        , viewBox ("0 0 " ++ String.fromInt svgWidth ++ " " ++ String.fromInt svgHeight)
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
            g [] []

          else
            defs []
                [ Svg.style
                    []
                    [ text ("@import url('https://fonts.googleapis.com/css?family=" ++ model.settings.font ++ "&display=swap');") ]
                ]
        , defs []
            [ filter [ id "shadow", height "130%" ]
                [ feGaussianBlur [ in_ "SourceAlpha", stdDeviation "3" ] []
                , feOffset [ dx "2", dy "2", result "offsetblur" ] []
                , feComponentTransfer []
                    [ feFuncA [ type_ "linear", slope "0.5" ] []
                    ]
                , feMerge []
                    [ feMergeNode [] []
                    , feMergeNode [ in_ "SourceGraphic" ] []
                    ]
                ]
            ]
        , g
            [ transform
                ("translate("
                    ++ String.fromInt (Position.getX centerPosition)
                    ++ ","
                    ++ String.fromInt (Position.getY centerPosition)
                    ++ "), scale("
                    ++ String.fromFloat model.svg.scale
                    ++ ","
                    ++ String.fromFloat model.svg.scale
                    ++ ")"
                )
            , fill model.settings.backgroundColor
            , style "will-change: transform;"
            ]
            [ mainSvg ]
        , case ( model.selectedItem, model.contextMenu ) of
            ( Just ( item_, _ ), Just ( contextMenu, position ) ) ->
                let
                    ( posX, posY ) =
                        position

                    ( offsetX, offsetY ) =
                        centerPosition
                in
                ContextMenu.view
                    { state = contextMenu
                    , item = item_
                    , position =
                        ( floor <| toFloat (posX + offsetX) * model.svg.scale
                        , floor <| toFloat (posY + offsetY) * model.svg.scale
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
            Touch.onStart
                (\event ->
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
                )

        ( Nothing, False ) ->
            Mouse.onDown
                (\event ->
                    let
                        ( x, y ) =
                            event.pagePos
                    in
                    Start Diagram.BoardMove ( round x, round y )
                )

        _ ->
            Attr.style "" ""


onDragMove : Maybe Float -> Diagram.MoveState -> Bool -> Svg.Attribute Msg
onDragMove distance moveState isPhone =
    case ( moveState, isPhone ) of
        ( Diagram.NotMove, _ ) ->
            Attr.style "" ""

        ( _, True ) ->
            Touch.onMove
                (\event ->
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
                )

        ( _, False ) ->
            Mouse.onMove
                (\event ->
                    let
                        ( x, y ) =
                            event.pagePos
                    in
                    Move ( round x, round y )
                )


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
                    Diagram.UserStoryMap <| UserStoryMapModel.from text items

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

                _ ->
                    Diagram.Items items

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
        , movePosition = ( 0, 0 )
        , text = Text.edit base.text text
    }


clearPosition : Model -> Return Msg Model
clearPosition model =
    Return.singleton { model | movePosition = ( 0, 0 ) }


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
    let
        text =
            setAt lineNo line lines
                |> String.join "\n"
    in
    setText text model


setItem : Item -> Items -> Model -> Return Msg Model
setItem item items model =
    Return.singleton
        { model
            | items =
                Item.map
                    (\i ->
                        if Item.getLineNo i == Item.getLineNo item then
                            item

                        else
                            i
                    )
                    items
                    |> Item.fromList
        }


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


loadTextToEditor : Model -> Return Msg Model
loadTextToEditor model =
    Return.return model (Ports.loadText <| Text.toString model.text)


update : Msg -> Model -> Return Msg Model
update message model =
    case message of
        NoOp ->
            Return.singleton model

        Init settings window text ->
            let
                width =
                    round window.viewport.width

                height =
                    round window.viewport.height - 50

                model_ =
                    updateDiagram ( width, height ) model text
            in
            Return.singleton { model_ | settings = settings }

        ZoomIn ->
            zoomIn model

        ZoomOut ->
            zoomOut model

        PinchIn distance ->
            Return.singleton { model | touchDistance = Just distance }
                |> Return.andThen zoomIn

        PinchOut distance ->
            Return.singleton { model | touchDistance = Just distance }
                |> Return.andThen zoomOut

        OnChangeText text ->
            Return.singleton <| updateDiagram model.size model text

        Start moveState pos ->
            Return.singleton
                { model
                    | moveState = moveState
                    , movePosition = pos
                }

        Stop ->
            Return.singleton model
                |> (case model.moveState of
                        Diagram.ItemMove target ->
                            (case target of
                                Diagram.TableTarget table ->
                                    let
                                        (ErDiagramModel.Table _ _ _ lineNo) =
                                            table
                                    in
                                    Return.andThen (setLine lineNo (Text.lines model.text) (ErDiagramModel.tableToLineString table))

                                Diagram.ItemTarget item ->
                                    Return.andThen (setLine (Item.getLineNo item) (Text.lines model.text) (Item.toLineString item))
                                        >> Return.andThen (setItem item model.items)
                            )
                                >> Return.andThen loadTextToEditor
                                >> Return.andThen stopMove

                        _ ->
                            Return.zero
                   )
                |> Return.andThen stopMove

        Move ( x, y ) ->
            Return.singleton <|
                if not (Diagram.isMoving model.moveState) || (x == Position.getX model.movePosition && y == Position.getY model.movePosition) then
                    model

                else
                    case model.moveState of
                        Diagram.BoardMove ->
                            { model
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
                                    { model
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
                                    { model
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
                            model

        MoveTo position ->
            Return.singleton { model | position = position }
                |> Return.andThen clearPosition

        ToggleFullscreen ->
            Return.singleton { model | fullscreen = not model.fullscreen }
                |> Return.andThen clearPosition

        OnResize width height ->
            Return.singleton { model | size = ( width, height - 56 ) }
                |> Return.andThen clearPosition

        StartPinch distance ->
            Return.singleton { model | touchDistance = Just distance }

        EditSelectedItem text ->
            Return.singleton { model | selectedItem = Maybe.andThen (\( i, _ ) -> Just ( i |> Item.withTextOnly (" " ++ String.trimLeft text), False )) model.selectedItem }

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
            Return.singleton { model | svg = newSvgModel, position = position }

        Select (Just ( item, position )) ->
            if Item.isImage <| Item.getText item then
                Return.singleton model

            else
                Return.singleton { model | selectedItem = Just ( item, False ), contextMenu = Just ( Diagram.CloseMenu, position ) }
                    |> Return.andThen (setFocus "edit-item")

        Select Nothing ->
            Return.singleton { model | selectedItem = Nothing }

        EndEditSelectedItem item code isComposing ->
            case ( model.selectedItem, code, isComposing ) of
                ( Just ( selectedItem, _ ), 13, False ) ->
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
                    setText text model
                        |> Return.andThen clearSelectedItem

                _ ->
                    Return.singleton model

        SelectContextMenu menu ->
            Return.singleton { model | contextMenu = Maybe.andThen (\c -> Just <| Tuple.mapFirst (\_ -> menu) c) model.contextMenu }

        FontSizeChanged size ->
            case model.selectedItem of
                Nothing ->
                    Return.singleton model

                Just ( item, _ ) ->
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
                        Just ( i, _ ) ->
                            Return.singleton model
                                |> Return.andThen closeDropDown
                                |> Return.andThen (setText updateText)
                                |> Return.andThen
                                    (selectItem
                                        (Just
                                            ( i
                                                |> Item.withItemSettings
                                                    (Item.getItemSettings i
                                                        |> Maybe.andThen (\s -> Just (ItemSettings.withFontSize size <| s))
                                                    )
                                            , False
                                            )
                                        )
                                    )

                        _ ->
                            Return.singleton model

        ColorChanged menu color ->
            case model.selectedItem of
                Nothing ->
                    Return.singleton model

                Just ( item, _ ) ->
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
                        ( Just ( i, _ ), Diagram.ColorSelectMenu ) ->
                            Return.singleton { model | contextMenu = Maybe.andThen (\c -> Just <| Tuple.mapFirst (\_ -> Diagram.CloseMenu) c) model.contextMenu }
                                |> Return.andThen (setText updateText)
                                |> Return.andThen
                                    (selectItem
                                        (Just
                                            ( i
                                                |> Item.withItemSettings
                                                    (Item.getItemSettings i
                                                        |> Maybe.andThen (\s -> Just (ItemSettings.withForegroundColor (Just color) s))
                                                    )
                                            , False
                                            )
                                        )
                                    )

                        ( Just ( i, _ ), Diagram.BackgroundColorSelectMenu ) ->
                            Return.singleton { model | contextMenu = Maybe.andThen (\c -> Just <| Tuple.mapFirst (\_ -> Diagram.CloseMenu) c) model.contextMenu }
                                |> Return.andThen (setText updateText)
                                |> Return.andThen
                                    (selectItem
                                        (Just
                                            ( i
                                                |> Item.withItemSettings
                                                    (Item.getItemSettings i
                                                        |> Maybe.andThen (\s -> Just (ItemSettings.withBackgroundColor (Just color) s))
                                                    )
                                            , False
                                            )
                                        )
                                    )

                        _ ->
                            Return.singleton model

        FontStyleChanged style ->
            case model.selectedItem of
                Just ( item, _ ) ->
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
                    setText updateText model

                Nothing ->
                    Return.singleton model

        DropFiles files ->
            ( { model | dragStatus = NoDrag }
            , List.filter (\file -> File.mime file |> String.startsWith "image/") files
                |> List.map File.toUrl
                |> Task.sequence
                |> Task.perform LoadFiles
            )

        LoadFiles files ->
            Return.return model (Ports.insertTextLines files)

        ChangeDragStatus status ->
            Return.singleton { model | dragStatus = status }

        ToggleDropDownList id ->
            let
                activeIndex =
                    if (model.dropDownIndex |> Maybe.withDefault "") == id then
                        Nothing

                    else
                        Just id
            in
            Return.singleton { model | dropDownIndex = activeIndex }

        ToggleMiniMap ->
            Return.singleton { model | showMiniMap = not model.showMiniMap }
