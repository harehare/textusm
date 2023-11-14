module Components.Diagram exposing (init, update, view)

import Attributes
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
import Events.Wheel as Wheel
import File
import Html.Events.Extra.Touch as Touch
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Html.Styled.Events as Event
import Html.Styled.Lazy as Lazy
import Json.Decode as D
import List
import List.Extra exposing (getAt, setAt)
import Maybe
import Models.Color as Color
import Models.Diagram as Diagram exposing (DragStatus(..), Model, Msg(..), SelectedItem, dragStart)
import Models.Diagram.BackgroundImage as BackgroundImage
import Models.Diagram.BusinessModelCanvas as BusinessModelCanvasModel
import Models.Diagram.Data as DiagramData
import Models.Diagram.ER as ErDiagramModel
import Models.Diagram.EmpathyMap as EmpathyMapModel
import Models.Diagram.FourLs as FourLsModel
import Models.Diagram.FreeForm as FreeFormModel
import Models.Diagram.GanttChart as GanttChartModel
import Models.Diagram.Kanban as KanbanModel
import Models.Diagram.KeyboardLayout as KeyboardLayout
import Models.Diagram.Kpt as KptModel
import Models.Diagram.OpportunityCanvas as OpportunityCanvasModel
import Models.Diagram.Scale as Scale exposing (Scale)
import Models.Diagram.Search as SearchModel
import Models.Diagram.SequenceDiagram as SequenceDiagramModel
import Models.Diagram.Settings as DiagramSettings
import Models.Diagram.StartStopContinue as StartStopContinueModel
import Models.Diagram.Table as TableModel
import Models.Diagram.Type exposing (DiagramType(..))
import Models.Diagram.UseCaseDiagram as UseCaseDiagramModel
import Models.Diagram.UserPersona as UserPersonaModel
import Models.Diagram.UserStoryMap as UserStoryMapModel
import Models.FontStyle as FontStyle
import Models.Item as Item exposing (Item, Items)
import Models.Item.Settings as ItemSettings
import Models.Position as Position exposing (Position)
import Models.Property as Property
import Models.Size as Size exposing (Size)
import Models.Text as Text
import Ports
import Return exposing (Return)
import Style.Style as Style
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Svg.Styled.Events exposing (onClick)
import Task
import Utils.Utils as Utils
import Views.Diagram.BusinessModelCanvas as BusinessModelCanvas
import Views.Diagram.ContextMenu as ContextMenu
import Views.Diagram.ER as ER
import Views.Diagram.EmpathyMap as EmpathyMap
import Views.Diagram.FourLs as FourLs
import Views.Diagram.FreeForm as FreeForm
import Views.Diagram.GanttChart as GanttChart
import Views.Diagram.Kanban as Kanban
import Views.Diagram.KeyboardLayout as KeyboardLayout
import Views.Diagram.Kpt as Kpt
import Views.Diagram.MindMap as MindMap
import Views.Diagram.MiniMap as MiniMap
import Views.Diagram.OpportunityCanvas as OpportunityCanvas
import Views.Diagram.Search as Search
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
        , windowSize = Size.zero
        , diagram =
            { size = Size.zero
            , scale = Scale.fromFloat <| Maybe.withDefault 1.0 settings.scale
            , position = ( 0, 20 )
            , isFullscreen = False
            }
        , moveState = Diagram.NotMove
        , movePosition = Position.zero
        , settings = settings
        , showZoomControl = True
        , showMiniMap = False
        , search = SearchModel.close
        , touchDistance = Nothing
        , diagramType = UserStoryMap
        , text = Text.empty
        , selectedItem = Nothing
        , contextMenu = Nothing
        , dragStatus = NoDrag
        , dropDownIndex = Nothing
        , property = Property.empty
        }


