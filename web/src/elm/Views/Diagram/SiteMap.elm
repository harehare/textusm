module Views.Diagram.SiteMap exposing (view)

import Constants
import List.Extra as ListEx
import Models.Diagram exposing (Model, Msg, SelectedItem)
import Models.DiagramSettings as DiagramSettings
import Models.Item as Item exposing (Item, Items)
import Models.Position exposing (Position)
import Models.Property exposing (Property)
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Svg.Styled.Lazy as Lazy
import Views.Diagram.Card as Card


view : Model -> Svg Msg
view model =
    let
        rootItem : Maybe Item
        rootItem =
            Item.head model.items
    in
    case rootItem of
        Just root ->
            let
                items : Items
                items =
                    Item.unwrapChildren <| Item.getChildren root
            in
            Svg.g
                []
                [ siteView model.settings model.property ( 0, Constants.itemSpan + model.settings.size.height ) model.selectedItem items
                , Lazy.lazy Card.viewWithDefaultColor
                    { settings = model.settings
                    , property = model.property
                    , position = ( 0, 0 )
                    , selectedItem = model.selectedItem
                    , item = root
                    , canMove = True
                    }
                ]

        Nothing ->
            Svg.g [] []


siteLineView : DiagramSettings.Settings -> Position -> Position -> Svg Msg
siteLineView settings ( xx1, yy1 ) ( xx2, yy2 ) =
    let
        centerX : Int
        centerX =
            settings.size.width // 2
    in
    if xx1 == xx2 then
        Svg.line
            [ SvgAttr.x1 <| String.fromInt <| xx1 + centerX
            , SvgAttr.y1 <| String.fromInt yy1
            , SvgAttr.x2 <| String.fromInt <| xx2 + centerX
            , SvgAttr.y2 <| String.fromInt yy2
            , SvgAttr.stroke settings.color.line
            , SvgAttr.strokeWidth "1"
            ]
            []

    else
        Svg.g []
            [ Svg.line
                [ SvgAttr.x1 <| String.fromInt <| xx1 + centerX
                , SvgAttr.y1 <| String.fromInt <| yy1 + settings.size.height + Constants.itemSpan // 2
                , SvgAttr.x2 <| String.fromInt <| xx2 + centerX
                , SvgAttr.y2 <| String.fromInt <| yy1 + settings.size.height + Constants.itemSpan // 2
                , SvgAttr.stroke settings.color.line
                , SvgAttr.strokeWidth "1"
                ]
                []
            , Svg.line
                [ SvgAttr.x1 <| String.fromInt <| xx2 + centerX
                , SvgAttr.y1 <| String.fromInt <| yy1 + settings.size.height + Constants.itemSpan // 2
                , SvgAttr.x2 <| String.fromInt <| xx2 + centerX
                , SvgAttr.y2 <| String.fromInt <| yy2
                , SvgAttr.stroke settings.color.line
                , SvgAttr.strokeWidth "1"
                ]
                []
            ]


siteTreeLineView : DiagramSettings.Settings -> Position -> Position -> Svg Msg
siteTreeLineView settings ( xx1, yy1 ) ( xx2, yy2 ) =
    let
        itemPadding : Int
        itemPadding =
            Constants.itemSpan // 2
    in
    Svg.g []
        [ Svg.line
            [ SvgAttr.x1 <| String.fromInt <| xx1 + itemPadding
            , SvgAttr.y1 <| String.fromInt <| yy1
            , SvgAttr.x2 <| String.fromInt <| xx1 + itemPadding
            , SvgAttr.y2 <| String.fromInt <| yy2 + settings.size.height // 2
            , SvgAttr.stroke settings.color.line
            , SvgAttr.strokeWidth "1"
            ]
            []
        , Svg.line
            [ SvgAttr.x1 <| String.fromInt <| xx1 + itemPadding
            , SvgAttr.y1 <| String.fromInt <| yy2 + settings.size.height // 2
            , SvgAttr.x2 <| String.fromInt <| xx2 + settings.size.width
            , SvgAttr.y2 <| String.fromInt <| yy2 + settings.size.height // 2
            , SvgAttr.stroke settings.color.line
            , SvgAttr.strokeWidth "1"
            ]
            []
        ]


siteTreeView : DiagramSettings.Settings -> Property -> Position -> SelectedItem -> Items -> Svg Msg
siteTreeView settings property ( posX, posY ) selectedItem items =
    let
        childrenCountList : List Int
        childrenCountList =
            0
                :: (items
                        |> Item.map
                            (\i ->
                                if Item.isEmpty (Item.unwrapChildren <| Item.getChildren i) then
                                    0

                                else
                                    Item.getChildrenCount i
                            )
                        |> ListEx.scanl1 (+)
                   )
    in
    Svg.g []
        (ListEx.zip childrenCountList (Item.unwrap items)
            |> List.indexedMap
                (\i ( childrenCount, item ) ->
                    let
                        children : Items
                        children =
                            Item.unwrapChildren <| Item.getChildren item

                        x : Int
                        x =
                            posX + Constants.itemSpan

                        y : Int
                        y =
                            posY + i * (settings.size.height + Constants.itemSpan) + childrenCount * (settings.size.height + Constants.itemSpan)
                    in
                    [ siteTreeLineView settings ( posX, posY - Constants.itemSpan ) ( posX, y )
                    , Card.viewWithDefaultColor
                        { settings = settings
                        , property = property
                        , position = ( x, y )
                        , selectedItem = selectedItem
                        , item = item
                        , canMove = True
                        }
                    , siteTreeView settings
                        property
                        ( x
                        , y + (settings.size.height + Constants.itemSpan)
                        )
                        selectedItem
                        children
                    ]
                )
            |> List.concat
        )


siteView : DiagramSettings.Settings -> Property -> ( Int, Int ) -> SelectedItem -> Items -> Svg Msg
siteView settings property ( posX, posY ) selectedItem items =
    let
        hierarchyCountList : List Int
        hierarchyCountList =
            0
                :: Item.map (\item -> Item.getHierarchyCount item - 1) items
                |> ListEx.scanl1 (+)
    in
    Svg.g []
        (ListEx.zip hierarchyCountList (Item.unwrap items)
            |> List.indexedMap
                (\i ( hierarchyCount, item ) ->
                    let
                        cardWidth : Int
                        cardWidth =
                            settings.size.width + Constants.itemSpan

                        children : Items
                        children =
                            Item.unwrapChildren <| Item.getChildren item

                        x : Int
                        x =
                            posX
                                + i
                                * (cardWidth + Constants.itemSpan)
                                + hierarchyCount
                                * Constants.itemSpan
                    in
                    [ Card.viewWithDefaultColor
                        { settings = settings
                        , property = property
                        , position = ( x, posY )
                        , selectedItem = selectedItem
                        , item = item
                        , canMove = True
                        }
                    , siteLineView settings ( 0, 0 ) ( x, posY )
                    , siteTreeView settings
                        property
                        ( x
                        , posY + settings.size.height + Constants.itemSpan
                        )
                        selectedItem
                        children
                    ]
                )
            |> List.concat
        )
