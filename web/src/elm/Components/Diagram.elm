module Components.Diagram exposing (init, update, view)

import Basics exposing (max)
import Browser.Dom as Dom
import Constants exposing (inputPrefix)
import Data.Color as Color
import Data.Item as Item exposing (Item, ItemType(..), Items)
import Data.Position as Position
import Data.Size as Size exposing (Size)
import Data.Text as Text
import Html exposing (Html, div)
import Html.Attributes as Attr
import Html.Events.Extra.Mouse as Mouse
import Html.Events.Extra.Touch as Touch
import Html.Events.Extra.Wheel as Wheel
import Html5.DragDrop as DragDrop
import List
import List.Extra exposing (findIndex, getAt, scanl, splitAt)
import Models.Diagram as Diagram exposing (Model, Msg(..), Settings)
import Models.Views.BusinessModelCanvas as BusinessModelCanvasModel
import Models.Views.ER as ErDiagramModel
import Models.Views.EmpathyMap as EmpathyMapModel
import Models.Views.FourLs as FourLsModel
import Models.Views.Kanban as KanbanModel
import Models.Views.Kpt as KptModel
import Models.Views.OpportunityCanvas as OpportunityCanvasModel
import Models.Views.StartStopContinue as StartStopContinueModel
import Models.Views.Table as TableModel
import Models.Views.UserPersona as UserPersonaModel
import Result exposing (andThen)
import String
import Svg exposing (Svg, defs, feComponentTransfer, feFuncA, feGaussianBlur, feMerge, feMergeNode, feOffset, filter, g, svg, text)
import Svg.Attributes exposing (class, dx, dy, fill, height, id, in_, result, slope, stdDeviation, style, transform, type_, viewBox, width)
import Svg.Events exposing (onClick)
import Svg.Lazy exposing (lazy, lazy2)
import Task
import TextUSM.Enum.Diagram exposing (Diagram(..))
import Utils
import Views.Diagram.BusinessModelCanvas as BusinessModelCanvas
import Views.Diagram.CardSettings as CardSettings
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
import Views.Diagram.SiteMap as SiteMap
import Views.Diagram.StartStopContinue as StartStopContinue
import Views.Diagram.Table as Table
import Views.Diagram.UserPersona as UserPersona
import Views.Diagram.UserStoryMap as UserStoryMap
import Views.Empty as Empty
import Views.Icon as Icon


type alias Hierarchy =
    Int


indentSpace : Int
indentSpace =
    4


init : Settings -> ( Model, Cmd Msg )
init settings =
    ( { items = Item.empty
      , data = Diagram.Empty
      , size = ( 0, 0 )
      , svg =
            { width = 0
            , height = 0
            , scale = 1.0
            }
      , moveStart = False
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
      }
    , Cmd.none
    )


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

                        ( displayText, color, backgroundColor ) =
                            case String.split "," x of
                                [ t, c, b ] ->
                                    ( t, Just c, Just b )

                                [ t, b ] ->
                                    ( t, Nothing, Just b )

                                _ ->
                                    ( x, Nothing, Nothing )
                    in
                    ( indent :: xsIndent ++ otherIndents
                    , Item.cons
                        { lineNo = lineNo
                        , text = displayText
                        , color = Maybe.andThen (\c -> Just <| Color.fromString c) color
                        , backgroundColor = Maybe.andThen (\c -> Just <| Color.fromString c) backgroundColor
                        , itemType = getItemType x indent
                        , children = Item.childrenFromItems xsItems
                        }
                        (Item.filter (\item -> item.itemType /= Comments) otherItems)
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


countUpToHierarchy : Int -> Items -> List Int
countUpToHierarchy hierarchy items =
    let
        countUp : Items -> List (List Int)
        countUp countItems =
            [ countItems
                |> Item.filter (\x -> x.itemType /= Tasks && x.itemType /= Activities)
                |> Item.length
            ]
                :: (countItems
                        |> Item.map
                            (\it ->
                                let
                                    results =
                                        countUp (Item.unwrapChildren it.children)
                                            |> Utils.transpose
                                in
                                if List.length results > hierarchy then
                                    List.map
                                        (\it2 ->
                                            List.maximum it2 |> Maybe.withDefault 0
                                        )
                                        results

                                else
                                    results
                                        |> List.concat
                                        |> List.filter (\x -> x /= 0)
                            )
                   )
    in
    1
        :: 1
        :: (countUp items
                |> Utils.transpose
                |> List.map
                    (\it ->
                        List.maximum it |> Maybe.withDefault 0
                    )
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
        , if model.moveStart then
            Attr.style "cursor" "grabbing"

          else
            Attr.style "cursor" "grab"
        ]
        [ if model.settings.zoomControl |> Maybe.withDefault model.showZoomControl then
            lazy2 zoomControl model.fullscreen model.svg.scale

          else
            Empty.view
        , lazy svgView model
        , CardSettings.view {}
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
        , onDragMove model.touchDistance model.moveStart (Utils.isPhone <| Size.getWidth model.size)
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
            , if model.moveStart then
                style "will-change: transform;"

              else
                style "will-change: transform;transition: transform 0.15s ease"
            ]
            [ mainSvg ]
        ]


onDragStart : Maybe Item -> Bool -> Svg.Attribute Msg
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
                        Start ( round x, round y )
                )

        ( Nothing, False ) ->
            Mouse.onDown
                (\event ->
                    let
                        ( x, y ) =
                            event.pagePos
                    in
                    Start ( round x, round y )
                )

        _ ->
            Attr.style "" ""