update : Model -> Msg -> Return.ReturnF Msg Model
update model message =
    case message of
        NoOp ->
            Return.zero

        Init settings window text ->
            Return.map
                (\m ->
                    updateDiagram
                        ( round window.viewport.width, round window.viewport.height - 50 )
                        m
                        text
                )
                >> Return.andThen (\m -> Return.singleton { m | settings = settings })

        ZoomIn ratio ->
            Return.andThen <| zoomIn ratio

        ZoomOut ratio ->
            Return.andThen <| zoomOut ratio

        PinchIn distance ->
            setTouchDistance (Just distance)
                >> Return.andThen (zoomIn Scale.step)

        PinchOut distance ->
            setTouchDistance (Just distance)
                >> Return.andThen (zoomOut Scale.step)

        Move isWheelEvent position ->
            Return.andThen <| move isWheelEvent position

        MoveTo position ->
            Return.map (Diagram.position.set position)
                >> clearPosition

        ToggleFullscreen ->
            Return.map (\m -> Diagram.isFullscreen.set (not m.diagram.isFullscreen) m)
                >> clearPosition

        EditSelectedItem text ->
            Return.map <| \m -> { m | selectedItem = Maybe.map (\item_ -> item_ |> Item.withTextOnly (" " ++ String.trimLeft text)) m.selectedItem }

        EndEditSelectedItem item ->
            model.selectedItem
                |> Maybe.map
                    (\selectedItem ->
                        let
                            lines : List String
                            lines =
                                Text.lines model.text

                            text : String
                            text =
                                setAt (Item.getLineNo item)
                                    (item
                                        |> Item.withSettings
                                            (Item.getSettings selectedItem)
                                        |> Item.toLineString
                                        |> String.dropLeft 1
                                    )
                                    lines
                                    |> String.join "\n"
                        in
                        setText text
                            >> clearSelectedItem
                    )
                |> Maybe.withDefault Return.zero

        FitToWindow ->
            let
                ( canvasWidth, canvasHeight ) =
                    Diagram.size model

                ( widthRatio, heightRatio ) =
                    ( toFloat (round (toFloat windowWidth / toFloat canvasWidth / 0.05)) * 0.05, toFloat (round (toFloat windowHeight / toFloat canvasHeight / 0.05)) * 0.05 )

                position : Position
                position =
                    ( windowWidth // 2 - round (toFloat canvasWidth / 2 * widthRatio), windowHeight // 2 - round (toFloat canvasHeight / 2 * heightRatio) )

                ( windowWidth, windowHeight ) =
                    model.windowSize
            in
            Return.map
                (\m ->
                    m
                        |> Diagram.scale.set (Scale.fromFloat <| min widthRatio heightRatio)
                        |> Diagram.position.set position
                )

        ColorChanged Diagram.ColorSelectMenu color ->
            model.selectedItem
                |> Maybe.map
                    (\item ->
                        let
                            currentText : String
                            currentText =
                                Text.getLine (Item.getLineNo item) model.text

                            ( mainText, settings, comment ) =
                                Item.split currentText
                        in
                        model.contextMenu
                            |> Maybe.map
                                (\menu ->
                                    Return.map (\m -> { m | contextMenu = Just { menu | contextMenu = Diagram.CloseMenu } })
                                        >> setText
                                            (setAt (Item.getLineNo item)
                                                (item
                                                    |> Item.withText mainText
                                                    |> Item.withSettings (Just (settings |> ItemSettings.withForegroundColor (Just color)))
                                                    |> Item.withComments comment
                                                    |> Item.toLineString
                                                )
                                                (Text.lines model.text)
                                                |> String.join "\n"
                                            )
                                        >> selectItem
                                            (Just
                                                (item
                                                    |> Item.withSettings
                                                        (Item.getSettings item
                                                            |> Maybe.map (ItemSettings.withForegroundColor (Just color))
                                                        )
                                                )
                                            )
                                )
                            |> Maybe.withDefault Return.zero
                    )
                |> Maybe.withDefault Return.zero

        ColorChanged Diagram.BackgroundColorSelectMenu color ->
            model.selectedItem
                |> Maybe.map
                    (\item ->
                        let
                            currentText : String
                            currentText =
                                Text.getLine (Item.getLineNo item) model.text

                            ( mainText, settings, comment ) =
                                Item.split currentText
                        in
                        model.contextMenu
                            |> Maybe.map
                                (\menu ->
                                    Return.map (\m -> { m | contextMenu = Just { menu | contextMenu = Diagram.CloseMenu } })
                                        >> setText
                                            (setAt (Item.getLineNo item)
                                                (item
                                                    |> Item.withText mainText
                                                    |> Item.withSettings (Just (ItemSettings.withBackgroundColor (Just color) settings))
                                                    |> Item.withComments comment
                                                    |> Item.toLineString
                                                )
                                                (Text.lines model.text)
                                                |> String.join "\n"
                                            )
                                        >> selectItem
                                            (Just
                                                (item
                                                    |> Item.withSettings
                                                        (Item.getSettings item
                                                            |> Maybe.map (ItemSettings.withBackgroundColor (Just color))
                                                        )
                                                )
                                            )
                                )
                            |> Maybe.withDefault Return.zero
                    )
                |> Maybe.withDefault Return.zero

        ColorChanged _ _ ->
            Return.zero

        FontStyleChanged style ->
            model.selectedItem
                |> Maybe.map
                    (\item ->
                        let
                            ( text, settings, comment ) =
                                Item.split currentText

                            currentText : String
                            currentText =
                                Text.getLine (Item.getLineNo item) model.text

                            lines : List String
                            lines =
                                Text.lines model.text

                            updateLine : String
                            updateLine =
                                item
                                    |> Item.withText (text |> FontStyle.apply style)
                                    |> Item.withSettings (Just settings)
                                    |> Item.withComments comment
                                    |> Item.toLineString
                        in
                        setText (setAt (Item.getLineNo item) updateLine lines |> String.join "\n")
                    )
                |> Maybe.withDefault Return.zero

        DropFiles files ->
            Return.map (\m -> { m | dragStatus = NoDrag })
                >> (List.filter (\file -> File.mime file |> String.startsWith "text/") files
                        |> List.head
                        |> Maybe.map File.toString
                        |> Maybe.withDefault (Task.succeed "")
                        |> Task.perform LoadFile
                        |> Return.command
                   )

        LoadFile file ->
            if String.isEmpty file then
                Return.zero

            else
                Return.map <| \m -> { m | text = Text.fromString file }

        ChangeDragStatus status ->
            Return.map <| \m -> { m | dragStatus = status }

        FontSizeChanged size ->
            model.selectedItem
                |> Maybe.map
                    (\item ->
                        let
                            ( mainText, settings, comment ) =
                                Item.split currentText

                            currentText : String
                            currentText =
                                Text.getLine (Item.getLineNo item) model.text

                            lines : List String
                            lines =
                                Text.lines model.text

                            text : String
                            text =
                                item
                                    |> Item.withText mainText
                                    |> Item.withSettings (Just (settings |> ItemSettings.withFontSize size))
                                    |> Item.withComments comment
                                    |> Item.toLineString

                            updateText : String
                            updateText =
                                setAt (Item.getLineNo item) text lines
                                    |> String.join "\n"
                        in
                        closeDropDown
                            >> setText updateText
                            >> selectItem
                                (Just
                                    (item
                                        |> Item.withSettings
                                            (Item.getSettings item
                                                |> Maybe.map (ItemSettings.withFontSize size)
                                            )
                                    )
                                )
                    )
                |> Maybe.withDefault Return.zero

        ToggleDropDownList id ->
            Return.map <|
                \m ->
                    { m
                        | dropDownIndex =
                            if (m.dropDownIndex |> Maybe.withDefault "") == id then
                                Nothing

                            else
                                Just id
                    }

        ToggleMiniMap ->
            Return.map <| \m -> { m | showMiniMap = not m.showMiniMap }

        ToggleSearch ->
            let
                diagramData : DiagramData.Data
                diagramData =
                    updateData (Text.toString model.text) model.data items

                items : Items
                items =
                    Item.searchClear model.items
            in
            Return.map <| \m -> { m | items = items, data = diagramData, search = SearchModel.toggle m.search }

        ToolbarClick item ->
            Item.toLineString item |> Ports.insertText |> Return.command

        ChangeText text ->
            Return.map <| \m -> updateDiagram m.windowSize m text

        Resize width height ->
            Return.map (\m -> { m | windowSize = ( width, height - 56 ) })
                >> clearPosition

        Search query ->
            let
                diagramData : DiagramData.Data
                diagramData =
                    updateData (Text.toString model.text) model.data items

                items : Items
                items =
                    if String.isEmpty query then
                        Item.searchClear model.items

                    else
                        Item.search model.items query
            in
            Return.map <| \m -> { m | items = items, data = diagramData, search = SearchModel.search query }

        Start moveState pos ->
            Return.map <| \m -> { m | moveState = moveState, movePosition = pos }

        StartPinch distance ->
            Return.map <| \m -> { m | touchDistance = Just distance }

        Select (Just { item, position, displayAllMenu }) ->
            Return.map (\m -> { m | contextMenu = Just { contextMenu = Diagram.CloseMenu, displayAllMenu = displayAllMenu, position = position }, selectedItem = Just item })
                >> setFocus "edit-item"

        Select Nothing ->
            Return.map <| \m -> { m | selectedItem = Nothing }

        SelectContextMenu menu ->
            model.contextMenu
                |> Maybe.map (\contextMenu -> Return.map (\m -> { m | contextMenu = Just { contextMenu | contextMenu = menu } }))
                |> Maybe.withDefault Return.zero

        Stop ->
            (case model.moveState of
                Diagram.ItemMove target ->
                    case target of
                        Diagram.TableTarget table ->
                            let
                                (ErDiagramModel.Table _ _ _ lineNo) =
                                    table
                            in
                            setLine lineNo (Text.lines model.text) (ErDiagramModel.tableToLineString table)

                        Diagram.ItemTarget item ->
                            setLine (Item.getLineNo item) (Text.lines model.text) (Item.toLineString item)

                Diagram.ItemResize item _ ->
                    setLine (Item.getLineNo item) (Text.lines model.text) (Item.toLineString item)

                _ ->
                    Return.zero
            )
                >> Return.andThen stopMove

        SelectFromLineNo lineNo text ->
            let
                item : Item
                item =
                    Item.itemFromString lineNo text
            in
            if Item.isComment item then
                Return.zero

            else
                selectItem <| Just item



-- View


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
                Basics.toFloat
                    (Basics.max (Size.getHeight model.diagram.size) (Size.getHeight model.windowSize))
                    |> round

            else
                Basics.toFloat
                    (Size.getHeight model.windowSize)
                    |> round

        svgWidth : Int
        svgWidth =
            if model.diagram.isFullscreen then
                Basics.toFloat
                    (Basics.max (Size.getWidth model.diagram.size) (Size.getWidth model.windowSize))
                    |> round

            else
                Basics.toFloat
                    (Size.getWidth model.windowSize)
                    |> round
    in
    Html.div
        [ Attr.id "usm-area"
        , Attr.css
            [ position relative
            , Style.heightFull
            , case model.moveState of
                Diagram.BoardMove ->
                    Css.batch [ cursor grabbing ]

                _ ->
                    Css.batch [ cursor grab ]
            , case model.dragStatus of
                NoDrag ->
                    Css.batch []

                DragOver ->
                    Css.batch [ backgroundColor <| rgba 0 0 0 0.3 ]
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
            Lazy.lazy2 zoomControl model.diagram.isFullscreen (Scale.toFloat model.diagram.scale)

          else
            Empty.view
        , Lazy.lazy MiniMap.view
            { diagramSvg = mainSvg
            , diagramType = model.diagramType
            , moveState = model.moveState
            , position = centerPosition
            , scale = Scale.toFloat model.diagram.scale
            , showMiniMap = model.showMiniMap
            , svgSize = ( svgWidth, svgHeight )
            , viewport = model.windowSize
            }
        , Lazy.lazy4 svgView model centerPosition ( svgWidth, svgHeight ) mainSvg
        , if SearchModel.isSearch model.search then
            Html.div
                [ Attr.css
                    [ position absolute
                    , top <| px 62
                    , right <| px 32
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


clearPosition : Return.ReturnF Msg Model
clearPosition =
    Return.map <| \m -> { m | movePosition = Position.zero }


clearSelectedItem : Return.ReturnF Msg Model
clearSelectedItem =
    Return.map <| \m -> { m | selectedItem = Nothing }


closeDropDown : Return.ReturnF Msg Model
closeDropDown =
    Return.map <| \m -> { m | dropDownIndex = Nothing }


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


move : Bool -> Position -> Model -> Return Msg Model
move isWheelEvent ( x, y ) m =
    case m.moveState of
        Diagram.BoardMove ->
            m
                |> Diagram.position.set
                    ( Position.getX m.diagram.position + round (toFloat (x - Position.getX m.movePosition) * Scale.toFloat m.diagram.scale)
                    , Position.getY m.diagram.position + round (toFloat (y - Position.getY m.movePosition) * Scale.toFloat m.diagram.scale)
                    )
                |> Diagram.movePosition.set ( x, y )
                |> Return.singleton

        Diagram.WheelMove ->
            if isWheelEvent then
                m
                    |> Diagram.position.set
                        ( Position.getX m.diagram.position - round (toFloat x * Scale.toFloat m.diagram.scale)
                        , Position.getY m.diagram.position - round (toFloat y * Scale.toFloat m.diagram.scale)
                        )
                    |> Diagram.movePosition.set ( x, y )
                    |> Return.singleton

            else
                Return.singleton m

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
                                    |> Maybe.map
                                        (\p ->
                                            ( Position.getX p + round (toFloat (x - Position.getX m.movePosition) / Scale.toFloat m.diagram.scale)
                                            , Position.getY p + round (toFloat (y - Position.getY m.movePosition) / Scale.toFloat m.diagram.scale)
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
                        newItem : Item
                        newItem =
                            Item.withOffset newPosition item

                        newPosition : Position
                        newPosition =
                            ( Position.getX offset + round (toFloat (x - Position.getX m.movePosition) / Scale.toFloat m.diagram.scale)
                            , Position.getY offset + round (toFloat (y - Position.getY m.movePosition) / Scale.toFloat m.diagram.scale)
                            )

                        offset : Position
                        offset =
                            Item.getOffset item
                    in
                    Return.singleton
                        { m
                            | moveState =
                                Diagram.ItemMove <|
                                    Diagram.ItemTarget newItem
                            , movePosition = ( x, y )
                            , selectedItem = Just newItem
                        }

        Diagram.ItemResize item direction ->
            let
                newItem : Item
                newItem =
                    Item.withOffsetSize newSize item
                        |> Item.withOffset newPosition

                ( newSize, newPosition ) =
                    case direction of
                        Diagram.TopLeft ->
                            ( ( Size.getWidth offsetSize + round (toFloat (Position.getX m.movePosition - x) / Scale.toFloat m.diagram.scale)
                              , Size.getHeight offsetSize + round (toFloat (Position.getY m.movePosition - y) / Scale.toFloat m.diagram.scale)
                              )
                            , ( Position.getX offsetPosition + round (toFloat (x - Position.getX m.movePosition) / Scale.toFloat m.diagram.scale)
                              , Position.getY offsetPosition + round (toFloat (y - Position.getY m.movePosition) / Scale.toFloat m.diagram.scale)
                              )
                            )

                        Diagram.TopRight ->
                            ( ( Size.getWidth offsetSize + round (toFloat (x - Position.getX m.movePosition) / Scale.toFloat m.diagram.scale)
                              , Size.getHeight offsetSize + round (toFloat (Position.getY m.movePosition - y) / Scale.toFloat m.diagram.scale)
                              )
                            , ( Position.getX offsetPosition
                              , Position.getY offsetPosition + round (toFloat (y - Position.getY m.movePosition) / Scale.toFloat m.diagram.scale)
                              )
                            )

                        Diagram.BottomLeft ->
                            ( ( Size.getWidth offsetSize + round (toFloat (Position.getX m.movePosition - x) / Scale.toFloat m.diagram.scale)
                              , Size.getHeight offsetSize + round (toFloat (y - Position.getY m.movePosition) / Scale.toFloat m.diagram.scale)
                              )
                            , ( Position.getX offsetPosition + round (toFloat (x - Position.getX m.movePosition) / Scale.toFloat m.diagram.scale)
                              , Position.getY offsetPosition
                              )
                            )

                        Diagram.BottomRight ->
                            ( ( Size.getWidth offsetSize + round (toFloat (x - Position.getX m.movePosition) / Scale.toFloat m.diagram.scale)
                              , Size.getHeight offsetSize + round (toFloat (y - Position.getY m.movePosition) / Scale.toFloat m.diagram.scale)
                              )
                            , offsetPosition
                            )

                        Diagram.Top ->
                            ( ( 0
                              , Size.getHeight offsetSize + round (toFloat (Position.getY m.movePosition - y) / Scale.toFloat m.diagram.scale)
                              )
                            , ( Position.getX offsetPosition, Position.getY offsetPosition + round (toFloat (y - Position.getY m.movePosition) / Scale.toFloat m.diagram.scale) )
                            )

                        Diagram.Bottom ->
                            ( ( 0, Size.getHeight offsetSize + round (toFloat (y - Position.getY m.movePosition) / Scale.toFloat m.diagram.scale) ), offsetPosition )

                        Diagram.Left ->
                            ( ( Size.getWidth offsetSize + round (toFloat (Position.getX m.movePosition - x) / Scale.toFloat m.diagram.scale), 0 )
                            , ( Position.getX offsetPosition + round (toFloat (x - Position.getX m.movePosition) / Scale.toFloat m.diagram.scale)
                              , Position.getY offsetPosition
                              )
                            )

                        Diagram.Right ->
                            ( ( Size.getWidth offsetSize + round (toFloat (x - Position.getX m.movePosition) / Scale.toFloat m.diagram.scale), 0 ), offsetPosition )

                offsetPosition : Position
                offsetPosition =
                    Item.getOffset item

                offsetSize : Size
                offsetSize =
                    Item.getOffsetSize item
            in
            Return.singleton
                { m
                    | moveState =
                        Diagram.ItemResize newItem direction
                    , movePosition = ( x, y )
                    , selectedItem = Just newItem
                }

        Diagram.MiniMapMove ->
            m
                |> Diagram.position.set
                    ( Position.getX m.diagram.position - round (toFloat (x - Position.getX m.movePosition) * Scale.toFloat m.diagram.scale * (toFloat (Size.getWidth m.windowSize) / 260.0 * 2.0))
                    , Position.getY m.diagram.position - round (toFloat (y - Position.getY m.movePosition) * Scale.toFloat m.diagram.scale * (toFloat (Size.getWidth m.windowSize) / 260.0 * 2.0))
                    )
                |> Diagram.movePosition.set ( x, y )
                |> Return.singleton

        _ ->
            Return.singleton m



-- Update


onTouchNotMove : Svg.Attribute Msg
onTouchNotMove =
    Attr.style "" ""


onMultiTouchMove : Maybe Float -> List Touch.Touch -> Msg
onMultiTouchMove distance changedTouches =
    let
        p1 : ( Float, Float )
        p1 =
            getAt 0 changedTouches
                |> Maybe.map .pagePos
                |> Maybe.withDefault ( 0.0, 0.0 )

        p2 : ( Float, Float )
        p2 =
            getAt 1 changedTouches
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


selectItem : SelectedItem -> Return.ReturnF Msg Model
selectItem item =
    Return.map <| \m -> { m | selectedItem = item }


setFocus : String -> Return.ReturnF Msg Model
setFocus id =
    Return.command (Task.attempt (\_ -> NoOp) <| Dom.focus id)


setLine : Int -> List String -> String -> Return.ReturnF Msg Model
setLine lineNo lines line =
    setText
        (setAt lineNo line lines
            |> String.join "\n"
        )


setText : String -> Return.ReturnF Msg Model
setText text =
    Return.map <| \m -> { m | text = Text.change <| Text.fromString text }


setTouchDistance : Maybe Float -> Return.ReturnF Msg Model
setTouchDistance distance =
    Return.map <| \m -> { m | touchDistance = distance }


stopMove : Model -> Return Msg Model
stopMove model =
    Return.singleton
        { model
            | moveState = Diagram.NotMove
            , movePosition = Position.zero
            , touchDistance = Nothing
        }


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
        [ if String.isEmpty model.settings.font then
            Svg.defs [] [ highlightDefs ]

          else
            Svg.defs [] [ highlightDefs, Svg.style [] [ Svg.text ("@import url('https://fonts.googleapis.com/css2?family=" ++ model.settings.font ++ "&display=swap');") ] ]
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
        , Svg.g
            [ SvgAttr.transform <|
                "translate("
                    ++ String.fromInt (Position.getX centerPosition)
                    ++ ","
                    ++ String.fromInt (Position.getY centerPosition)
                    ++ ") scale("
                    ++ String.fromFloat
                        (model.diagram.scale |> Scale.toFloat)
                    ++ ","
                    ++ String.fromFloat
                        (model.diagram.scale |> Scale.toFloat)
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
                            ( floor <| toFloat (Position.getX pos) * Scale.toFloat model.diagram.scale
                            , floor <| toFloat (Position.getY pos + h + 24) * Scale.toFloat model.diagram.scale
                            )

                        else if Item.isHorizontalLine item_ then
                            ( floor <| toFloat (Position.getX pos) * Scale.toFloat model.diagram.scale
                            , floor <| toFloat (Position.getY pos + h + 8) * Scale.toFloat model.diagram.scale
                            )

                        else if Item.isCanvas item_ then
                            ( floor <| toFloat (Position.getX position) * Scale.toFloat model.diagram.scale
                            , floor <| toFloat (Position.getY position) * Scale.toFloat model.diagram.scale
                            )

                        else
                            ( floor <| toFloat (Position.getX pos) * Scale.toFloat model.diagram.scale
                            , floor <| toFloat (Position.getY pos + h + 24) * Scale.toFloat model.diagram.scale
                            )

                    ( _, h ) =
                        Item.getSize item_ ( model.settings.size.width, model.settings.size.height )

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


updateData : String -> DiagramData.Data -> Items -> DiagramData.Data
updateData text data items =
    case data of
        DiagramData.Empty ->
            DiagramData.Empty

        DiagramData.UserStoryMap usm ->
            DiagramData.UserStoryMap <| UserStoryMapModel.from text (UserStoryMapModel.getHierarchy usm) items

        DiagramData.MindMap _ hierarchy ->
            DiagramData.MindMap items hierarchy

        DiagramData.SiteMap _ hierarchy ->
            DiagramData.SiteMap items hierarchy

        DiagramData.Table _ ->
            DiagramData.Table <| TableModel.from items

        DiagramData.Kpt _ ->
            DiagramData.Kpt <| KptModel.from items

        DiagramData.FourLs _ ->
            DiagramData.FourLs <| FourLsModel.from items

        DiagramData.Kanban _ ->
            DiagramData.Kanban <| KanbanModel.from items

        DiagramData.BusinessModelCanvas _ ->
            DiagramData.BusinessModelCanvas <| BusinessModelCanvasModel.from items

        DiagramData.EmpathyMap _ ->
            DiagramData.EmpathyMap <| EmpathyMapModel.from items

        DiagramData.OpportunityCanvas _ ->
            DiagramData.OpportunityCanvas <| OpportunityCanvasModel.from items

        DiagramData.UserPersona _ ->
            DiagramData.UserPersona <| UserPersonaModel.from items

        DiagramData.StartStopContinue _ ->
            DiagramData.StartStopContinue <| StartStopContinueModel.from items

        DiagramData.ErDiagram _ ->
            DiagramData.ErDiagram <| ErDiagramModel.from items

        DiagramData.SequenceDiagram _ ->
            DiagramData.SequenceDiagram <| SequenceDiagramModel.from items

        DiagramData.FreeForm _ ->
            DiagramData.FreeForm <| FreeFormModel.from items

        DiagramData.GanttChart _ ->
            DiagramData.GanttChart <| GanttChartModel.from items

        DiagramData.UseCaseDiagram _ ->
            DiagramData.UseCaseDiagram <| UseCaseDiagramModel.from items

        DiagramData.KeyboardLayout _ ->
            DiagramData.KeyboardLayout <| KeyboardLayout.from items


updateDiagram : Size -> Model -> String -> Model
updateDiagram size base text =
    let
        data : DiagramData.Data
        data =
            case base.diagramType of
                UserStoryMap ->
                    DiagramData.UserStoryMap <| UserStoryMapModel.from text hierarchy items

                OpportunityCanvas ->
                    DiagramData.OpportunityCanvas <| OpportunityCanvasModel.from items

                BusinessModelCanvas ->
                    DiagramData.BusinessModelCanvas <| BusinessModelCanvasModel.from items

                Fourls ->
                    DiagramData.FourLs <| FourLsModel.from items

                StartStopContinue ->
                    DiagramData.StartStopContinue <| StartStopContinueModel.from items

                Kpt ->
                    DiagramData.Kpt <| KptModel.from items

                UserPersona ->
                    DiagramData.UserPersona <| UserPersonaModel.from items

                MindMap ->
                    DiagramData.MindMap items hierarchy

                EmpathyMap ->
                    DiagramData.EmpathyMap <| EmpathyMapModel.from items

                SiteMap ->
                    DiagramData.SiteMap items hierarchy

                GanttChart ->
                    DiagramData.GanttChart <| GanttChartModel.from items

                ImpactMap ->
                    DiagramData.MindMap items hierarchy

                ErDiagram ->
                    DiagramData.ErDiagram <| ErDiagramModel.from items

                Kanban ->
                    DiagramData.Kanban <| KanbanModel.from items

                Table ->
                    DiagramData.Table <| TableModel.from items

                SequenceDiagram ->
                    DiagramData.SequenceDiagram <| SequenceDiagramModel.from items

                Freeform ->
                    DiagramData.FreeForm <| FreeFormModel.from items

                UseCaseDiagram ->
                    DiagramData.UseCaseDiagram <| UseCaseDiagramModel.from items

                KeyboardLayout ->
                    DiagramData.KeyboardLayout <| KeyboardLayout.from items

        ( hierarchy, items ) =
            Item.fromString text

        newModel : Model
        newModel =
            { base | items = items, data = data }

        ( svgWidth, svgHeight ) =
            Diagram.size newModel
    in
    { newModel
        | windowSize = size
        , diagram =
            { size = ( svgWidth, svgHeight )
            , scale = base.diagram.scale
            , position = newModel.diagram.position
            , isFullscreen = newModel.diagram.isFullscreen
            }
        , movePosition = Position.zero
        , text = Text.edit base.text text
        , property = Property.fromString text
    }


zoomControl : Bool -> Float -> Html Msg
zoomControl isFullscreen scale =
    let
        s : Int
        s =
            round <| scale * 100.0
    in
    Html.div
        [ Attr.id "zoom-control"
        , Attr.css
            [ position absolute
            , alignItems center
            , displayFlex
            , justifyContent spaceBetween
            , top <| px 16
            , right <| px 32
            , width <| px 240
            , backgroundColor <| hex <| Color.toString Color.white2
            , Style.roundedSm
            , padding2 (px 8) (px 16)
            , border3 (px 1) solid (rgba 0 0 0 0.1)
            ]
        ]
        [ Html.div
            [ Attr.css
                [ width <| px 24
                , height <| px 24
                , cursor pointer
                , displayFlex
                , alignItems center
                ]
            , onClick ToggleSearch
            ]
            [ Icon.search (Color.toString Color.disabledIconColor) 18
            ]
        , Html.div
            [ Attr.css
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
        , Html.div
            [ Attr.css
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
        , Html.div
            [ Attr.css
                [ width <| px 24
                , height <| px 24
                , cursor pointer
                ]
            , onClick <| ZoomOut Scale.step
            ]
            [ Icon.remove 24
            ]
        , Html.div
            [ Attr.css
                [ Css.fontSize <| rem 0.7
                , color <| hex <| Color.toString Color.labelDefalut
                , cursor pointer
                , fontWeight <| int 600
                , width <| px 32
                ]
            ]
            [ Html.text (String.fromInt s ++ "%")
            ]
        , Html.div
            [ Attr.css
                [ width <| px 24
                , height <| px 24
                , cursor pointer
                ]
            , onClick <| ZoomIn Scale.step
            ]
            [ Icon.add 24
            ]
        , Html.div
            [ Attr.css
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


zoomIn : Scale -> Model -> Return Msg Model
zoomIn step model =
    if Scale.toFloat model.diagram.scale <= 10.0 then
        Return.singleton
            { model
                | diagram =
                    { size = ( Size.getWidth model.diagram.size, Size.getHeight model.diagram.size )
                    , scale = Scale.add model.diagram.scale step
                    , position = model.diagram.position
                    , isFullscreen = model.diagram.isFullscreen
                    }
            }

    else
        Return.singleton model


zoomOut : Scale -> Model -> Return Msg Model
zoomOut step model =
    if Scale.toFloat model.diagram.scale > 0.03 then
        Return.singleton
            { model
                | diagram =
                    { size = ( Size.getWidth model.diagram.size, Size.getHeight model.diagram.size )
                    , scale = Scale.sub model.diagram.scale step
                    , position = model.diagram.position
                    , isFullscreen = model.diagram.isFullscreen
                    }
            }

    else
        Return.singleton model
