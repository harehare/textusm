module Components.Diagram exposing (init, update, view)

import Browser.Dom as Dom
import Constants
import Css
    exposing
        ( absolute
        , alignItems
        , backgroundColor
        , border3
        , center
        , color
        , cursor
        , disc
        , displayFlex
        , fontWeight
        , grab
        , grabbing
        , height
        , hex
        , important
        , int
        , justifyContent
        , listStyleType
        , padding2
        , pointer
        , position
        , px
        , relative
        , rem
        , rgba
        , right
        , solid
        , spaceBetween
        , top
        , width
        )
import Css.Global as Global exposing (global)
import Events
import File
import Graphql.Enum.Diagram exposing (Diagram(..))
import Html.Events.Extra.Touch as Touch
import Html.Styled as Html exposing (Html, div)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Event
import Html.Styled.Lazy as Lazy
import Json.Decode as D
import List
import List.Extra exposing (getAt, setAt)
import Maybe
import Models.Color as Color
import Models.Diagram as Diagram exposing (DragStatus(..), Model, Msg(..), SelectedItem)
import Models.Diagram.BusinessModelCanvas as BusinessModelCanvasModel
import Models.Diagram.ER as ErDiagramModel
import Models.Diagram.EmpathyMap as EmpathyMapModel
import Models.Diagram.FourLs as FourLsModel
import Models.Diagram.FreeForm as FreeFormModel
import Models.Diagram.GanttChart as GanttChartModel
import Models.Diagram.Kanban as KanbanModel
import Models.Diagram.Kpt as KptModel
import Models.Diagram.OpportunityCanvas as OpportunityCanvasModel
import Models.Diagram.SequenceDiagram as SequenceDiagramModel
import Models.Diagram.StartStopContinue as StartStopContinueModel
import Models.Diagram.Table as TableModel
import Models.Diagram.UseCaseDiagram as UseCaseDiagramModel
import Models.Diagram.UserPersona as UserPersonaModel
import Models.Diagram.UserStoryMap as UserStoryMapModel
import Models.DiagramData as DiagramData
import Models.DiagramSettings as DiagramSettings
import Models.FontStyle as FontStyle
import Models.Item as Item exposing (Item)
import Models.ItemSettings as ItemSettings
import Models.Position as Position exposing (Position)
import Models.Property as Property
import Models.Size as Size exposing (Size)
import Models.Text as Text
import Return exposing (Return)
import Style.Style as Style
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Svg.Styled.Events exposing (onClick)
import Task
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
import Views.Diagram.Toolbar as Toolbar
import Views.Diagram.UseCaseDiagram as UseCaseDiagram
import Views.Diagram.UserPersona as UserPersona
import Views.Diagram.UserStoryMap as UserStoryMap
import Views.Empty as Empty
import Views.Icon as Icon


init : DiagramSettings.Settings -> Return Msg Model
init settings =
    Return.singleton
        { items = Item.empty
        , data = DiagramData.Empty
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
        , property = Property.empty
        }


