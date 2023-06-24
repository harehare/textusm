module Views.Diagram.KeyboardLayout exposing (docs, view)

import ElmBook.Chapter as Chapter exposing (Chapter)
import List.Extra as ListEx
import Models.Diagram.Data as DiagramData
import Models.Diagram.KeyboardLayout as KeyboardLayout exposing (Row)
import Models.Diagram.KeyboardLayout.Key as Key exposing (Key)
import Models.Diagram.KeyboardLayout.Unit as Unit exposing (Unit)
import Models.Item as Item
import Models.Property as Property
import String
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Views.Empty as Empty


view : DiagramData.Data -> Svg msg
view data =
    case data of
        DiagramData.KeyboardLayout k ->
            Svg.g [] <|
                List.indexedMap
                    (\i row ->
                        rowView { row = row, y = (toFloat i * outerSize) + 2 }
                    )
                    (KeyboardLayout.rows k)

        _ ->
            Empty.view


outerSize : Float
outerSize =
    54.0


innerSize : Float
innerSize =
    42.0


adjustSize : Unit -> Float
adjustSize unit =
    if Unit.toFloat unit == 1.0 then
        0.0

    else if Unit.toFloat unit < 2.5 then
        Unit.toFloat unit * 5.9

    else if Unit.toFloat unit < 6 then
        Unit.toFloat unit * 6.8

    else
        Unit.toFloat unit * 10


rowView : { row : Row, y : Float } -> Svg msg
rowView { row, y } =
    let
        (KeyboardLayout.Row row_) =
            row

        posList =
            ListEx.scanl
                (\key acc ->
                    acc + Unit.toFloat (Key.unit key) * outerSize
                )
                0
                row_
    in
    Svg.g [] <|
        List.map
            (\( key, pos ) ->
                keyView { key = key, position = ( pos, y ) }
            )
            (ListEx.zip
                row_
                posList
            )


keyView : { key : Key, position : ( Float, Float ) } -> Svg msg
keyView { key, position } =
    let
        ( x, y ) =
            position

        outerWidth =
            Unit.toFloat (Key.unit key) * outerSize

        innerWidth =
            Unit.toFloat (Key.unit key) * innerSize
    in
    case key of
        Key.Empty _ ->
            Svg.g [] []

        _ ->
            Svg.g []
                [ Svg.rect
                    [ SvgAttr.x <| String.fromFloat <| x
                    , SvgAttr.y <| String.fromFloat <| y
                    , SvgAttr.width <| String.fromFloat outerWidth
                    , SvgAttr.height <| String.fromFloat outerSize
                    , SvgAttr.stroke "rgba(0,0,0,0.6)"
                    , SvgAttr.strokeWidth "1"
                    , SvgAttr.fill "#CCCCCC"
                    , SvgAttr.rx "2"
                    ]
                    []
                , Svg.rect
                    [ SvgAttr.x <| String.fromFloat <| x + 4.0
                    , SvgAttr.y <| String.fromFloat <| y + 3.0
                    , SvgAttr.width <| String.fromFloat <| innerWidth + adjustSize (Key.unit key)
                    , SvgAttr.height <| String.fromFloat <| innerSize
                    , SvgAttr.stroke "rgba(0,0,0,0.1)"
                    , SvgAttr.strokeWidth "1"
                    , SvgAttr.fill "#FCFCFC"
                    , SvgAttr.rx "4"
                    ]
                    []
                , Svg.text_
                    [ SvgAttr.x <| String.fromFloat <| x + 6
                    , SvgAttr.y <| String.fromFloat <| y + 16
                    , SvgAttr.fontSize "12px"
                    ]
                    [ Key.topLegend key
                        |> Maybe.withDefault ""
                        |> Svg.text
                    ]
                , Svg.text_
                    [ SvgAttr.x <| String.fromFloat <| x + 6
                    , SvgAttr.y <| String.fromFloat <| y + 38
                    , SvgAttr.fontSize "12px"
                    ]
                    [ Svg.text <| Maybe.withDefault "" <| Key.bottomLegend key ]
                ]


