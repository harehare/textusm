module Diagram.State exposing (init, update)

import Browser.Dom as Dom
import Diagram.BusinessModelCanvas.Types as BusinessModelCanvasModel
import Diagram.ER.Types as ErDiagramModel
import Diagram.EmpathyMap.Types as EmpathyMapModel
import Diagram.FourLs.Types as FourLsModel
import Diagram.FreeForm.Types as FreeFormModel
import Diagram.GanttChart.Types as GanttChartModel
import Diagram.Kanban.Types as KanbanModel
import Diagram.KeyboardLayout.Types as KeyboardLayout
import Diagram.KeyboardLayout.View as KeyboardLayout
import Diagram.Kpt.Types as KptModel
import Diagram.OpportunityCanvas.Types as OpportunityCanvasModel
import Diagram.Search.Types as SearchModel
import Diagram.SequenceDiagram.Types as SequenceDiagramModel
import Diagram.StartStopContinue.Types as StartStopContinueModel
import Diagram.Table.Types as TableModel
import Diagram.Types as Diagram exposing (DragStatus(..), Model, Msg(..), SelectedItem)
import Diagram.Types.Data as DiagramData
import Diagram.Types.Scale as Scale exposing (Scale)
import Diagram.Types.Settings as DiagramSettings
import Diagram.Types.Type exposing (DiagramType(..))
import Diagram.UseCaseDiagram.Types as UseCaseDiagramModel
import Diagram.UserPersona.Types as UserPersonaModel
import Diagram.UserPersona.View as UserPersonaModel
import Diagram.UserStoryMap.Types as UserStoryMapModel
import File
import List
import List.Extra as ListEx
import Maybe
import Ports
import Return exposing (Return)
import Task
import Types.FontStyle as FontStyle
import Types.Item as Item exposing (Item, Items)
import Types.Item.Parser as ItemParser
import Types.Item.Settings as ItemSettings
import Types.Item.Value as ItemValue exposing (Value(..))
import Types.Position as Position exposing (Position)
import Types.Property as Property
import Types.Size as Size exposing (Size)
import Types.Text as Text


