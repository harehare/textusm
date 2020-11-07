module Components.Diagram exposing (init, update, view)

import Basics exposing (max)
import Browser.Dom as Dom
import Constants exposing (indentSpace, inputPrefix)
import Data.Color as Color
import Data.FontStyle as FontStyle
import Data.Item as Item exposing (Item, ItemType(..), Items)
import Data.Position as Position
import Data.Size as Size exposing (Size)
import Data.Text as Text
import Events
import File
import Html exposing (Html, div)
import Html.Attributes as Attr
import Html.Events as E
import Html.Events.Extra.Mouse as Mouse
import Html.Events.Extra.Touch as Touch
import Html.Events.Extra.Wheel as Wheel
import Html5.DragDrop as DragDrop
import Json.Decode as D
import List
import List.Extra exposing (findIndex, getAt, removeAt, setAt, splitAt)
import Models.Diagram as Diagram exposing (DragStatus(..), Model, Msg(..), SelectedItem, Settings)
import Models.Views.BusinessModelCanvas as BusinessModelCanvasModel
import Models.Views.ER as ErDiagramModel
import Models.Views.EmpathyMap as EmpathyMapModel
import Models.Views.FourLs as FourLsModel
import Models.Views.Kanban as KanbanModel
import Models.Views.Kpt as KptModel
import Models.Views.OpportunityCanvas as OpportunityCanvasModel
import Models.Views.SequenceDiagram as SequenceDiagramModel
import Models.Views.StartStopContinue as StartStopContinueModel
import Models.Views.Table as TableModel
import Models.Views.UserPersona as UserPersonaModel
import Models.Views.UserStoryMap as UserStoryMapModel
import Ports
import Result exposing (andThen)
import Return as Return exposing (Return)
import String
import Svg exposing (Svg, defs, feComponentTransfer, feFuncA, feGaussianBlur, feMerge, feMergeNode, feOffset, filter, g, svg, text)
import Svg.Attributes exposing (class, dx, dy, fill, height, id, in_, result, slope, stdDeviation, style, transform, type_, viewBox, width)
import Svg.Events exposing (onClick)
import Svg.Lazy exposing (lazy, lazy2)
import Task
import TextUSM.Enum.Diagram exposing (Diagram(..))
import Utils
import Views.Diagram.BusinessModelCanvas as BusinessModelCanvas
import Views.Diagram.ContextMenu as ContextMenu
import Views.Diagram.ER as ER
import Views.Diagram.EmpathyMap as EmpathyMap
import Views.Diagram.FourLs as FourLs
import Views.Diagram.GanttChart as GanttChart
import Views.Diagram.ImpactMap as ImpactMap
import Views.Diagram.Kanban as Kanban
import Views.Diagram.Kpt as Kpt
import Views.Diagram.Markdown as Markdown
import Views.Diagram.MindMap as MindMap
import Views.Diagram.OpportunityCanvas as OpportunityCanvas
import Views.Diagram.SequenceDiagram as SequenceDiagram
import Views.Diagram.SiteMap as SiteMap
import Views.Diagram.StartStopContinue as StartStopContinue
import Views.Diagram.Table as Table
import Views.Diagram.UserPersona as UserPersona
import Views.Diagram.UserStoryMap as UserStoryMap
import Views.Empty as Empty
import Views.Icon as Icon


type alias Hierarchy =
    Int


init : Settings -> Return Msg Model
init settings =
    Return.singleton
        { items = Item.empty
        , data = Diagram.Empty
        , size = ( 0, 0 )
        , svg =
            { width = 0
            , height = 0
            , scale = 1.0
            }
        , moveState = Diagram.NotMove
        , position = ( 0, 20 )
        , movePosition = ( 0, 0 )
        , fullscreen = False
        , showZoomControl = True
        , touchDistance = Nothing
        , settings = settings
        , diagramType = UserStoryMap
        , text = Text.empty
        , matchParent = False
        , selectedItem = Nothing
        , dragDrop = DragDrop.init
        , contextMenu = Nothing
        , dragStatus = NoDrag
        }