zoomControl : Bool -> Float -> Html Msg
zoomControl isFullscreen scale =
    let
        s : Int
        s =
            round <| scale * 100.0
    in
    div
        [ Attr.id "zoom-control"
        , css
            [ position absolute
            , alignItems center
            , displayFlex
            , justifyContent spaceBetween
            , top <| px 16
            , right <| px 16
            , width <| px 240
            , backgroundColor <| hex <| Color.toString Color.white2
            , Style.roundedSm
            , padding2 (px 8) (px 16)
            , border3 (px 1) solid (rgba 0 0 0 0.1)
            ]
        ]
        [ div
            [ css
                [ width <| px 24
                , height <| px 24
                , cursor pointer
                , displayFlex
                , alignItems center
                ]
            , onClick FitToWindow
            ]
            [ Icon.expandAlt 14
            ]
        , div
            [ css
                [ width <| px 24
                , height <| px 24
                , cursor pointer
                , displayFlex
                , alignItems center
                ]
            , onClick ToggleMiniMap
            ]
            [ Icon.map 14
            ]
        , div
            [ css
                [ width <| px 24
                , height <| px 24
                , cursor pointer
                ]
            , onClick <| ZoomOut 0.01
            ]
            [ Icon.remove 24
            ]
        , div
            [ css
                [ Css.fontSize <| rem 0.7
                , color <| hex <| Color.toString Color.labelDefalut
                , cursor pointer
                , fontWeight <| int 600
                , width <| px 32
                ]
            ]
            [ Html.text (String.fromInt s ++ "%")
            ]
        , div
            [ css
                [ width <| px 24
                , height <| px 24
                , cursor pointer
                ]
            , onClick <| ZoomIn 0.01
            ]
            [ Icon.add 24
            ]
        , div
            [ css
                [ width <| px 24
                , height <| px 24
                , cursor pointer
                ]
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
        svgWidth : Int
        svgWidth =
            if model.fullscreen then
                Basics.toFloat
                    (Basics.max model.svg.width (Size.getWidth model.size))
                    |> round

            else
                Basics.toFloat
                    (Size.getWidth model.size)
                    |> round

        svgHeight : Int
        svgHeight =
            if model.fullscreen then
                Basics.toFloat
                    (Basics.max model.svg.height (Size.getHeight model.size))
                    |> round

            else
                Basics.toFloat
                    (Size.getHeight model.size)
                    |> round

        centerPosition : Position
        centerPosition =
            case model.diagramType of
                MindMap ->
                    Tuple.mapBoth (\x -> x + (svgWidth // 3)) (\y -> y + (svgHeight // 3)) model.position

                ImpactMap ->
                    Tuple.mapBoth (\x -> x + Constants.itemMargin) (\y -> y + (svgHeight // 3)) model.position

                ErDiagram ->
                    Tuple.mapBoth (\x -> x + (svgWidth // 3)) (\y -> y + (svgHeight // 3)) model.position

                _ ->
                    model.position

        mainSvg : Html Msg
        mainSvg =
            Lazy.lazy (diagramView model.diagramType) model
    in
    div
        [ Attr.id "usm-area"
        , css
            [ position relative
            , Style.heightFull
            , case model.moveState of
                Diagram.BoardMove ->
                    Css.batch [ cursor grabbing ]

                _ ->
                    Css.batch [ cursor grab ]
            , case model.dragStatus of
                DragOver ->
                    Css.batch [ backgroundColor <| rgba 0 0 0 0.3 ]

                NoDrag ->
                    Css.batch []
            ]
        , Events.onDrop DropFiles
        , Events.onMouseUp <| \_ -> Stop
        , Event.preventDefaultOn "dragover" <|
            D.succeed ( ChangeDragStatus DragOver, True )
        , Event.preventDefaultOn "dragleave" <|
            D.succeed ( ChangeDragStatus NoDrag, True )
        ]
        [ global
            [ Global.class "md-content"
                [ Style.paddingSm
                , Global.children
                    [ Global.typeSelector "li"
                        [ listStyleType disc
                        , important <| Css.paddingLeft Css.zero
                        ]
                    ]
                ]
            ]
        , case model.diagramType of
            Freeform ->
                Lazy.lazy Toolbar.viewForFreeForm ToolbarClick

            _ ->
                Empty.view
        , if Property.getZoomControl model.property |> Maybe.withDefault (model.settings.zoomControl |> Maybe.withDefault model.showZoomControl) then
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
            , moveState = model.moveState
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

        UseCaseDiagram ->
            UseCaseDiagram.view


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
        , Property.getBackgroundColor model.property
            |> Maybe.map Color.toString
            |> Maybe.withDefault model.settings.backgroundColor
            |> Attr.style "background-color"
        , case model.selectedItem of
            Just _ ->
                Attr.style "" ""

            Nothing ->
                Events.onWheel <| Diagram.chooseZoom 0.01
        , onDragStart model.selectedItem (Utils.isPhone <| Size.getWidth model.size)
        , onDragMove model.touchDistance model.moveState (Utils.isPhone <| Size.getWidth model.size)
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
            DiagramData.UserStoryMap _ ->
                Svg.text_
                    [ SvgAttr.x "8"
                    , SvgAttr.y "8"
                    , SvgAttr.fontSize "12"
                    , SvgAttr.fontFamily <| DiagramSettings.fontStyle model.settings
                    , SvgAttr.fill (model.settings.color.text |> Maybe.withDefault model.settings.color.label)
                    ]
                    [ Svg.text (Property.getTitle model.property |> Maybe.withDefault "") ]

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
            ( Just item_, Just { contextMenu, position, displayAllMenu } ) ->
                let
                    pos : Position
                    pos =
                        Item.getPosition item_ <| Position.concat position centerPosition

                    ( _, h ) =
                        Item.getSize item_ ( model.settings.size.width, model.settings.size.height )

                    contextMenuPosition =
                        if Item.isVerticalLine item_ then
                            ( floor <| toFloat (Position.getX pos) * model.svg.scale
                            , floor <| toFloat (Position.getY pos + h + 24) * model.svg.scale
                            )

                        else if Item.isHorizontalLine item_ then
                            ( floor <| toFloat (Position.getX pos) * model.svg.scale
                            , floor <| toFloat (Position.getY pos + h + 8) * model.svg.scale
                            )

                        else if Item.isCanvas item_ then
                            ( floor <| toFloat (Position.getX position) * model.svg.scale
                            , floor <| toFloat (Position.getY position) * model.svg.scale
                            )

                        else
                            ( floor <| toFloat (Position.getX pos) * model.svg.scale
                            , floor <| toFloat (Position.getY pos + h + 8) * model.svg.scale
                            )
                in
                (if displayAllMenu then
                    ContextMenu.viewAllMenu

                 else
                    ContextMenu.viewColorMenuOnly
                )
                    { state = contextMenu
                    , item = item_
                    , settings = model.settings
                    , position = contextMenuPosition
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
            Attr.fromUnstyled <|
                Touch.onStart <|
                    \event ->
                        if List.length event.changedTouches > 1 then
                            let
                                p1 : ( Float, Float )
                                p1 =
                                    getAt 0 event.changedTouches
                                        |> Maybe.map .pagePos
                                        |> Maybe.withDefault ( 0.0, 0.0 )

                                p2 : ( Float, Float )
                                p2 =
                                    getAt 1 event.changedTouches
                                        |> Maybe.map .pagePos
                                        |> Maybe.withDefault ( 0.0, 0.0 )
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
            Attr.fromUnstyled <|
                Touch.onMove <|
                    \event ->
                        if List.length event.changedTouches > 1 then
                            let
                                p1 : ( Float, Float )
                                p1 =
                                    getAt 0 event.changedTouches
                                        |> Maybe.map .pagePos
                                        |> Maybe.withDefault ( 0.0, 0.0 )

                                p2 : ( Float, Float )
                                p2 =
                                    getAt 1 event.changedTouches
                                        |> Maybe.map .pagePos
                                        |> Maybe.withDefault ( 0.0, 0.0 )
                            in
                            case distance of
                                Just x ->
                                    let
                                        newDistance : Float
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

        data : DiagramData.DiagramData
        data =
            case base.diagramType of
                UserStoryMap ->
                    DiagramData.UserStoryMap <| UserStoryMapModel.from text hierarchy items

                Table ->
                    DiagramData.Table <| TableModel.from items

                Kpt ->
                    DiagramData.Kpt <| KptModel.from items

                BusinessModelCanvas ->
                    DiagramData.BusinessModelCanvas <| BusinessModelCanvasModel.from items

                EmpathyMap ->
                    DiagramData.EmpathyMap <| EmpathyMapModel.from items

                Fourls ->
                    DiagramData.FourLs <| FourLsModel.from items

                Kanban ->
                    DiagramData.Kanban <| KanbanModel.from items

                OpportunityCanvas ->
                    DiagramData.OpportunityCanvas <| OpportunityCanvasModel.from items

                StartStopContinue ->
                    DiagramData.StartStopContinue <| StartStopContinueModel.from items

                UserPersona ->
                    DiagramData.UserPersona <| UserPersonaModel.from items

                ErDiagram ->
                    DiagramData.ErDiagram <| ErDiagramModel.from items

                MindMap ->
                    DiagramData.MindMap items hierarchy

                ImpactMap ->
                    DiagramData.ImpactMap items hierarchy

                SiteMap ->
                    DiagramData.SiteMap items hierarchy

                SequenceDiagram ->
                    DiagramData.SequenceDiagram <| SequenceDiagramModel.from items

                Freeform ->
                    DiagramData.FreeForm <| FreeFormModel.from items

                GanttChart ->
                    DiagramData.GanttChart <| GanttChartModel.from items

                UseCaseDiagram ->
                    DiagramData.UseCaseDiagram <| UseCaseDiagramModel.from items

        newModel : Model
        newModel =
            { base | items = items, data = data }

        ( svgWidth, svgHeight ) =
            Diagram.size newModel
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
        , property = Property.fromString text
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


move : Position -> Model -> Return Msg Model
move ( x, y ) m =
    case m.moveState of
        Diagram.BoardMove ->
            Return.singleton
                { m
                    | position =
                        ( Position.getX m.position + round (toFloat (x - Position.getX m.movePosition) * m.svg.scale)
                        , Position.getY m.position + round (toFloat (y - Position.getY m.movePosition) * m.svg.scale)
                        )
                    , movePosition = ( x, y )
                }

        Diagram.MiniMapMove ->
            Return.singleton
                { m
                    | position =
                        ( Position.getX m.position - round (toFloat (x - Position.getX m.movePosition) * m.svg.scale * (toFloat (Size.getWidth m.size) / 260.0 * 2.0))
                        , Position.getY m.position - round (toFloat (y - Position.getY m.movePosition) * m.svg.scale * (toFloat (Size.getWidth m.size) / 260.0 * 2.0))
                        )
                    , movePosition = ( x, y )
                }

        Diagram.ItemMove target ->
            case target of
                Diagram.TableTarget table ->
                    let
                        (ErDiagramModel.Table name columns position lineNo) =
                            table

                        newPosition : Maybe Position
                        newPosition =
                            Just
                                (position
                                    |> Maybe.andThen
                                        (\p ->
                                            Just
                                                ( Position.getX p + round (toFloat (x - Position.getX m.movePosition) / m.svg.scale)
                                                , Position.getY p + round (toFloat (y - Position.getY m.movePosition) / m.svg.scale)
                                                )
                                        )
                                    |> Maybe.withDefault ( x - Position.getX m.movePosition, y - Position.getY m.movePosition )
                                )
                    in
                    Return.singleton
                        { m
                            | moveState =
                                Diagram.ItemMove <|
                                    Diagram.TableTarget (ErDiagramModel.Table name columns newPosition lineNo)
                            , movePosition = ( x, y )
                        }

                Diagram.ItemTarget item ->
                    let
                        offset : Position
                        offset =
                            Item.getOffset item

                        newPosition : Position
                        newPosition =
                            ( Position.getX offset + round (toFloat (x - Position.getX m.movePosition) / m.svg.scale)
                            , Position.getY offset + round (toFloat (y - Position.getY m.movePosition) / m.svg.scale)
                            )

                        newItem : Item
                        newItem =
                            Item.withOffset newPosition item
                    in
                    Return.singleton
                        { m
                            | moveState =
                                Diagram.ItemMove <|
                                    Diagram.ItemTarget newItem
                            , selectedItem = Just newItem
                            , movePosition = ( x, y )
                        }

        Diagram.ItemResize item direction ->
            let
                offsetPosition : Position
                offsetPosition =
                    Item.getOffset item

                offsetSize : Size
                offsetSize =
                    Item.getOffsetSize item

                ( newSize, newPosition ) =
                    case direction of
                        Diagram.TopLeft ->
                            ( ( Size.getWidth offsetSize + round (toFloat (Position.getX m.movePosition - x) / m.svg.scale)
                              , Size.getHeight offsetSize + round (toFloat (Position.getY m.movePosition - y) / m.svg.scale)
                              )
                            , ( Position.getX offsetPosition + round (toFloat (x - Position.getX m.movePosition) / m.svg.scale)
                              , Position.getY offsetPosition + round (toFloat (y - Position.getY m.movePosition) / m.svg.scale)
                              )
                            )

                        Diagram.TopRight ->
                            ( ( Size.getWidth offsetSize + round (toFloat (x - Position.getX m.movePosition) / m.svg.scale)
                              , Size.getHeight offsetSize + round (toFloat (Position.getY m.movePosition - y) / m.svg.scale)
                              )
                            , ( Position.getX offsetPosition
                              , Position.getY offsetPosition + round (toFloat (y - Position.getY m.movePosition) / m.svg.scale)
                              )
                            )

                        Diagram.BottomLeft ->
                            ( ( Size.getWidth offsetSize + round (toFloat (Position.getX m.movePosition - x) / m.svg.scale)
                              , Size.getHeight offsetSize + round (toFloat (y - Position.getY m.movePosition) / m.svg.scale)
                              )
                            , ( Position.getX offsetPosition + round (toFloat (x - Position.getX m.movePosition) / m.svg.scale)
                              , Position.getY offsetPosition
                              )
                            )

                        Diagram.BottomRight ->
                            ( ( Size.getWidth offsetSize + round (toFloat (x - Position.getX m.movePosition) / m.svg.scale)
                              , Size.getHeight offsetSize + round (toFloat (y - Position.getY m.movePosition) / m.svg.scale)
                              )
                            , offsetPosition
                            )

                        Diagram.Top ->
                            ( ( 0
                              , Size.getHeight offsetSize + round (toFloat (Position.getY m.movePosition - y) / m.svg.scale)
                              )
                            , ( Position.getX offsetPosition, Position.getY offsetPosition + round (toFloat (y - Position.getY m.movePosition) / m.svg.scale) )
                            )

                        Diagram.Bottom ->
                            ( ( 0, Size.getHeight offsetSize + round (toFloat (y - Position.getY m.movePosition) / m.svg.scale) ), offsetPosition )

                        Diagram.Right ->
                            ( ( Size.getWidth offsetSize + round (toFloat (x - Position.getX m.movePosition) / m.svg.scale), 0 ), offsetPosition )

                        Diagram.Left ->
                            ( ( Size.getWidth offsetSize + round (toFloat (Position.getX m.movePosition - x) / m.svg.scale), 0 )
                            , ( Position.getX offsetPosition + round (toFloat (x - Position.getX m.movePosition) / m.svg.scale)
                              , Position.getY offsetPosition
                              )
                            )

                newItem : Item
                newItem =
                    Item.withOffsetSize newSize item
                        |> Item.withOffset newPosition
            in
            Return.singleton
                { m
                    | moveState =
                        Diagram.ItemResize newItem direction
                    , selectedItem = Just newItem
                    , movePosition = ( x, y )
                }

        _ ->
            Return.singleton m


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


zoomIn : Float -> Model -> Return Msg Model
zoomIn ratio model =
    if model.svg.scale <= 10.0 then
        Return.singleton
            { model
                | svg =
                    { width = model.svg.width
                    , height = model.svg.height
                    , scale = model.svg.scale + ratio
                    }
            }

    else
        Return.singleton model


zoomOut : Float -> Model -> Return Msg Model
zoomOut ratio model =
    if model.svg.scale > 0.01 then
        Return.singleton
            { model
                | svg =
                    { width = model.svg.width
                    , height = model.svg.height
                    , scale = model.svg.scale - ratio
                    }
            }

    else
        Return.singleton model


update : Msg -> Return.ReturnF Msg Model
update message =
    case message of
        NoOp ->
            Return.zero

        Init settings window text ->
            Return.andThen (\m -> Return.singleton <| updateDiagram ( round window.viewport.width, round window.viewport.height - 50 ) m text)
                >> Return.andThen (\m -> Return.singleton { m | settings = settings })

        ZoomIn ratio ->
            Return.andThen <| zoomIn ratio

        ZoomOut ratio ->
            Return.andThen <| zoomOut ratio

        PinchIn distance ->
            Return.andThen (setTouchDistance <| Just distance)
                >> Return.andThen (zoomIn 0.01)

        PinchOut distance ->
            Return.andThen (setTouchDistance <| Just distance)
                >> Return.andThen (zoomOut 0.01)

        OnChangeText text ->
            Return.andThen <| \m -> Return.singleton <| updateDiagram m.size m text

        Start moveState pos ->
            Return.andThen <| \m -> Return.singleton { m | moveState = moveState, movePosition = pos }

        Stop ->
            Return.andThen
                (\m ->
                    case m.moveState of
                        Diagram.ItemMove target ->
                            case target of
                                Diagram.TableTarget table ->
                                    let
                                        (ErDiagramModel.Table _ _ _ lineNo) =
                                            table
                                    in
                                    setLine lineNo (Text.lines m.text) (ErDiagramModel.tableToLineString table) m

                                Diagram.ItemTarget item ->
                                    setLine (Item.getLineNo item) (Text.lines m.text) (Item.toLineString item) m

                        Diagram.ItemResize item _ ->
                            setLine (Item.getLineNo item) (Text.lines m.text) (Item.toLineString item) m

                        _ ->
                            Return.singleton m
                )
                >> Return.andThen stopMove

        Move position ->
            Return.andThen <| move position

        MoveTo position ->
            Return.andThen (\m -> Return.singleton { m | position = position })
                >> Return.andThen clearPosition

        ToggleFullscreen ->
            Return.andThen (\m -> Return.singleton { m | fullscreen = not m.fullscreen })
                >> Return.andThen clearPosition

        OnResize width height ->
            Return.andThen (\m -> Return.singleton { m | size = ( width, height - 56 ) })
                >> Return.andThen clearPosition

        StartPinch distance ->
            Return.andThen <| \m -> Return.singleton { m | touchDistance = Just distance }

        EditSelectedItem text ->
            Return.andThen <| \m -> Return.singleton { m | selectedItem = Maybe.andThen (\item_ -> Just (item_ |> Item.withTextOnly (" " ++ String.trimLeft text))) m.selectedItem }

        FitToWindow ->
            Return.andThen <|
                \m ->
                    let
                        ( windowWidth, windowHeight ) =
                            m.size

                        ( canvasWidth, canvasHeight ) =
                            Diagram.size m

                        ( widthRatio, heightRatio ) =
                            ( toFloat (round (toFloat windowWidth / toFloat canvasWidth / 0.05)) * 0.05, toFloat (round (toFloat windowHeight / toFloat canvasHeight / 0.05)) * 0.05 )

                        position : Position
                        position =
                            ( windowWidth // 2 - round (toFloat canvasWidth / 2 * widthRatio), windowHeight // 2 - round (toFloat canvasHeight / 2 * heightRatio) )
                    in
                    m
                        |> Diagram.ofScale.set (min widthRatio heightRatio)
                        |> Diagram.ofPosition.set position
                        |> Return.singleton

        Select (Just { item, position, displayAllMenu }) ->
            Return.andThen (\m -> Return.singleton { m | selectedItem = Just item, contextMenu = Just { contextMenu = Diagram.CloseMenu, position = position, displayAllMenu = displayAllMenu } })
                >> Return.andThen (setFocus "edit-item")

        Select Nothing ->
            Return.andThen <| \m -> Return.singleton { m | selectedItem = Nothing }

        EndEditSelectedItem item ->
            Return.andThen <|
                \m ->
                    m.selectedItem
                        |> Maybe.map
                            (\selectedItem ->
                                let
                                    lines : List String
                                    lines =
                                        Text.lines m.text

                                    prefix : String
                                    prefix =
                                        Text.getLine (Item.getLineNo item) m.text
                                            |> DiagramUtils.getSpacePrefix

                                    text : String
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
                                Return.singleton m
                                    |> Return.andThen (setText text)
                                    |> Return.andThen clearSelectedItem
                            )
                        |> Maybe.withDefault (Return.singleton m)

        SelectContextMenu menu ->
            Return.andThen <|
                \m ->
                    m.contextMenu
                        |> Maybe.map (\contextMenu -> Return.singleton { m | contextMenu = Just { contextMenu | contextMenu = menu } })
                        |> Maybe.withDefault (Return.singleton m)

        FontSizeChanged size ->
            Return.andThen <|
                \m ->
                    m.selectedItem
                        |> Maybe.map
                            (\item ->
                                let
                                    lines : List String
                                    lines =
                                        Text.lines m.text

                                    currentText : String
                                    currentText =
                                        Text.getLine (Item.getLineNo item) m.text

                                    ( mainText, settings, comment ) =
                                        Item.split currentText

                                    text : String
                                    text =
                                        Item.new
                                            |> Item.withText mainText
                                            |> Item.withItemSettings (Just (settings |> ItemSettings.withFontSize size))
                                            |> Item.withComments comment
                                            |> Item.toLineString

                                    updateText : String
                                    updateText =
                                        setAt (Item.getLineNo item) (DiagramUtils.getSpacePrefix currentText ++ String.trimLeft text) lines
                                            |> String.join "\n"
                                in
                                Return.singleton m
                                    |> Return.andThen closeDropDown
                                    |> Return.andThen (setText updateText)
                                    |> Return.andThen
                                        (selectItem
                                            (Just
                                                (item
                                                    |> Item.withItemSettings
                                                        (Item.getItemSettings item
                                                            |> Maybe.andThen (\s -> Just (ItemSettings.withFontSize size <| s))
                                                        )
                                                )
                                            )
                                        )
                            )
                        |> Maybe.withDefault (Return.singleton m)

        ColorChanged menu color ->
            Return.andThen <|
                \m ->
                    m.selectedItem
                        |> Maybe.map
                            (\item ->
                                let
                                    lines : List String
                                    lines =
                                        Text.lines m.text

                                    currentText : String
                                    currentText =
                                        Text.getLine (Item.getLineNo item) m.text

                                    ( mainText, settings, comment ) =
                                        Item.split currentText

                                    text : String
                                    text =
                                        case menu of
                                            Diagram.ColorSelectMenu ->
                                                Item.new
                                                    |> Item.withText mainText
                                                    |> Item.withItemSettings (Just (settings |> ItemSettings.withForegroundColor (Just color)))
                                                    |> Item.withComments comment
                                                    |> Item.toLineString

                                            Diagram.BackgroundColorSelectMenu ->
                                                Item.new
                                                    |> Item.withText mainText
                                                    |> Item.withItemSettings (Just (ItemSettings.withBackgroundColor (Just color) settings))
                                                    |> Item.withComments comment
                                                    |> Item.toLineString

                                            _ ->
                                                currentText

                                    updateText : String
                                    updateText =
                                        setAt (Item.getLineNo item) (DiagramUtils.getSpacePrefix currentText ++ String.trimLeft text) lines
                                            |> String.join "\n"
                                in
                                case ( m.selectedItem, menu ) of
                                    ( Just item_, Diagram.ColorSelectMenu ) ->
                                        case m.contextMenu of
                                            Just menu_ ->
                                                Return.singleton { m | contextMenu = Just { menu_ | contextMenu = Diagram.CloseMenu } }
                                                    |> Return.andThen (setText updateText)
                                                    |> Return.andThen
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

                                            Nothing ->
                                                Return.singleton m

                                    ( Just item_, Diagram.BackgroundColorSelectMenu ) ->
                                        case m.contextMenu of
                                            Just menu_ ->
                                                Return.singleton { m | contextMenu = Just { menu_ | contextMenu = Diagram.CloseMenu } }
                                                    |> Return.andThen (setText updateText)
                                                    |> Return.andThen
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

                                            Nothing ->
                                                Return.singleton m

                                    _ ->
                                        Return.singleton m
                            )
                        |> Maybe.withDefault (Return.singleton m)

        FontStyleChanged style ->
            Return.andThen <|
                \m ->
                    m.selectedItem
                        |> Maybe.map
                            (\item ->
                                let
                                    lines : List String
                                    lines =
                                        Text.lines m.text

                                    currentText : String
                                    currentText =
                                        Text.getLine (Item.getLineNo item) m.text

                                    ( text, settings, comment ) =
                                        Item.split currentText

                                    updateLine : String
                                    updateLine =
                                        Item.new
                                            |> Item.withText (DiagramUtils.getSpacePrefix currentText ++ (String.trimLeft text |> FontStyle.apply style))
                                            |> Item.withItemSettings (Just settings)
                                            |> Item.withComments comment
                                            |> Item.toLineString
                                in
                                setText
                                    (setAt (Item.getLineNo item) updateLine lines
                                        |> String.join "\n"
                                    )
                                    m
                            )
                        |> Maybe.withDefault (Return.singleton m)

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
            Return.andThen <|
                \m ->
                    Return.singleton
                        { m
                            | dropDownIndex =
                                if (m.dropDownIndex |> Maybe.withDefault "") == id then
                                    Nothing

                                else
                                    Just id
                        }

        ToggleMiniMap ->
            Return.andThen <| \m -> Return.singleton { m | showMiniMap = not m.showMiniMap }

        ToolbarClick item ->
            Return.andThen <| \m -> setText (Text.addLine m.text (Item.toLineString item) |> Text.toString) m
