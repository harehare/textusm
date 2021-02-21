module Views.Diagram.SiteMap exposing (view)

import Constants
import Data.Item as Item exposing (Items)
import Data.Position exposing (Position)
import List.Extra as ListEx
import Models.Diagram exposing (Model, Msg(..), SelectedItem, Settings)
import Svg exposing (Svg)
import Svg.Attributes as SvgAttr
import Views.Diagram.Views as Views


view : Model -> Svg Msg
view model =
    let
        rootItem =
            Item.head model.items
    in
    case rootItem of
        Just root ->
            let
                items =
                    Item.unwrapChildren <| Item.getChildren root
            in
            Svg.g
                []
                [ siteView model.settings ( 0, Constants.itemSpan + model.settings.size.height ) model.selectedItem items
                , Views.card
                    { settings = model.settings
                    , position = ( 0, 0 )
                    , selectedItem = model.selectedItem
                    , item = root
                    , canMove = False
                    }
                ]

        Nothing ->
            Svg.g [] []


siteView : Settings -> ( Int, Int ) -> SelectedItem -> Items -> Svg Msg
siteView settings ( posX, posY ) selectedItem items =
    let
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
                        children =
                            Item.unwrapChildren <| Item.getChildren item

                        cardWidth =
                            settings.size.width + Constants.itemSpan

                        x =
                            posX
                                + i
                                * (cardWidth + Constants.itemSpan)
                                + hierarchyCount
                                * Constants.itemSpan
                    in
                    [ Views.card
                        { settings = settings
                        , position = ( x, posY )
                        , selectedItem = selectedItem
                        , item = item
                        , canMove = False
                        }
                    , siteLineView settings ( 0, 0 ) ( x, posY )
                    , siteTreeView settings
                        ( x
                        , posY + settings.size.height + Constants.itemSpan
                        )
                        selectedItem
                        children
                    ]
                )
            |> List.concat
        )


siteTreeView : Settings -> Position -> SelectedItem -> Items -> Svg Msg
siteTreeView settings ( posX, posY ) selectedItem items =
    let
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
                        children =
                            Item.unwrapChildren <| Item.getChildren item

                        x =
                            posX + Constants.itemSpan

                        y =
                            posY + i * (settings.size.height + Constants.itemSpan) + childrenCount * (settings.size.height + Constants.itemSpan)
                    in
                    [ siteTreeLineView settings ( posX, posY - Constants.itemSpan ) ( posX, y )
                    , Views.card
                        { settings = settings
                        , position = ( x, y )
                        , selectedItem = selectedItem
                        , item = item
                        , canMove = False
                        }
                    , siteTreeView settings
                        ( x
                        , y + (settings.size.height + Constants.itemSpan)
                        )
                        selectedItem
                        children
                    ]
                )
            |> List.concat
        )


siteLineView : Settings -> Position -> Position -> Svg Msg
siteLineView settings ( xx1, yy1 ) ( xx2, yy2 ) =
    let
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


siteTreeLineView : Settings -> Position -> Position -> Svg Msg
siteTreeLineView settings ( xx1, yy1 ) ( xx2, yy2 ) =
    let
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