getItemType : String -> Int -> ItemType
getItemType text indent =
    if text |> String.trim |> String.startsWith "#" then
        Comments

    else
        case indent of
            0 ->
                Activities

            1 ->
                Tasks

            _ ->
                Stories (indent - 1)


hasIndent : Int -> String -> Bool
hasIndent indent text =
    let
        lineinputPrefix =
            String.repeat indent inputPrefix
    in
    if indent == 0 then
        String.left 1 text /= " "

    else
        String.startsWith lineinputPrefix text
            && (String.slice (indent * indentSpace) (indent * indentSpace + 1) text /= " ")


parse : Int -> String -> ( List String, List String )
parse indent text =
    let
        line =
            String.lines text
                |> List.filter
                    (\x ->
                        let
                            str =
                                x |> String.trim
                        in
                        not (String.isEmpty str)
                    )

        tail =
            List.tail line
    in
    case tail of
        Just t ->
            case
                t
                    |> findIndex (hasIndent indent)
            of
                Just xs ->
                    splitAt (xs + 1) line

                Nothing ->
                    ( line, [] )

        Nothing ->
            ( [], [] )


load : String -> ( Hierarchy, Items )
load text =
    let
        loadText : Int -> Int -> String -> ( List Hierarchy, Items )
        loadText lineNo indent input =
            case parse indent input of
                ( x :: xs, other ) ->
                    let
                        ( xsIndent, xsItems ) =
                            loadText (lineNo + 1) (indent + 1) (String.join "\n" xs)

                        ( otherIndents, otherItems ) =
                            loadText (lineNo + List.length (x :: xs)) indent (String.join "\n" other)

                        itemType =
                            getItemType x indent
                    in
                    case itemType of
                        Comments ->
                            ( indent :: xsIndent ++ otherIndents
                            , Item.filter (\item -> Item.getItemType item /= Comments) otherItems
                            )

                        _ ->
                            ( indent :: xsIndent ++ otherIndents
                            , Item.cons
                                (Item.new
                                    |> Item.withLineNo lineNo
                                    |> Item.withText x
                                    |> Item.withItemType itemType
                                    |> Item.withChildren (Item.childrenFromItems xsItems)
                                )
                                (Item.filter (\item -> Item.getItemType item /= Comments) otherItems)
                            )

                ( [], _ ) ->
                    ( [ indent ], Item.empty )
    in
    if String.isEmpty text then
        ( 0, Item.empty )

    else
        let
            ( indentList, loadedItems ) =
                loadText 0 0 text
        in
        ( indentList
            |> List.maximum
            |> Maybe.map (\x -> x - 1)
            |> Maybe.withDefault 0
        , loadedItems
        )


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
        , Events.onDrop OnDropFiles
        , E.preventDefaultOn "dragover" <|
            D.succeed ( ChangeDragStatus DragOver, True )
        , E.preventDefaultOn "dragleave" <|
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

        Markdown ->
            Markdown.view

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