docs : Chapter x
docs =
    Chapter.chapter "KeyboardLayout"
        |> Chapter.renderComponent
            (Svg.svg
                [ SvgAttr.width "100%"
                , SvgAttr.height "100%"
                , SvgAttr.viewBox "0 0 2048 2048"
                ]
                [ view <|
                    DiagramData.KeyboardLayout <|
                        KeyboardLayout.from
                            (Item.fromList
                                [ Item.new
                                    |> Item.withText "r4"
                                    |> Item.withChildren
                                        (Item.fromList
                                            [ Item.new |> Item.withText "    Esc"
                                            , Item.new |> Item.withText "    !,1,1"
                                            , Item.new |> Item.withText "    @,2,1"
                                            , Item.new |> Item.withText "    \\#,3,1"
                                            , Item.new |> Item.withText "    $,4,1"
                                            , Item.new |> Item.withText "    %,5,1"
                                            , Item.new |> Item.withText "    ^,6,1"
                                            , Item.new |> Item.withText "    &,7,1"
                                            , Item.new |> Item.withText "    *,8,1"
                                            , Item.new |> Item.withText "    (,9,1"
                                            , Item.new |> Item.withText "    ),0,1"
                                            , Item.new |> Item.withText "    _,-,1"
                                            , Item.new |> Item.withText "    =,+,1"
                                            , Item.new |> Item.withText "    Backspace,,2"
                                            ]
                                            |> Item.childrenFromItems
                                        )
                                , Item.new
                                    |> Item.withText "r4"
                                    |> Item.withChildren
                                        (Item.fromList
                                            [ Item.new |> Item.withText "    Tab,,1.5"
                                            , Item.new |> Item.withText "    Q"
                                            , Item.new |> Item.withText "    W"
                                            , Item.new |> Item.withText "    E"
                                            , Item.new |> Item.withText "    R"
                                            , Item.new |> Item.withText "    T"
                                            , Item.new |> Item.withText "    Y"
                                            , Item.new |> Item.withText "    U"
                                            , Item.new |> Item.withText "    I"
                                            , Item.new |> Item.withText "    O"
                                            , Item.new |> Item.withText "    P"
                                            , Item.new |> Item.withText "    {,[,1"
                                            , Item.new |> Item.withText "    },],1"
                                            , Item.new |> Item.withText "    |,\\,1.5"
                                            ]
                                            |> Item.childrenFromItems
                                        )
                                , Item.new
                                    |> Item.withText "r3"
                                    |> Item.withChildren
                                        (Item.fromList
                                            [ Item.new |> Item.withText "    Caps Lock,,1.75"
                                            , Item.new |> Item.withText "    A"
                                            , Item.new |> Item.withText "    S"
                                            , Item.new |> Item.withText "    D"
                                            , Item.new |> Item.withText "    F"
                                            , Item.new |> Item.withText "    G"
                                            , Item.new |> Item.withText "    H"
                                            , Item.new |> Item.withText "    J"
                                            , Item.new |> Item.withText "    K"
                                            , Item.new |> Item.withText "    L"
                                            , Item.new |> Item.withText "    :,;,1"
                                            , Item.new |> Item.withText "    \",',1"
                                            , Item.new |> Item.withText "    Enter,,2.25"
                                            ]
                                            |> Item.childrenFromItems
                                        )
                                , Item.new
                                    |> Item.withText "r2"
                                    |> Item.withChildren
                                        (Item.fromList
                                            [ Item.new |> Item.withText "    Shift,,2.25"
                                            , Item.new |> Item.withText "    Z"
                                            , Item.new |> Item.withText "    X"
                                            , Item.new |> Item.withText "    C"
                                            , Item.new |> Item.withText "    V"
                                            , Item.new |> Item.withText "    B"
                                            , Item.new |> Item.withText "    N"
                                            , Item.new |> Item.withText "    M"
                                            , Item.new |> Item.withText "    <,comma,1"
                                            , Item.new |> Item.withText "    >,.,1"
                                            , Item.new |> Item.withText "    ?,/,1"
                                            , Item.new |> Item.withText "    Shift,,2.75"
                                            ]
                                            |> Item.childrenFromItems
                                        )
                                , Item.new
                                    |> Item.withText "r1"
                                    |> Item.withChildren
                                        (Item.fromList
                                            [ Item.new |> Item.withText "    Ctrl,,1.25"
                                            , Item.new |> Item.withText "    Win,,1.25"
                                            , Item.new |> Item.withText "    Alt,,1.25"
                                            , Item.new |> Item.withText "    ,,6.25"
                                            , Item.new |> Item.withText "    Alt,,1.25"
                                            , Item.new |> Item.withText "    Win,,1.25"
                                            , Item.new |> Item.withText "    Menu,,1.25"
                                            , Item.new |> Item.withText "    Ctl,,1.25"
                                            ]
                                            |> Item.childrenFromItems
                                        )
                                ]
                            )
                            Property.empty
                ]
                |> Svg.toUnstyled
            )