init : DiagramSettings.Settings -> Return Msg Model
init settings =
    Return.singleton
        { items = Item.empty
        , data = DiagramData.Empty
        , windowSize = Size.zero
        , diagram =
            { size = Size.zero
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
            Return.map <| \m -> { m | selectedItem = Maybe.map (\item_ -> item_ |> Item.withTextOnly (String.trimLeft text)) m.selectedItem }

        EndEditSelectedItem item ->
            model.selectedItem
                |> Maybe.map
                    (\selectedItem ->
                        let
                            lines : List String
                            lines =
                                Text.lines model.text

                            beforeText : String
                            beforeText =
                                Item.new
                                    |> (ListEx.getAt (Item.getLineNo item) lines
                                            |> Maybe.map String.trim
                                            |> Maybe.withDefault ""
                                            |> Item.withText
                                       )
                                    |> Item.getTextOnly

                            afterText : String
                            afterText =
                                Item.getTextOnly selectedItem
                        in
                        if beforeText == afterText then
                            clearSelectedItem

                        else
                            let
                                text : String
                                text =
                                    ListEx.setAt (Item.getLineNo item)
                                        (item
                                            |> Item.withSettings (Item.getSettings selectedItem)
                                            |> Item.toLineString
                                        )
                                        lines
                                        |> String.join "\n"
                            in
                            setText text >> clearSelectedItem
                    )
                |> Maybe.withDefault Return.zero

        FitToWindow ->
            let
                ( windowWidth, windowHeight ) =
                    model.windowSize

                ( canvasWidth, canvasHeight ) =
                    Diagram.size model

                ( widthRatio, heightRatio ) =
                    ( toFloat (round (toFloat windowWidth / toFloat canvasWidth / 0.05)) * 0.05, toFloat (round (toFloat windowHeight / toFloat canvasHeight / 0.05)) * 0.05 )

                position : Position
                position =
                    ( windowWidth // 2 - round (toFloat canvasWidth / 2 * widthRatio), windowHeight // 2 - round (toFloat canvasHeight / 2 * heightRatio) )
            in
            Return.map
                (\m ->
                    let
                        newModel : Model
                        newModel =
                            m |> Diagram.position.set position
                    in
                    { newModel | settings = m.settings |> DiagramSettings.scale.set (Just <| Scale.fromFloat <| min widthRatio heightRatio) }
                )

        ColorChanged Diagram.ColorSelectMenu color ->
            model.selectedItem
                |> Maybe.map
                    (\item ->
                        let
                            currentText : String
                            currentText =
                                Text.getLine (Item.getLineNo item) model.text

                            (ItemParser.Parsed mainText comment settings) =
                                currentText |> ItemParser.parse |> Result.withDefault (ItemParser.Parsed (PlainText 0 (Text.fromString currentText)) Nothing Nothing)
                        in
                        model.contextMenu
                            |> Maybe.map
                                (\menu ->
                                    Return.map (\m -> { m | contextMenu = Just { menu | contextMenu = Diagram.CloseMenu } })
                                        >> setText
                                            (ListEx.setAt (Item.getLineNo item)
                                                (item
                                                    |> Item.withValue mainText
                                                    |> Item.withSettings (Just (settings |> Maybe.withDefault ItemSettings.new |> ItemSettings.withForegroundColor (Just color)))
                                                    |> Item.withComments comment
                                                    |> Item.toLineString
                                                )
                                                (Text.lines model.text)
                                                |> String.join "\n"
                                            )
                                        >> clearSelectedItem
                                )
                            |> Maybe.withDefault Return.zero
                    )
                |> Maybe.withDefault Return.zero

        ColorChanged Diagram.BackgroundColorSelectMenu color ->
            model.selectedItem
                |> Maybe.map
                    (\item ->
                        let
                            currentLine =
                                Text.getLine (Item.getLineNo item) model.text

                            (ItemParser.Parsed mainText comment settings) =
                                currentLine |> ItemParser.parse |> Result.withDefault (ItemParser.Parsed (PlainText 0 (Text.fromString currentLine)) Nothing Nothing)
                        in
                        model.contextMenu
                            |> Maybe.map
                                (\menu ->
                                    Return.map (\m -> { m | contextMenu = Just { menu | contextMenu = Diagram.CloseMenu } })
                                        >> setText
                                            (ListEx.setAt (Item.getLineNo item)
                                                (item
                                                    |> Item.withValue mainText
                                                    |> Item.withSettings (Just (settings |> Maybe.withDefault ItemSettings.new |> ItemSettings.withBackgroundColor (Just color)))
                                                    |> Item.withComments comment
                                                    |> Item.toLineString
                                                )
                                                (Text.lines model.text)
                                                |> String.join "\n"
                                            )
                                        >> clearSelectedItem
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
                            currentLine =
                                Text.getLine (Item.getLineNo item) model.text

                            (ItemParser.Parsed value_ comment_ settings_) =
                                currentLine |> ItemParser.parse |> Result.withDefault (ItemParser.Parsed (PlainText 0 (Text.fromString currentLine)) Nothing Nothing)

                            updateLine : String
                            updateLine =
                                item
                                    |> Item.withText (ItemValue.update value_ (ItemValue.toTrimedString value_ |> FontStyle.apply style) |> ItemValue.toFullString)
                                    |> Item.withSettings settings_
                                    |> Item.withComments comment_
                                    |> Item.toLineString
                        in
                        setText (ListEx.setAt (Item.getLineNo item) updateLine (Text.lines model.text) |> String.join "\n")
                            >> clearSelectedItem
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
                            currentLine =
                                Text.getLine (Item.getLineNo item) model.text

                            (ItemParser.Parsed mainText comment settings) =
                                currentLine |> ItemParser.parse |> Result.withDefault (ItemParser.Parsed (PlainText 0 (Text.fromString currentLine)) Nothing Nothing)

                            text : String
                            text =
                                item
                                    |> Item.withValue mainText
                                    |> Item.withSettings (Just (settings |> Maybe.withDefault ItemSettings.new |> ItemSettings.withFontSize size))
                                    |> Item.withComments comment
                                    |> Item.toLineString

                            updateText : String
                            updateText =
                                ListEx.setAt (Item.getLineNo item) text (Text.lines model.text)
                                    |> String.join "\n"
                        in
                        closeDropDown
                            >> setText updateText
                            >> clearSelectedItem
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

        ToggleEdit ->
            Return.map
                (\m ->
                    { m
                        | settings =
                            m.settings
                                |> DiagramSettings.lockEditing.set
                                    (m.settings.lockEditing
                                        |> Maybe.withDefault False
                                        |> not
                                        |> Just
                                    )
                    }
                )


clearPosition : Return.ReturnF Msg Model
clearPosition =
    Return.map <| \m -> { m | movePosition = Position.zero }


clearSelectedItem : Return.ReturnF Msg Model
clearSelectedItem =
    Return.map <| \m -> { m | selectedItem = Nothing }


closeDropDown : Return.ReturnF Msg Model
closeDropDown =
    Return.map <| \m -> { m | dropDownIndex = Nothing }


move : Bool -> Position -> Model -> Return Msg Model
move isWheelEvent ( x, y ) m =
    case m.moveState of
        Diagram.BoardMove ->
            m
                |> Diagram.position.set
                    ( Position.getX m.diagram.position + round (toFloat (x - Position.getX m.movePosition) * Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default))
                    , Position.getY m.diagram.position + round (toFloat (y - Position.getY m.movePosition) * Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default))
                    )
                |> Diagram.movePosition.set ( x, y )
                |> Return.singleton

        Diagram.WheelMove ->
            if isWheelEvent then
                m
                    |> Diagram.position.set
                        ( Position.getX m.diagram.position - round (toFloat x * Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default))
                        , Position.getY m.diagram.position - round (toFloat y * Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default))
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
                                            ( Position.getX p + round (toFloat (x - Position.getX m.movePosition) / Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default))
                                            , Position.getY p + round (toFloat (y - Position.getY m.movePosition) / Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default))
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
                            ( Position.getX offset + round (toFloat (x - Position.getX m.movePosition) / Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default))
                            , Position.getY offset + round (toFloat (y - Position.getY m.movePosition) / Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default))
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
                            ( ( Size.getWidth offsetSize + round (toFloat (Position.getX m.movePosition - x) / Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default))
                              , Size.getHeight offsetSize + round (toFloat (Position.getY m.movePosition - y) / Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default))
                              )
                            , ( Position.getX offsetPosition + round (toFloat (x - Position.getX m.movePosition) / Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default))
                              , Position.getY offsetPosition + round (toFloat (y - Position.getY m.movePosition) / Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default))
                              )
                            )

                        Diagram.TopRight ->
                            ( ( Size.getWidth offsetSize + round (toFloat (x - Position.getX m.movePosition) / Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default))
                              , Size.getHeight offsetSize + round (toFloat (Position.getY m.movePosition - y) / Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default))
                              )
                            , ( Position.getX offsetPosition
                              , Position.getY offsetPosition + round (toFloat (y - Position.getY m.movePosition) / Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default))
                              )
                            )

                        Diagram.BottomLeft ->
                            ( ( Size.getWidth offsetSize + round (toFloat (Position.getX m.movePosition - x) / Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default))
                              , Size.getHeight offsetSize + round (toFloat (y - Position.getY m.movePosition) / Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default))
                              )
                            , ( Position.getX offsetPosition + round (toFloat (x - Position.getX m.movePosition) / Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default))
                              , Position.getY offsetPosition
                              )
                            )

                        Diagram.BottomRight ->
                            ( ( Size.getWidth offsetSize + round (toFloat (x - Position.getX m.movePosition) / Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default))
                              , Size.getHeight offsetSize + round (toFloat (y - Position.getY m.movePosition) / Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default))
                              )
                            , offsetPosition
                            )

                        Diagram.Top ->
                            ( ( 0
                              , Size.getHeight offsetSize + round (toFloat (Position.getY m.movePosition - y) / Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default))
                              )
                            , ( Position.getX offsetPosition, Position.getY offsetPosition + round (toFloat (y - Position.getY m.movePosition) / Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default)) )
                            )

                        Diagram.Bottom ->
                            ( ( 0, Size.getHeight offsetSize + round (toFloat (y - Position.getY m.movePosition) / Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default)) ), offsetPosition )

                        Diagram.Left ->
                            ( ( Size.getWidth offsetSize + round (toFloat (Position.getX m.movePosition - x) / Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default)), 0 )
                            , ( Position.getX offsetPosition + round (toFloat (x - Position.getX m.movePosition) / Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default))
                              , Position.getY offsetPosition
                              )
                            )

                        Diagram.Right ->
                            ( ( Size.getWidth offsetSize + round (toFloat (x - Position.getX m.movePosition) / Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default)), 0 ), offsetPosition )

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
                    ( Position.getX m.diagram.position - round (toFloat (x - Position.getX m.movePosition) * Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default) * (toFloat (Size.getWidth m.windowSize) / 260.0 * 2.0))
                    , Position.getY m.diagram.position - round (toFloat (y - Position.getY m.movePosition) * Scale.toFloat (m.settings.scale |> Maybe.withDefault Scale.default) * (toFloat (Size.getWidth m.windowSize) / 260.0 * 2.0))
                    )
                |> Diagram.movePosition.set ( x, y )
                |> Return.singleton

        _ ->
            Return.singleton m


