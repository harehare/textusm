module Diagram.View exposing (view)

import Attributes
import Constants
import Css
import Css.Global as Global exposing (global)
import Diagram.BusinessModelCanvas.View as BusinessModelCanvas
import Diagram.ER.View as ER
import Diagram.EmpathyMap.View as EmpathyMap
import Diagram.FourLs.View as FourLs
import Diagram.FreeForm.View as FreeForm
import Diagram.GanttChart.View as GanttChart
import Diagram.Kanban.View as Kanban
import Diagram.KeyboardLayout.Types as KeyboardLayout
import Diagram.KeyboardLayout.View as KeyboardLayout
import Diagram.Kpt.View as Kpt
import Diagram.MindMap.View as MindMap
import Diagram.OpportunityCanvas.View as OpportunityCanvas
import Diagram.Search.Types as SearchModel
import Diagram.Search.View as Search
import Diagram.SequenceDiagram.View as SequenceDiagram
import Diagram.SiteMap.Types as SiteMap
import Diagram.SiteMap.View as SiteMap
import Diagram.StartStopContinue.View as StartStopContinue
import Diagram.Table.View as Table
import Diagram.Types as Diagram exposing (DragStatus(..), Model, Msg(..), SelectedItem, dragStart)
import Diagram.Types.BackgroundImage as BackgroundImage
import Diagram.Types.CardSize as CardSize
import Diagram.Types.Data as DiagramData
import Diagram.Types.Scale as Scale
import Diagram.Types.Settings as DiagramSettings
import Diagram.Types.Type exposing (DiagramType(..))
import Diagram.UseCaseDiagram.View as UseCaseDiagram
import Diagram.UserPersona.View as UserPersona
import Diagram.UserStoryMap.View as UserStoryMap
import Diagram.View.ContextMenu as ContextMenu
import Diagram.View.MiniMap as MiniMap
import Diagram.View.Toolbar as Toolbar
import Events
import Events.Wheel as Wheel
import Html.Events.Extra.Touch as Touch
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Html.Styled.Events as Event
import Html.Styled.Lazy as Lazy
import Json.Decode as D
import List
import List.Extra as ListEx
import Maybe
import Style.Style as Style
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Svg.Styled.Events exposing (onClick)
import Types.Color as Color
import Types.Font as Font
import Types.Item as Item
import Types.Position as Position exposing (Position)
import Types.Property as Property
import Types.Size as Size exposing (Size)
import Utils.Common as Utils
import View.Empty as Empty
import View.Icon as Icon