onDragMove : Maybe Float -> Bool -> Bool -> Svg.Attribute Msg
onDragMove distance isDragStart isPhone =
    case ( isDragStart, isPhone ) of
        ( True, True ) ->
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

        ( True, False ) ->
            Mouse.onMove
                (\event ->
                    let
                        ( x, y ) =
                            event.pagePos
                    in
                    Move ( round x, round y )
                )

        _ ->
            Attr.style "" ""


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
                    Diagram.UserStoryMap items hierarchy (countUpToHierarchy (hierarchy - 2) items) (scanl (\it v -> v + Item.length (Item.unwrapChildren it.children)) 0 (Item.unwrap items))

                Table ->
                    Diagram.Table <| TableModel.fromItems items

                Kpt ->
                    Diagram.Kpt <| KptModel.fromItems items

                BusinessModelCanvas ->
                    Diagram.BusinessModelCanvas <| BusinessModelCanvasModel.fromItems items

                EmpathyMap ->
                    Diagram.EmpathyMap <| EmpathyMapModel.fromItems items

                Fourls ->
                    Diagram.FourLs <| FourLsModel.fromItems items

                Kanban ->
                    Diagram.Kanban <| KanbanModel.fromItems items

                OpportunityCanvas ->
                    Diagram.OpportunityCanvas <| OpportunityCanvasModel.fromItems items

                StartStopContinue ->
                    Diagram.StartStopContinue <| StartStopContinueModel.fromItems items

                UserPersona ->
                    Diagram.UserPersona <| UserPersonaModel.fromItems items

                ErDiagram ->
                    Diagram.ErDiagram <| ErDiagramModel.fromItems items

                MindMap ->
                    Diagram.MindMap items hierarchy

                ImpactMap ->
                    Diagram.ImpactMap items hierarchy

                SiteMap ->
                    Diagram.SiteMap items hierarchy

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


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        NoOp ->
            ( model, Cmd.none )

        Init settings window text ->
            let
                width =
                    round window.viewport.width

                height =
                    round window.viewport.height - 50

                model_ =
                    updateDiagram ( width, height ) model text
            in
            ( { model_ | settings = settings }, Cmd.none )

        ZoomIn ->
            ( if model.svg.scale <= 5.0 then
                { model
                    | svg =
                        { width = model.svg.width
                        , height = model.svg.height
                        , scale = model.svg.scale + 0.05
                        }
                }

              else
                model
            , Cmd.none
            )

        ZoomOut ->
            ( if model.svg.scale > 0.05 then
                { model
                    | svg =
                        { width = model.svg.width
                        , height = model.svg.height
                        , scale = model.svg.scale - 0.05
                        }
                }

              else
                model
            , Cmd.none
            )

        PinchIn distance ->
            ( { model | touchDistance = Just distance }, Task.perform identity (Task.succeed ZoomIn) )

        PinchOut distance ->
            ( { model | touchDistance = Just distance }, Task.perform identity (Task.succeed ZoomOut) )

        OnChangeText text ->
            let
                model_ =
                    updateDiagram model.size model text
            in
            ( model_, Cmd.none )

        Start pos ->
            ( { model
                | moveStart = True
                , movePosition = pos
              }
            , Cmd.none
            )

        Stop ->
            ( { model
                | moveStart = False
                , movePosition = Position.zero
                , touchDistance = Nothing
              }
            , Cmd.none
            )

        Move ( x, y ) ->
            ( if not model.moveStart || (x == Position.getX model.movePosition && y == Position.getY model.movePosition) then
                model

              else
                { model
                    | position =
                        ( Position.getX model.position + round (toFloat (x - Position.getX model.movePosition) * model.svg.scale)
                        , Position.getY model.position + round (toFloat (y - Position.getY model.movePosition) * model.svg.scale)
                        )
                    , movePosition = ( x, y )
                }
            , Cmd.none
            )

        MoveTo position ->
            ( { model
                | position = position
                , movePosition = ( 0, 0 )
              }
            , Cmd.none
            )

        ToggleFullscreen ->
            ( { model
                | movePosition = ( 0, 0 )
                , fullscreen = not model.fullscreen
              }
            , Cmd.none
            )

        OnResize width height ->
            ( { model
                | size = ( width, height - 56 )
                , movePosition = ( 0, 0 )
              }
            , Cmd.none
            )

        StartPinch distance ->
            ( { model | touchDistance = Just distance }, Cmd.none )

        EditSelectedItem text ->
            ( { model | selectedItem = Maybe.andThen (\i -> Just { i | text = " " ++ String.trimLeft text }) model.selectedItem }
            , Cmd.none
            )

        DeselectItem ->
            ( { model | selectedItem = Nothing }, Cmd.none )

        DragDropMsg msg_ ->
            let
                ( model_, result ) =
                    DragDrop.update msg_ model.dragDrop

                move =
                    Maybe.map (\( fromNo, toNo, _ ) -> ( fromNo, toNo )) result
            in
            case move of
                Just ( fromNo, toNo ) ->
                    ( { model | dragDrop = model_ }, Task.perform MoveItem (Task.succeed ( fromNo, toNo )) )

                Nothing ->
                    ( { model | dragDrop = model_ }, Cmd.none )

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
            ( { model | svg = newSvgModel, position = position }, Cmd.none )

        Select item ->
            ( { model | selectedItem = item }
            , case item of
                Just _ ->
                    Task.attempt (\_ -> NoOp) (Dom.focus "edit-item")

                Nothing ->
                    Cmd.none
            )

        _ ->
            ( model, Cmd.none )
