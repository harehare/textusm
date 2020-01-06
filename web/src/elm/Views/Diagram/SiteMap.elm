module Views.Diagram.SiteMap exposing (view)

import Constants
import List.Extra exposing (scanl1, zip)
import Models.Diagram exposing (Model, Msg(..), Settings)
import Models.Item as Item exposing (Item)
import Svg exposing (Svg, g, line)
import Svg.Attributes exposing (stroke, strokeWidth, transform, x1, x2, y1, y2)
import Views.Diagram.Views as Views


view : Model -> Svg Msg
view model =
    let
        rootItem =
            List.head model.items
    in
    case rootItem of
        Just root ->
            let
                items =
                    Item.unwrapChildren root.children
            in
            g
                [ transform
                    ("translate("
                        ++ String.fromInt
                            (if isInfinite <| toFloat <| model.x then
                                0

                             else
                                model.x + Constants.itemSpan
                            )
                        ++ ","
                        ++ String.fromInt
                            (if isInfinite <| toFloat <| model.y then
                                0

                             else
                                model.y + Constants.itemSpan
                            )
                        ++ ")"
                    )
                ]
                [ siteView model.settings ( 0, Constants.itemSpan + model.settings.size.height ) items
                , Views.cardView model.settings ( 0, 0 ) root
                ]

        Nothing ->
            g [] []


siteView : Settings -> ( Int, Int ) -> List Item -> Svg Msg
siteView settings ( posX, posY ) items =
    let
        hierarchyCountList =
            0
                :: List.map (\item -> Item.getHierarchyCount item - 1) items
                |> scanl1 (+)
    in
    g []
        (zip hierarchyCountList items
            |> List.indexedMap
                (\i ( hierarchyCount, item ) ->
                    let
                        children =
                            Item.unwrapChildren item.children

                        cardWidth =
                            settings.size.width + Constants.itemSpan

                        x =
                            posX
                                + i
                                * (cardWidth + Constants.itemSpan)
                                + hierarchyCount
                                * Constants.itemSpan
                    in
                    [ Views.cardView settings
                        ( x
                        , posY
                        )
                        item
                    , siteLineView settings ( 0, 0 ) ( x, posY )
                    , siteTreeView settings
                        ( x
                        , posY + settings.size.height + Constants.itemSpan
                        )
                        children
                    ]
                )
            |> List.concat
        )


siteTreeView : Settings -> ( Int, Int ) -> List Item -> Svg Msg
siteTreeView settings ( posX, posY ) items =
    let
        childrenCountList =
            0
                :: (items
                        |> List.map
                            (\i ->
                                if List.isEmpty (Item.unwrapChildren i.children) then
                                    0

                                else
                                    Item.getChildrenCount i
                            )
                        |> scanl1 (+)
                   )
    in
    g []
        (zip childrenCountList items
            |> List.indexedMap
                (\i ( childrenCount, item ) ->
                    let
                        children =
                            Item.unwrapChildren item.children

                        x =
                            posX + Constants.itemSpan

                        y =
                            posY + i * (settings.size.height + Constants.itemSpan) + childrenCount * (settings.size.height + Constants.itemSpan)
                    in
                    [ siteTreeLineView settings ( posX, posY - Constants.itemSpan ) ( posX, y )
                    , Views.cardView settings
                        ( x
                        , y
                        )
                        item
                    , siteTreeView settings
                        ( x
                        , y + (settings.size.height + Constants.itemSpan)
                        )
                        children
                    ]
                )
            |> List.concat
        )


siteLineView : Settings -> ( Int, Int ) -> ( Int, Int ) -> Svg Msg
siteLineView settings ( xx1, yy1 ) ( xx2, yy2 ) =
    let
        centerX =
            settings.size.width // 2
    in
    if xx1 == xx2 then
        line
            [ x1 <| String.fromInt <| xx1 + centerX
            , y1 <| String.fromInt yy1
            , x2 <| String.fromInt <| xx2 + centerX
            , y2 <| String.fromInt yy2
            , stroke settings.color.line
            , strokeWidth "1"
            ]
            []

    else
        g []
            [ line
                [ x1 <| String.fromInt <| xx1 + centerX
                , y1 <| String.fromInt <| yy1 + settings.size.height + Constants.itemSpan // 2
                , x2 <| String.fromInt <| xx2 + centerX
                , y2 <| String.fromInt <| yy1 + settings.size.height + Constants.itemSpan // 2
                , stroke settings.color.line
                , strokeWidth "1"
                ]
                []
            , line
                [ x1 <| String.fromInt <| xx2 + centerX
                , y1 <| String.fromInt <| yy1 + settings.size.height + Constants.itemSpan // 2
                , x2 <| String.fromInt <| xx2 + centerX
                , y2 <| String.fromInt <| yy2
                , stroke settings.color.line
                , strokeWidth "1"
                ]
                []
            ]


siteTreeLineView : Settings -> ( Int, Int ) -> ( Int, Int ) -> Svg Msg
siteTreeLineView settings ( xx1, yy1 ) ( xx2, yy2 ) =
    let
        itemPadding =
            Constants.itemSpan // 2
    in
    g []
        [ line
            [ x1 <| String.fromInt <| xx1 + itemPadding
            , y1 <| String.fromInt <| yy1
            , x2 <| String.fromInt <| xx1 + itemPadding
            , y2 <| String.fromInt <| yy2 + settings.size.height // 2
            , stroke settings.color.line
            , strokeWidth "1"
            ]
            []
        , line
            [ x1 <| String.fromInt <| xx1 + itemPadding
            , y1 <| String.fromInt <| yy2 + settings.size.height // 2
            , x2 <| String.fromInt <| xx2 + settings.size.width
            , y2 <| String.fromInt <| yy2 + settings.size.height // 2
            , stroke settings.color.line
            , strokeWidth "1"
            ]
            []
        ]