view : Model -> Html Msg
view model =
    let
        centerPosition : Position
        centerPosition =
            case model.diagramType of
                MindMap ->
                    Tuple.mapBoth (\x -> x + (svgWidth // 3)) (\y -> y + (svgHeight // 3)) model.diagram.position

                ImpactMap ->
                    Tuple.mapBoth (\x -> x + Constants.itemMargin) (\y -> y + (svgHeight // 3)) model.diagram.position

                ErDiagram ->
                    Tuple.mapBoth (\x -> x + (svgWidth // 3)) (\y -> y + (svgHeight // 3)) model.diagram.position

                _ ->
                    model.diagram.position

        mainSvg : Html Msg
        mainSvg =
            Lazy.lazy2 diagramView model.diagramType model

        svgHeight : Int
        svgHeight =
            if model.diagram.isFullscreen then
                Basics.max (Size.getHeight model.diagram.size) (Size.getHeight model.windowSize)

            else
                Size.getHeight model.windowSize

        svgWidth : Int
        svgWidth =
            if model.diagram.isFullscreen then
                Basics.max (Size.getWidth model.diagram.size) (Size.getWidth model.windowSize)

            else
                Size.getWidth model.windowSize
    in
    Html.div
        [ Attr.id "usm-area"
        , Attr.css
            [ Css.position Css.relative
            , Style.heightFull
            , case model.moveState of
                Diagram.BoardMove ->
                    Css.batch [ Css.cursor Css.grabbing ]

                _ ->
                    Css.batch [ Css.cursor Css.grab ]
            , case model.dragStatus of
                NoDrag ->
                    Css.batch []

                DragOver ->
                    Css.batch [ Css.backgroundColor <| Css.rgba 0 0 0 0.3 ]
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
                        [ Css.listStyleType Css.disc
                        , Css.important <| Css.paddingLeft Css.zero
                        ]
                    ]
                ]
            ]
        , if Property.getToolbar model.property |> Maybe.withDefault (model.settings.toolbar |> Maybe.withDefault True) then
            case model.diagramType of
                UserStoryMap ->
                    Lazy.lazy Toolbar.viewColorOnly ToolbarClick

                OpportunityCanvas ->
                    Lazy.lazy Toolbar.viewColorOnly ToolbarClick

                BusinessModelCanvas ->
                    Lazy.lazy Toolbar.viewColorOnly ToolbarClick

                Fourls ->
                    Lazy.lazy Toolbar.viewColorOnly ToolbarClick

                StartStopContinue ->
                    Lazy.lazy Toolbar.viewColorOnly ToolbarClick

                Kpt ->
                    Lazy.lazy Toolbar.viewColorOnly ToolbarClick

                UserPersona ->
                    Lazy.lazy Toolbar.viewColorOnly ToolbarClick

                EmpathyMap ->
                    Lazy.lazy Toolbar.viewColorOnly ToolbarClick

                Kanban ->
                    Lazy.lazy Toolbar.viewColorOnly ToolbarClick

                Freeform ->
                    Lazy.lazy Toolbar.viewForFreeForm ToolbarClick

                _ ->
                    Empty.view

          else
            Empty.view
        , if Property.getZoomControl model.property |> Maybe.withDefault (model.settings.zoomControl |> Maybe.withDefault model.showZoomControl) then
            Lazy.lazy zoomControl
                { isFullscreen = model.diagram.isFullscreen
                , scale = model.settings.scale |> Maybe.withDefault Scale.default |> Scale.toFloat
                , lockEditing = model.settings.lockEditing |> Maybe.withDefault False
                }

          else
            Empty.view
        , Lazy.lazy MiniMap.view
            { diagramSvg = mainSvg
            , diagramType = model.diagramType
            , moveState = model.moveState
            , position = centerPosition
            , scale = model.settings.scale |> Maybe.withDefault Scale.default |> Scale.toFloat
            , showMiniMap = model.showMiniMap
            , svgSize = ( svgWidth, svgHeight )
            , viewport = model.windowSize
            }
        , Lazy.lazy4 svgView model centerPosition ( svgWidth, svgHeight ) mainSvg
        , if SearchModel.isSearch model.search then
            Html.div
                [ Attr.css
                    [ Css.position Css.absolute
                    , Css.top <| Css.px 62
                    , Css.right <| Css.px 32
                    ]
                ]
                [ Search.view
                    { closeMsg = ToggleSearch
                    , count = Item.count Item.isHighlight model.items
                    , query = SearchModel.toString model.search
                    , searchMsg = Search
                    }
                ]

          else
            Empty.view
        ]


diagramView : DiagramType -> Model -> Svg Msg
diagramView diagramType model =
    case diagramType of
        UserStoryMap ->
            UserStoryMap.view
                { data = model.data
                , settings = model.settings
                , selectedItem = model.selectedItem
                , property = model.property
                , diagram = model.diagram
                , onEditSelectedItem = EditSelectedItem
                , onEndEditSelectedItem = EndEditSelectedItem
                , onSelect = Select
                , dragStart = dragStart
                }

        OpportunityCanvas ->
            OpportunityCanvas.view
                { items = model.items
                , data = model.data
                , settings = model.settings
                , selectedItem = model.selectedItem
                , property = model.property
                , onEditSelectedItem = EditSelectedItem
                , onEndEditSelectedItem = EndEditSelectedItem
                , onSelect = Select
                , dragStart = dragStart
                }

        BusinessModelCanvas ->
            BusinessModelCanvas.view
                { items = model.items
                , data = model.data
                , settings = model.settings
                , selectedItem = model.selectedItem
                , property = model.property
                , onEditSelectedItem = EditSelectedItem
                , onEndEditSelectedItem = EndEditSelectedItem
                , onSelect = Select
                , dragStart = dragStart
                }

        Fourls ->
            FourLs.view
                { items = model.items
                , data = model.data
                , settings = model.settings
                , selectedItem = model.selectedItem
                , property = model.property
                , onEditSelectedItem = EditSelectedItem
                , onEndEditSelectedItem = EndEditSelectedItem
                , onSelect = Select
                , dragStart = dragStart
                }

        StartStopContinue ->
            StartStopContinue.view
                { items = model.items
                , data = model.data
                , settings = model.settings
                , selectedItem = model.selectedItem
                , property = model.property
                , onEditSelectedItem = EditSelectedItem
                , onEndEditSelectedItem = EndEditSelectedItem
                , onSelect = Select
                , dragStart = dragStart
                }

        Kpt ->
            Kpt.view
                { items = model.items
                , data = model.data
                , settings = model.settings
                , selectedItem = model.selectedItem
                , property = model.property
                , onEditSelectedItem = EditSelectedItem
                , onEndEditSelectedItem = EndEditSelectedItem
                , onSelect = Select
                , dragStart = dragStart
                }

        UserPersona ->
            UserPersona.view
                { items = model.items
                , data = model.data
                , settings = model.settings
                , selectedItem = model.selectedItem
                , property = model.property
                , onEditSelectedItem = EditSelectedItem
                , onEndEditSelectedItem = EndEditSelectedItem
                , onSelect = Select
                , dragStart = dragStart
                }

        MindMap ->
            MindMap.view
                { data = model.data
                , settings = model.settings
                , selectedItem = model.selectedItem
                , property = model.property
                , viewType = MindMap.MindMap
                , diagram = model.diagram
                , moveState = model.moveState
                , onEditSelectedItem = EditSelectedItem
                , onEndEditSelectedItem = EndEditSelectedItem
                , onSelect = Select
                , dragStart = dragStart
                }

        EmpathyMap ->
            EmpathyMap.view
                { items = model.items
                , data = model.data
                , settings = model.settings
                , selectedItem = model.selectedItem
                , property = model.property
                , onEditSelectedItem = EditSelectedItem
                , onEndEditSelectedItem = EndEditSelectedItem
                , onSelect = Select
                , dragStart = dragStart
                }

        SiteMap ->
            SiteMap.view
                { items = model.items
                , data = model.data
                , settings = model.settings
                , selectedItem = model.selectedItem
                , property = model.property
                , diagram = model.diagram
                , onEditSelectedItem = EditSelectedItem
                , onEndEditSelectedItem = EndEditSelectedItem
                , onSelect = Select
                , dragStart = dragStart
                }

        GanttChart ->
            GanttChart.view
                { data = model.data
                , settings = model.settings
                }

        ImpactMap ->
            MindMap.view
                { data = model.data
                , settings = model.settings
                , selectedItem = model.selectedItem
                , property = model.property
                , viewType = MindMap.ImpactMap
                , diagram = model.diagram
                , moveState = model.moveState
                , onEditSelectedItem = EditSelectedItem
                , onEndEditSelectedItem = EndEditSelectedItem
                , onSelect = Select
                , dragStart = dragStart
                }

        ErDiagram ->
            ER.view
                { data = model.data
                , settings = model.settings
                , moveState = model.moveState
                , windowSize = model.windowSize
                , dragStart = dragStart
                }

        Kanban ->
            Kanban.view
                { data = model.data
                , settings = model.settings
                , selectedItem = model.selectedItem
                , property = model.property
                , onEditSelectedItem = EditSelectedItem
                , onEndEditSelectedItem = EndEditSelectedItem
                , onSelect = Select
                , dragStart = dragStart
                }

        Table ->
            Table.view
                { data = model.data
                , settings = model.settings
                , selectedItem = model.selectedItem
                , property = model.property
                , onEditSelectedItem = EditSelectedItem
                , onEndEditSelectedItem = EndEditSelectedItem
                , onSelect = Select
                }

        SequenceDiagram ->
            SequenceDiagram.view
                { data = model.data
                , settings = model.settings
                , selectedItem = model.selectedItem
                , property = model.property
                , onEditSelectedItem = EditSelectedItem
                , onEndEditSelectedItem = EndEditSelectedItem
                , onSelect = Select
                , dragStart = dragStart
                }

        Freeform ->
            FreeForm.view
                { items = model.items
                , data = model.data
                , settings = model.settings
                , selectedItem = model.selectedItem
                , property = model.property
                , moveState = model.moveState
                , onEditSelectedItem = EditSelectedItem
                , onEndEditSelectedItem = EndEditSelectedItem
                , onSelect = Select
                , dragStart = dragStart
                }

        UseCaseDiagram ->
            UseCaseDiagram.view
                { data = model.data
                , settings = model.settings
                , property = model.property
                , onSelect = Select
                }

        KeyboardLayout ->
            KeyboardLayout.view
                { data = model.data
                , settings = model.settings
                , selectedItem = model.selectedItem
                , property = model.property
                , onEditSelectedItem = EditSelectedItem
                , onEndEditSelectedItem = EndEditSelectedItem
                , onSelect = Select
                }


highlightDefs : Svg msg
highlightDefs =
    Svg.filter [ SvgAttr.x "0", SvgAttr.y "0", SvgAttr.width "1", SvgAttr.height "1", SvgAttr.id "highlight" ]
        [ Svg.feFlood [ SvgAttr.floodColor "yellow" ] []
        , Svg.feComposite [ SvgAttr.in_ "SourceGraphic", SvgAttr.operator "xor" ] []
        ]


onTouchNotMove : Svg.Attribute Msg
onTouchNotMove =
    Attr.style "" ""


onMultiTouchMove : Maybe Float -> List Touch.Touch -> Msg
onMultiTouchMove distance changedTouches =
    let
        p1 : ( Float, Float )
        p1 =
            ListEx.getAt 0 changedTouches
                |> Maybe.map .pagePos
                |> Maybe.withDefault ( 0.0, 0.0 )

        p2 : ( Float, Float )
        p2 =
            ListEx.getAt 1 changedTouches
                |> Maybe.map .pagePos
                |> Maybe.withDefault ( 0.0, 0.0 )
    in
    distance
        |> Maybe.map
            (\x ->
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
            )
        |> Maybe.withDefault (StartPinch (Utils.calcDistance p1 p2))


onTouchDrag : Maybe Float -> Diagram.MoveState -> Svg.Attribute Msg
onTouchDrag distance moveState =
    case moveState of
        Diagram.NotMove ->
            onTouchNotMove

        _ ->
            Attr.fromUnstyled <|
                Touch.onMove <|
                    \event ->
                        if List.length event.changedTouches > 1 then
                            onMultiTouchMove distance event.changedTouches

                        else
                            touchCoordinates event
                                |> Tuple.mapBoth round round
                                |> Move False


onDragMove : Diagram.MoveState -> Svg.Attribute Msg
onDragMove moveState =
    case moveState of
        Diagram.NotMove ->
            Attr.style "" ""

        _ ->
            Events.onMouseMove <|
                \event ->
                    let
                        ( x, y ) =
                            event.pagePos
                    in
                    Move False ( round x, round y )


onTouchDragStart : SelectedItem -> Svg.Attribute Msg
onTouchDragStart item =
    case item of
        Nothing ->
            Attr.fromUnstyled <|
                Touch.onStart <|
                    \event ->
                        if List.length event.changedTouches > 1 then
                            let
                                p1 : ( Float, Float )
                                p1 =
                                    ListEx.getAt 0 event.changedTouches
                                        |> Maybe.map .pagePos
                                        |> Maybe.withDefault ( 0.0, 0.0 )

                                p2 : ( Float, Float )
                                p2 =
                                    ListEx.getAt 1 event.changedTouches
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

        _ ->
            Attr.style "" ""


onDragStart : SelectedItem -> Svg.Attribute Msg
onDragStart item =
    case item of
        Nothing ->
            Events.onMouseDown <|
                \event ->
                    let
                        ( x, y ) =
                            event.pagePos
                    in
                    Start Diagram.BoardMove ( round x, round y )

        _ ->
            Attr.style "" ""


backgroundImageStyle : Property.Property -> Svg.Attribute Msg
backgroundImageStyle property =
    case Property.getBackgroundImage property of
        Just image ->
            SvgAttr.style <| "background-image: url(" ++ BackgroundImage.toString image ++ ")"

        Nothing ->
            SvgAttr.style ""


widthStyle : { svgSize : Size, windowSize : Size, isFullscreen : Bool } -> Svg.Attribute Msg
widthStyle { svgSize, windowSize, isFullscreen } =
    SvgAttr.width
        (String.fromInt
            (if Utils.isPhone (Size.getWidth windowSize) || isFullscreen then
                Size.getWidth svgSize

             else if Size.getWidth windowSize - 56 > 0 then
                Size.getWidth windowSize - 56

             else
                0
            )
        )


heightStyle : { svgSize : Size, windowSize : Size, isFullscreen : Bool } -> Svg.Attribute Msg
heightStyle { svgSize, windowSize, isFullscreen } =
    SvgAttr.height
        (String.fromInt <|
            if isFullscreen then
                Size.getHeight svgSize

            else
                Size.getHeight windowSize
        )


svgView : Model -> Position -> Size -> Svg Msg -> Svg Msg
svgView model centerPosition (( svgWidth, svgHeight ) as svgSize) mainSvg =
    Svg.svg
        [ Attr.id "usm"
        , Attributes.dataTest "diagram"
        , backgroundImageStyle model.property
        , widthStyle { svgSize = svgSize, windowSize = model.windowSize, isFullscreen = model.diagram.isFullscreen }
        , heightStyle { svgSize = svgSize, windowSize = model.windowSize, isFullscreen = model.diagram.isFullscreen }
        , SvgAttr.viewBox ("0 0 " ++ String.fromInt svgWidth ++ " " ++ String.fromInt svgHeight)
        , DiagramSettings.getBackgroundColor model.settings model.property
            |> Color.toString
            |> Attr.style "background-color"
        , case model.selectedItem of
            Just _ ->
                Attr.style "" ""

            Nothing ->
                Wheel.onWheel <| Diagram.moveOrZoom model.moveState Scale.step
        , onDragStart model.selectedItem
        , onTouchDragStart model.selectedItem
        , onDragMove model.moveState
        , onTouchDrag model.touchDistance model.moveState
        ]
        [ if String.isEmpty (Font.name model.settings.font) then
            Svg.defs [] [ highlightDefs ]

          else
            Svg.defs [] [ highlightDefs, Svg.style [] [ Svg.text ("@import url('" ++ Font.url model.settings.font ++ "'&display=swap');") ] ]
        , Svg.defs []
            [ Svg.filter [ SvgAttr.id "shadow", SvgAttr.height "120%" ]
                [ Svg.feGaussianBlur [ SvgAttr.in_ "SourceAlpha", SvgAttr.stdDeviation "2" ] []
                , Svg.feOffset [ SvgAttr.dx "3", SvgAttr.dy "3", SvgAttr.result "offsetblur" ] []
                , Svg.feComponentTransfer []
                    [ Svg.feFuncA [ SvgAttr.type_ "linear", SvgAttr.slope "0.3" ] [] ]
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
                    , SvgAttr.fill <| Color.toString (model.settings.color.text |> Maybe.withDefault model.settings.color.label)
                    ]
                    [ Svg.text (Property.getTitle model.property |> Maybe.withDefault "") ]

            _ ->
                Svg.g [] []
        , if model.settings.showGrid |> Maybe.withDefault False then
            Svg.g []
                [ Svg.pattern
                    [ SvgAttr.id "pattern"
                    , SvgAttr.x "0"
                    , SvgAttr.y "0"
                    , SvgAttr.width "24"
                    , SvgAttr.height "24"
                    , SvgAttr.patternUnits "userSpaceOnUse"
                    , SvgAttr.patternTransform "translate(-1,-1)"
                    ]
                    [ Svg.circle [ SvgAttr.cx "1", SvgAttr.cy "1", SvgAttr.r "1", SvgAttr.fill "#e2e5e9" ] []
                    ]
                , Svg.rect
                    [ SvgAttr.id "pattern-rect"
                    , SvgAttr.x "-4"
                    , SvgAttr.y "-4"
                    , SvgAttr.width "100%"
                    , SvgAttr.height "100%"
                    , SvgAttr.fill "url(#pattern)"
                    , SvgAttr.transform <|
                        "scale("
                            ++ String.fromFloat
                                ((model.settings.scale |> Maybe.withDefault Scale.default) |> Scale.toFloat)
                            ++ ","
                            ++ String.fromFloat
                                ((model.settings.scale |> Maybe.withDefault Scale.default) |> Scale.toFloat)
                            ++ ")"
                    ]
                    []
                ]

          else
            Svg.text ""
        , Svg.g
            [ SvgAttr.transform <|
                "translate("
                    ++ String.fromInt (Position.getX centerPosition)
                    ++ ","
                    ++ String.fromInt (Position.getY centerPosition)
                    ++ ") scale("
                    ++ String.fromFloat
                        ((model.settings.scale |> Maybe.withDefault Scale.default) |> Scale.toFloat)
                    ++ ","
                    ++ String.fromFloat
                        ((model.settings.scale |> Maybe.withDefault Scale.default) |> Scale.toFloat)
                    ++ ")"
            , SvgAttr.fill <| Color.toString model.settings.backgroundColor
            , SvgAttr.style "will-change: transform;"
            ]
            [ mainSvg ]
        , case ( model.selectedItem, model.contextMenu ) of
            ( Just item_, Just { contextMenu, position, displayAllMenu } ) ->
                let
                    contextMenuPosition : ( Int, Int )
                    contextMenuPosition =
                        if Item.isVerticalLine item_ then
                            ( floor <| toFloat (Position.getX pos) * Scale.toFloat (model.settings.scale |> Maybe.withDefault Scale.default)
                            , floor <| toFloat (Position.getY pos + h + 24) * Scale.toFloat (model.settings.scale |> Maybe.withDefault Scale.default)
                            )

                        else if Item.isHorizontalLine item_ then
                            ( floor <| toFloat (Position.getX pos) * Scale.toFloat (model.settings.scale |> Maybe.withDefault Scale.default)
                            , floor <| toFloat (Position.getY pos + h + 8) * Scale.toFloat (model.settings.scale |> Maybe.withDefault Scale.default)
                            )

                        else if Item.isCanvas item_ then
                            ( floor <| toFloat (Position.getX position) * Scale.toFloat (model.settings.scale |> Maybe.withDefault Scale.default)
                            , floor <| toFloat (Position.getY position) * Scale.toFloat (model.settings.scale |> Maybe.withDefault Scale.default)
                            )

                        else
                            ( floor <| toFloat (Position.getX pos) * Scale.toFloat (model.settings.scale |> Maybe.withDefault Scale.default)
                            , floor <| toFloat (Position.getY pos + h) * Scale.toFloat (model.settings.scale |> Maybe.withDefault Scale.default)
                            )

                    ( _, h ) =
                        Item.getSize item_ ( CardSize.toInt model.settings.size.width, CardSize.toInt model.settings.size.height )

                    pos : Position
                    pos =
                        Item.getPosition item_ <| Position.concat position centerPosition
                in
                (if displayAllMenu then
                    ContextMenu.viewAllMenu

                 else
                    ContextMenu.viewColorMenuOnly
                )
                    { state = contextMenu
                    , item = item_
                    , settings = model.settings
                    , property = model.property
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


touchCoordinates : Touch.Event -> ( Float, Float )
touchCoordinates touchEvent =
    List.head touchEvent.changedTouches
        |> Maybe.map .clientPos
        |> Maybe.withDefault ( 0, 0 )


zoomControl : { isFullscreen : Bool, scale : Float, lockEditing : Bool } -> Html Msg
zoomControl { isFullscreen, scale, lockEditing } =
    let
        s : Int
        s =
            round <| scale * 100.0
    in
    Html.div
        [ Attr.id "zoom-control"
        , Attr.css
            [ Css.position Css.absolute
            , Css.alignItems Css.center
            , Css.displayFlex
            , Css.justifyContent Css.spaceBetween
            , Css.top <| Css.px 16
            , Css.right <| Css.px 32
            , Css.width <| Css.px 240
            , Css.backgroundColor <| Css.hex <| Color.toString Color.white2
            , Style.roundedSm
            , Css.padding2 (Css.px 8) (Css.px 16)
            , Css.border3 (Css.px 1) Css.solid (Css.rgba 0 0 0 0.1)
            ]
        ]
        [ Html.div
            [ Attr.css
                [ Css.width <| Css.px 24
                , Css.height <| Css.px 24
                , Css.cursor Css.pointer
                , Css.displayFlex
                , Css.alignItems Css.center
                ]
            , onClick ToggleSearch
            ]
            [ Icon.search (Color.toString Color.disabledIconColor) 18
            ]
        , Html.div
            [ Attr.css
                [ Css.width <| Css.px 24
                , Css.height <| Css.px 24
                , Css.cursor Css.pointer
                , Css.displayFlex
                , Css.alignItems Css.center
                ]
            , onClick FitToWindow
            ]
            [ Icon.expandAlt 14
            ]
        , Html.div
            [ Attr.css
                [ Css.width <| Css.px 24
                , Css.height <| Css.px 24
                , Css.cursor Css.pointer
                , Css.displayFlex
                , Css.alignItems Css.center
                ]
            , onClick ToggleMiniMap
            ]
            [ Icon.map 14
            ]
        , Html.div
            [ Attr.css
                [ Css.width <| Css.px 24
                , Css.height <| Css.px 24
                , Css.cursor Css.pointer
                ]
            , onClick <| ZoomOut Scale.step
            ]
            [ Icon.remove 24
            ]
        , Html.div
            [ Attr.css
                [ Css.fontSize <| Css.rem 0.7
                , Css.color <| Css.hex <| Color.toString Color.labelDefalut
                , Css.cursor Css.pointer
                , Css.fontWeight <| Css.int 600
                , Css.width <| Css.px 32
                ]
            ]
            [ Html.text (String.fromInt s ++ "%")
            ]
        , Html.div
            [ Attr.css
                [ Css.width <| Css.px 24
                , Css.height <| Css.px 24
                , Css.cursor Css.pointer
                ]
            , onClick <| ZoomIn Scale.step
            ]
            [ Icon.add 24
            ]
        , Html.div
            [ Attr.css
                [ Css.width <| Css.px 24
                , Css.height <| Css.px 16
                , Css.cursor Css.pointer
                , Css.textAlign Css.center
                ]
            , onClick ToggleEdit
            ]
            [ if lockEditing then
                Icon.lock Color.disabledIconColor 16

              else
                Icon.lockOpen Color.disabledIconColor 16
            ]
        , Html.div
            [ Attr.css
                [ Css.width <| Css.px 24
                , Css.height <| Css.px 24
                , Css.cursor Css.pointer
                ]
            , onClick ToggleFullscreen
            ]
            [ if isFullscreen then
                Icon.fullscreenExit 24

              else
                Icon.fullscreen 24
            ]
        ]