selectItem : SelectedItem -> Return.ReturnF Msg Model
selectItem item =
    Return.map <| \m -> { m | selectedItem = item }


setFocus : String -> Return.ReturnF Msg Model
setFocus id =
    Return.command (Task.attempt (\_ -> NoOp) <| Dom.focus id)


setLine : Int -> List String -> String -> Return.ReturnF Msg Model
setLine lineNo lines line =
    setText
        (ListEx.setAt lineNo line lines
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
            , position = newModel.diagram.position
            , isFullscreen = newModel.diagram.isFullscreen
            }
        , movePosition = Position.zero
        , text = Text.edit base.text text
        , property = Property.fromString text
    }


zoomIn : Scale -> Model -> Return Msg Model
zoomIn step model =
    Return.singleton
        { model
            | diagram =
                { size = ( Size.getWidth model.diagram.size, Size.getHeight model.diagram.size )
                , position = model.diagram.position
                , isFullscreen = model.diagram.isFullscreen
                }
            , settings = model.settings |> DiagramSettings.scale.set (model.settings.scale |> Maybe.map (Scale.add step))
        }


zoomOut : Scale -> Model -> Return Msg Model
zoomOut step model =
    Return.singleton
        { model
            | diagram =
                { size = ( Size.getWidth model.diagram.size, Size.getHeight model.diagram.size )
                , position = model.diagram.position
                , isFullscreen = model.diagram.isFullscreen
                }
            , settings = model.settings |> DiagramSettings.scale.set (model.settings.scale |> Maybe.map (\s -> Scale.sub s step))
        }