svgView : Model -> Svg Msg
svgView model =
    let
        svgWidth =
            if model.fullscreen then
                Basics.toFloat
                    (Basics.max model.svg.width (Size.getWidth model.size))
                    |> round
                    |> String.fromInt

            else
                Basics.toFloat
                    (Size.getWidth model.size)
                    |> round
                    |> String.fromInt

        svgHeight =
            if model.fullscreen then
                Basics.toFloat
                    (Basics.max model.svg.height (Size.getHeight model.size))
                    |> round
                    |> String.fromInt

            else
                Basics.toFloat
                    (Size.getHeight model.size)
                    |> round
                    |> String.fromInt

        mainSvg =
            lazy (diagramView model.diagramType) model
    in
    svg
        [ Attr.id "usm"
        , width
            (String.fromInt
                (if Utils.isPhone (Size.getWidth model.size) || model.fullscreen then
                    Size.getWidth model.size

                 else if Size.getWidth model.size - 56 > 0 then
                    Size.getWidth model.size - 56

                 else
                    0
                )
            )
        , height
            (String.fromInt <|
                if model.fullscreen then
                    Size.getHeight model.size + 56

                else
                    Size.getHeight model.size
            )
        , viewBox ("0 0 " ++ svgWidth ++ " " ++ svgHeight)
        , Attr.style "background-color" model.settings.backgroundColor
        , Wheel.onWheel chooseZoom
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
                    ++ String.fromInt (Position.getX model.position)
                    ++ ","
                    ++ String.fromInt (Position.getY model.position)
                    ++ "), scale("
                    ++ String.fromFloat model.svg.scale
                    ++ ","
                    ++ String.fromFloat model.svg.scale
                    ++ ")"
                )
            , fill model.settings.backgroundColor
            , case model.moveState of
                Diagram.NotMove ->
                    style "will-change: transform;transition: transform 0.15s ease"

                _ ->
                    style "will-change: transform;"
            ]
            [ mainSvg ]
        , case ( model.selectedItem, model.contextMenu ) of
            ( Just ( item_, _ ), Just ( contextMenu, position ) ) ->
                let
                    ( posX, posY ) =
                        position

                    ( offsetX, offsetY ) =
                        model.position
                in
                ContextMenu.view
                    { state = contextMenu
                    , item = item_
                    , position =
                        ( floor <| toFloat (posX + offsetX) * model.svg.scale
                        , floor <| toFloat (posY + offsetY) * model.svg.scale
                        )
                    , onMenuSelect = OnSelectContextMenu
                    , onColorChanged = OnColorChanged Diagram.ColorSelectMenu
                    , onBackgroundColorChanged = OnColorChanged Diagram.BackgroundColorSelectMenu
                    , onFontStyleChanged = OnFontStyleChanged
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
            load text

        newModel =
            { base | items = items }

        ( svgWidth, svgHeight ) =
            Utils.getCanvasSize newModel

        data =
            case base.diagramType of
                UserStoryMap ->
                    Diagram.UserStoryMap <| UserStoryMapModel.from hierarchy text items

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

                _ ->
                    Diagram.Items items
    in
    { newModel
        | size = ( width, height )
        , data = data
        , svg =
            { width = svgWidth
            , height = svgHeight
            , scale = base.svg.scale
            }
        , movePosition = ( 0, 0 )
        , text = Text.edit base.text text
    }


itemToColorText : Item -> String
itemToColorText item =
    case ( Item.getColor item, Item.getBackgroundColor item ) of
        ( Just color, Just backgroundColor ) ->
            "," ++ Color.toString color ++ "," ++ Color.toString backgroundColor

        ( Just color, Nothing ) ->
            "," ++ Color.toString color

        ( Nothing, Just backgroundColor ) ->
            "," ++ "," ++ Color.toString backgroundColor

        _ ->
            ""


clearPosition : Model -> Return Msg Model
clearPosition model =
    Return.singleton { model | movePosition = ( 0, 0 ) }


selectLine : Int -> Model -> Return Msg Model
selectLine lineNo model =
    Return.return model (Ports.selectLine <| lineNo + 1)


setFocus : String -> Model -> Return Msg Model
setFocus id model =
    Return.return model (Task.attempt (\_ -> NoOp) <| Dom.focus id)


setText : String -> Model -> Return Msg Model
setText text model =
    Return.singleton { model | text = Text.change <| Text.fromString text }


setLine : Int -> List String -> String -> Model -> Return Msg Model
setLine lineNo lines line model =
    let
        text =
            setAt lineNo line lines
                |> String.join "\n"
    in
    setText text model


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
    if model.svg.scale <= 5.0 then
        Return.singleton
            { model
                | svg =
                    { width = model.svg.width
                    , height = model.svg.height
                    , scale = model.svg.scale + 0.05
                    }
            }

    else
        Return.singleton model


zoomOut : Model -> Return Msg Model
zoomOut model =
    if model.svg.scale > 0.05 then
        Return.singleton
            { model
                | svg =
                    { width = model.svg.width
                    , height = model.svg.height
                    , scale = model.svg.scale - 0.05
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
            case model.moveState of
                Diagram.ItemMove target ->
                    case target of
                        Diagram.TableTarget table ->
                            let
                                (ErDiagramModel.Table _ _  _ lineNo) =
                                    table
                            in
                            stopMove model
                                |> Return.andThen (setLine lineNo (Text.lines model.text) (ErDiagramModel.tableToLineString table))
                                |> Return.andThen loadTextToEditor

                        Diagram.ItemTarget _ ->
                            stopMove model

                _ ->
                    stopMove model

        Move ( x, y ) ->
            Return.singleton <|
                if not (Diagram.isMoving model.moveState) || (x == Position.getX model.movePosition && y == Position.getY model.movePosition) then
                    model

                else
                    case model.moveState of
                        Diagram.BoardMove ->
                            { model
                                | position =
                                    ( Position.getX model.position + round (toFloat (x - Position.getX model.movePosition) / model.svg.scale)
                                    , Position.getY model.position + round (toFloat (y - Position.getY model.movePosition) / model.svg.scale)
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
                                            position
                                                |> Maybe.andThen
                                                    (\p ->
                                                        Just
                                                            ( Position.getX p + round (toFloat (x - Position.getX model.movePosition) / model.svg.scale)
                                                            , Position.getY p + round (toFloat (y - Position.getY model.movePosition) / model.svg.scale)
                                                            )
                                                    )
                                                |> Maybe.withDefault ( x - Position.getX model.movePosition, y - Position.getY model.movePosition )
                                                |> Just
                                    in
                                    { model
                                        | moveState =
                                            Diagram.ItemMove <|
                                                Diagram.TableTarget (ErDiagramModel.Table name columns newPosition lineNo)
                                        , movePosition = ( x, y )
                                    }

                                Diagram.ItemTarget _ ->
                                    model

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
            Return.singleton { model | selectedItem = Maybe.andThen (\( i, _ ) -> Just ( i |> Item.withText (" " ++ String.trimLeft text), False )) model.selectedItem }

        DragDropMsg msg_ ->
            let
                ( model_, result ) =
                    DragDrop.update msg_ model.dragDrop

                move =
                    Maybe.map (\( fromNo, toNo, _ ) -> ( fromNo, toNo )) result
            in
            case ( move, model.selectedItem ) of
                ( Just ( fromNo, toNo ), _ ) ->
                    ( { model | dragDrop = model_ }, Task.perform MoveItem (Task.succeed ( fromNo, toNo )) )

                ( Nothing, Just ( item, _ ) ) ->
                    case DragDrop.getDragId model.dragDrop of
                        Just id_ ->
                            if Item.getLineNo item == id_ then
                                Return.singleton { model | dragDrop = model_, selectedItem = Just ( item, True ) }

                            else
                                Return.singleton { model | dragDrop = model_, selectedItem = Just ( item, False ) }

                        Nothing ->
                            Return.singleton { model | dragDrop = model_, selectedItem = Just ( item, False ) }

                ( Nothing, _ ) ->
                    Return.singleton { model | dragDrop = model_, selectedItem = Maybe.andThen (\( item_, _ ) -> Just ( item_, False )) model.selectedItem }

        FitToWindow ->
            let
                ( windowWidth, windowHeight ) =
                    model.size

                ( canvasWidth, canvasHeight ) =
                    Utils.getCanvasSize model

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
                    |> Return.andThen (selectLine <| Item.getLineNo item)

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
                                |> Utils.getSpacePrefix

                        text =
                            setAt (Item.getLineNo item) (prefix ++ String.trimLeft (Item.getText item ++ itemToColorText selectedItem)) lines
                                |> String.join "\n"
                    in
                    setText text model
                        |> Return.andThen clearSelectedItem

                _ ->
                    Return.singleton model

        OnSelectContextMenu menu ->
            Return.singleton { model | contextMenu = Maybe.andThen (\c -> Just <| Tuple.mapFirst (\_ -> menu) c) model.contextMenu }

        OnColorChanged menu color ->
            case model.selectedItem of
                Just ( item, _ ) ->
                    let
                        lines =
                            Text.lines model.text

                        currentText =
                            getAt (Item.getLineNo item) lines

                        tokens =
                            Maybe.map (String.split ",") currentText

                        text =
                            case ( menu, tokens ) of
                                ( Diagram.ColorSelectMenu, Just [ t, _, b ] ) ->
                                    t ++ "," ++ Color.toString color ++ "," ++ b

                                ( Diagram.ColorSelectMenu, Just [ t, _ ] ) ->
                                    t ++ "," ++ Color.toString color

                                ( Diagram.ColorSelectMenu, Just [ t ] ) ->
                                    t ++ "," ++ Color.toString color

                                ( Diagram.ColorSelectMenu, Nothing ) ->
                                    currentText |> Maybe.withDefault ""

                                ( Diagram.BackgroundColorSelectMenu, Just [ t, c, _ ] ) ->
                                    t ++ "," ++ c ++ "," ++ Color.toString color

                                ( Diagram.BackgroundColorSelectMenu, Just [ t, c ] ) ->
                                    t ++ "," ++ c ++ "," ++ Color.toString color

                                ( Diagram.BackgroundColorSelectMenu, Just [ t ] ) ->
                                    t ++ "," ++ "," ++ Color.toString color

                                ( Diagram.BackgroundColorSelectMenu, Nothing ) ->
                                    currentText |> Maybe.withDefault ""

                                _ ->
                                    currentText |> Maybe.withDefault ""

                        prefix =
                            currentText
                                |> Maybe.withDefault ""
                                |> Utils.getSpacePrefix

                        updateText =
                            setAt (Item.getLineNo item) (prefix ++ String.trimLeft text) lines
                                |> String.join "\n"
                    in
                    case ( model.selectedItem, menu ) of
                        ( Just ( i, _ ), Diagram.ColorSelectMenu ) ->
                            Return.singleton { model | contextMenu = Maybe.andThen (\c -> Just <| Tuple.mapFirst (\_ -> menu) c) model.contextMenu }
                                |> Return.andThen (setText updateText)
                                |> Return.andThen (selectItem (Just ( Item.withColor (Just color) i, False )))

                        ( Just ( i, _ ), Diagram.BackgroundColorSelectMenu ) ->
                            Return.singleton { model | contextMenu = Maybe.andThen (\c -> Just <| Tuple.mapFirst (\_ -> menu) c) model.contextMenu }
                                |> Return.andThen (setText updateText)
                                |> Return.andThen (selectItem (Just ( Item.withBackgroundColor (Just color) i, False )))

                        _ ->
                            Return.singleton model

                Nothing ->
                    Return.singleton model

        OnFontStyleChanged style ->
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
                                |> Utils.getSpacePrefix

                        text =
                            currentText
                                |> String.split ","
                                |> List.head
                                |> Maybe.withDefault ""

                        updateText =
                            setAt (Item.getLineNo item) (prefix ++ (String.trimLeft text |> FontStyle.apply style) ++ itemToColorText item) lines
                                |> String.join "\n"
                    in
                    setText updateText model

                Nothing ->
                    Return.singleton model

        MoveItem ( fromNo, toNo ) ->
            let
                lines =
                    Text.lines model.text

                toPrefix =
                    getAt toNo lines
                        |> Maybe.withDefault ""
                        |> Utils.getSpacePrefix

                from =
                    toPrefix
                        ++ (getAt fromNo lines
                                |> Maybe.withDefault ""
                                |> String.trimLeft
                           )

                newLines =
                    removeAt fromNo lines

                ( left, right ) =
                    splitAt
                        (if fromNo < toNo then
                            toNo - 1

                         else
                            toNo
                        )
                        newLines

                text =
                    left
                        ++ from
                        :: right
                        |> String.join "\n"
            in
            setText text model
                |> Return.andThen clearSelectedItem

        OnDropFiles files ->
            ( { model | dragStatus = NoDrag }
            , List.filter (\file -> File.mime file |> String.startsWith "image/") files
                |> List.map File.toUrl
                |> Task.sequence
                |> Task.perform OnLoadFiles
            )

        OnLoadFiles files ->
            Return.return model (Ports.insertTextLines files)

        ChangeDragStatus status ->
            Return.singleton { model | dragStatus = status }
