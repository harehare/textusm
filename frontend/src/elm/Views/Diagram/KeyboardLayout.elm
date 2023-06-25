module Views.Diagram.KeyboardLayout exposing (docs, view)

import ElmBook.Chapter as Chapter exposing (Chapter)
import List.Extra as ListEx
import Models.Diagram.Data as DiagramData
import Models.Diagram.KeyboardLayout as KeyboardLayout exposing (Row)
import Models.Diagram.KeyboardLayout.Key as Key exposing (Key)
import Models.Diagram.KeyboardLayout.Unit as Unit exposing (Unit)
import Models.Item as Item
import String
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Views.Empty as Empty


view : DiagramData.Data -> Svg msg
view data =
    case data of
        DiagramData.KeyboardLayout k ->
            let
                rows =
                    KeyboardLayout.rows k

                rowSizeList =
                    KeyboardLayout.rowSizeList rows
            in
            Svg.g [] <|
                List.map
                    (\( row, y ) ->
                        rowView { row = row, y = y }
                    )
                    (ListEx.zip rows rowSizeList)

        _ ->
            Empty.view


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
    case row of
        KeyboardLayout.Blank _ ->
            Svg.g [] []

        KeyboardLayout.Row row_ ->
            let
                columnSizeList =
                    KeyboardLayout.columnSizeList row
            in
            Svg.g [] <|
                List.map
                    (\( key, x ) ->
                        keyView { key = key, position = ( x, y ) }
                    )
                    (ListEx.zip
                        row_
                        columnSizeList
                    )


keyView : { key : Key, position : ( Float, Float ) } -> Svg msg
keyView { key, position } =
    let
        ( x, y ) =
            position

        outerWidth =
            Unit.toFloat (Key.unit key) * KeyboardLayout.outerSize

        innerWidth =
            Unit.toFloat (Key.unit key) * KeyboardLayout.innerSize
    in
    case key of
        Key.Blank _ ->
            Svg.g [] []

        _ ->
            Svg.g []
                [ Svg.rect
                    [ SvgAttr.x <| String.fromFloat <| x
                    , SvgAttr.y <| String.fromFloat <| y
                    , SvgAttr.width <| String.fromFloat outerWidth
                    , SvgAttr.height <| String.fromFloat KeyboardLayout.outerSize
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
                    , SvgAttr.height <| String.fromFloat <| KeyboardLayout.innerSize
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
        |> Chapter.renderComponentList
            [ ( "60%"
              , Svg.svg
                    [ SvgAttr.width "100%"
                    , SvgAttr.height "512px"
                    , SvgAttr.viewBox "0 0 512 512"
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
                                                , Item.new |> Item.withText "    !,1"
                                                , Item.new |> Item.withText "    @,2"
                                                , Item.new |> Item.withText "    \\#,3"
                                                , Item.new |> Item.withText "    $,4"
                                                , Item.new |> Item.withText "    %,5"
                                                , Item.new |> Item.withText "    ^,6"
                                                , Item.new |> Item.withText "    &,7"
                                                , Item.new |> Item.withText "    *,8"
                                                , Item.new |> Item.withText "    (,9"
                                                , Item.new |> Item.withText "    ),0"
                                                , Item.new |> Item.withText "    _,-"
                                                , Item.new |> Item.withText "    =,+"
                                                , Item.new |> Item.withText "    Backspace,,2u"
                                                ]
                                                |> Item.childrenFromItems
                                            )
                                    , Item.new
                                        |> Item.withText "r4"
                                        |> Item.withChildren
                                            (Item.fromList
                                                [ Item.new |> Item.withText "    Tab,,1.5u"
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
                                                , Item.new |> Item.withText "    {,["
                                                , Item.new |> Item.withText "    },]"
                                                , Item.new |> Item.withText "    |,\\,1.5u"
                                                ]
                                                |> Item.childrenFromItems
                                            )
                                    , Item.new
                                        |> Item.withText "r3"
                                        |> Item.withChildren
                                            (Item.fromList
                                                [ Item.new |> Item.withText "    Caps Lock,,1.75u"
                                                , Item.new |> Item.withText "    A"
                                                , Item.new |> Item.withText "    S"
                                                , Item.new |> Item.withText "    D"
                                                , Item.new |> Item.withText "    F"
                                                , Item.new |> Item.withText "    G"
                                                , Item.new |> Item.withText "    H"
                                                , Item.new |> Item.withText "    J"
                                                , Item.new |> Item.withText "    K"
                                                , Item.new |> Item.withText "    L"
                                                , Item.new |> Item.withText "    :,;"
                                                , Item.new |> Item.withText "    \",'"
                                                , Item.new |> Item.withText "    Enter,,2.25u"
                                                ]
                                                |> Item.childrenFromItems
                                            )
                                    , Item.new
                                        |> Item.withText "r2"
                                        |> Item.withChildren
                                            (Item.fromList
                                                [ Item.new |> Item.withText "    Shift,,2.25u"
                                                , Item.new |> Item.withText "    Z"
                                                , Item.new |> Item.withText "    X"
                                                , Item.new |> Item.withText "    C"
                                                , Item.new |> Item.withText "    V"
                                                , Item.new |> Item.withText "    B"
                                                , Item.new |> Item.withText "    N"
                                                , Item.new |> Item.withText "    M"
                                                , Item.new |> Item.withText "    <,comma"
                                                , Item.new |> Item.withText "    >,."
                                                , Item.new |> Item.withText "    ?,/"
                                                , Item.new |> Item.withText "    Shift,,2.75u"
                                                ]
                                                |> Item.childrenFromItems
                                            )
                                    , Item.new
                                        |> Item.withText "r1"
                                        |> Item.withChildren
                                            (Item.fromList
                                                [ Item.new |> Item.withText "    Ctrl,,1.25u"
                                                , Item.new |> Item.withText "    Win,,1.25u"
                                                , Item.new |> Item.withText "    Alt,,1.25u"
                                                , Item.new |> Item.withText "    ,,6.25u"
                                                , Item.new |> Item.withText "    Alt,,1.25u"
                                                , Item.new |> Item.withText "    Win,,1.25u"
                                                , Item.new |> Item.withText "    Menu,,1.25u"
                                                , Item.new |> Item.withText "    Ctl,,1.25u"
                                                ]
                                                |> Item.childrenFromItems
                                            )
                                    ]
                                )
                    ]
                    |> Svg.toUnstyled
              )
            , ( "HHKB"
              , Svg.svg
                    [ SvgAttr.width "100%"
                    , SvgAttr.height "512px"
                    , SvgAttr.viewBox "0 0 512 512"
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
                                                , Item.new |> Item.withText "    !,1"
                                                , Item.new |> Item.withText "    @,2"
                                                , Item.new |> Item.withText "    \\#,3"
                                                , Item.new |> Item.withText "    $,4"
                                                , Item.new |> Item.withText "    %,5"
                                                , Item.new |> Item.withText "    ^,6"
                                                , Item.new |> Item.withText "    &,7"
                                                , Item.new |> Item.withText "    *,8"
                                                , Item.new |> Item.withText "    (,9"
                                                , Item.new |> Item.withText "    ),0"
                                                , Item.new |> Item.withText "    _,-"
                                                , Item.new |> Item.withText "    =,+"
                                                , Item.new |> Item.withText "    |,\\"
                                                , Item.new |> Item.withText "    ~,`"
                                                ]
                                                |> Item.childrenFromItems
                                            )
                                    , Item.new
                                        |> Item.withText "r4"
                                        |> Item.withChildren
                                            (Item.fromList
                                                [ Item.new |> Item.withText "    Tab,,1.5u"
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
                                                , Item.new |> Item.withText "    {,["
                                                , Item.new |> Item.withText "    },]"
                                                , Item.new |> Item.withText "    Backspace,,1.5u"
                                                ]
                                                |> Item.childrenFromItems
                                            )
                                    , Item.new
                                        |> Item.withText "r3"
                                        |> Item.withChildren
                                            (Item.fromList
                                                [ Item.new |> Item.withText "    Control,,1.75u"
                                                , Item.new |> Item.withText "    A"
                                                , Item.new |> Item.withText "    S"
                                                , Item.new |> Item.withText "    D"
                                                , Item.new |> Item.withText "    F"
                                                , Item.new |> Item.withText "    G"
                                                , Item.new |> Item.withText "    H"
                                                , Item.new |> Item.withText "    J"
                                                , Item.new |> Item.withText "    K"
                                                , Item.new |> Item.withText "    L"
                                                , Item.new |> Item.withText "    :,;"
                                                , Item.new |> Item.withText "    \",'"
                                                , Item.new |> Item.withText "    Enter,,2.25u"
                                                ]
                                                |> Item.childrenFromItems
                                            )
                                    , Item.new
                                        |> Item.withText "r2"
                                        |> Item.withChildren
                                            (Item.fromList
                                                [ Item.new |> Item.withText "    Shift,,2.25u"
                                                , Item.new |> Item.withText "    Z"
                                                , Item.new |> Item.withText "    X"
                                                , Item.new |> Item.withText "    C"
                                                , Item.new |> Item.withText "    V"
                                                , Item.new |> Item.withText "    B"
                                                , Item.new |> Item.withText "    N"
                                                , Item.new |> Item.withText "    M"
                                                , Item.new |> Item.withText "    <,comma"
                                                , Item.new |> Item.withText "    >,."
                                                , Item.new |> Item.withText "    ?,/"
                                                , Item.new |> Item.withText "    Shift,,1.75u"
                                                , Item.new |> Item.withText "    Fn"
                                                ]
                                                |> Item.childrenFromItems
                                            )
                                    , Item.new
                                        |> Item.withText "r1"
                                        |> Item.withChildren
                                            (Item.fromList
                                                [ Item.new |> Item.withText "    1.25u"
                                                , Item.new |> Item.withText "    Opt"
                                                , Item.new |> Item.withText "    Alt,,1.75u"
                                                , Item.new |> Item.withText "    ,,7u"
                                                , Item.new |> Item.withText "    Alt,,1.75u"
                                                , Item.new |> Item.withText "    Opt"
                                                , Item.new |> Item.withText "    1.25u"
                                                ]
                                                |> Item.childrenFromItems
                                            )
                                    ]
                                )
                    ]
                    |> Svg.toUnstyled
              )
            , ( "TKL"
              , Svg.svg
                    [ SvgAttr.width "100%"
                    , SvgAttr.height "512px"
                    , SvgAttr.viewBox "0 0 512 512"
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
                                                , Item.new |> Item.withText "    1u"
                                                , Item.new |> Item.withText "    F1"
                                                , Item.new |> Item.withText "    F2"
                                                , Item.new |> Item.withText "    F3"
                                                , Item.new |> Item.withText "    F4"
                                                , Item.new |> Item.withText "    0.5u"
                                                , Item.new |> Item.withText "    F5"
                                                , Item.new |> Item.withText "    F6"
                                                , Item.new |> Item.withText "    F7"
                                                , Item.new |> Item.withText "    F8"
                                                , Item.new |> Item.withText "    0.5u"
                                                , Item.new |> Item.withText "    F9"
                                                , Item.new |> Item.withText "    F10"
                                                , Item.new |> Item.withText "    F11"
                                                , Item.new |> Item.withText "    F12"
                                                , Item.new |> Item.withText "    0.5u"
                                                , Item.new |> Item.withText "    PrtSc"
                                                , Item.new |> Item.withText "    Scroll,Lock"
                                                , Item.new |> Item.withText "    Pause,Break"
                                                ]
                                                |> Item.childrenFromItems
                                            )
                                    , Item.new
                                        |> Item.withText "0.25u"
                                    , Item.new
                                        |> Item.withText "r4"
                                        |> Item.withChildren
                                            (Item.fromList
                                                [ Item.new |> Item.withText "    Esc"
                                                , Item.new |> Item.withText "    !,1"
                                                , Item.new |> Item.withText "    @,2"
                                                , Item.new |> Item.withText "    \\#,3"
                                                , Item.new |> Item.withText "    $,4"
                                                , Item.new |> Item.withText "    %,5"
                                                , Item.new |> Item.withText "    ^,6"
                                                , Item.new |> Item.withText "    &,7"
                                                , Item.new |> Item.withText "    *,8"
                                                , Item.new |> Item.withText "    (,9"
                                                , Item.new |> Item.withText "    ),0"
                                                , Item.new |> Item.withText "    _,-"
                                                , Item.new |> Item.withText "    =,+"
                                                , Item.new |> Item.withText "    Backspace,,2u"
                                                , Item.new |> Item.withText "    0.5u"
                                                , Item.new |> Item.withText "    Insert"
                                                , Item.new |> Item.withText "    Home"
                                                , Item.new |> Item.withText "    PgUp"
                                                ]
                                                |> Item.childrenFromItems
                                            )
                                    , Item.new
                                        |> Item.withText "r4"
                                        |> Item.withChildren
                                            (Item.fromList
                                                [ Item.new |> Item.withText "    Tab,,1.5u"
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
                                                , Item.new |> Item.withText "    {,["
                                                , Item.new |> Item.withText "    },]"
                                                , Item.new |> Item.withText "    |,\\,1.5u"
                                                , Item.new |> Item.withText "    0.5u"
                                                , Item.new |> Item.withText "    Delete"
                                                , Item.new |> Item.withText "    End"
                                                , Item.new |> Item.withText "    PgDn"
                                                ]
                                                |> Item.childrenFromItems
                                            )
                                    , Item.new
                                        |> Item.withText "r3"
                                        |> Item.withChildren
                                            (Item.fromList
                                                [ Item.new |> Item.withText "    Caps Lock,,1.75u"
                                                , Item.new |> Item.withText "    A"
                                                , Item.new |> Item.withText "    S"
                                                , Item.new |> Item.withText "    D"
                                                , Item.new |> Item.withText "    F"
                                                , Item.new |> Item.withText "    G"
                                                , Item.new |> Item.withText "    H"
                                                , Item.new |> Item.withText "    J"
                                                , Item.new |> Item.withText "    K"
                                                , Item.new |> Item.withText "    L"
                                                , Item.new |> Item.withText "    :,;"
                                                , Item.new |> Item.withText "    \",'"
                                                , Item.new |> Item.withText "    Enter,,2.25u"
                                                ]
                                                |> Item.childrenFromItems
                                            )
                                    , Item.new
                                        |> Item.withText "r2"
                                        |> Item.withChildren
                                            (Item.fromList
                                                [ Item.new |> Item.withText "    Shift,,2.25u"
                                                , Item.new |> Item.withText "    Z"
                                                , Item.new |> Item.withText "    X"
                                                , Item.new |> Item.withText "    C"
                                                , Item.new |> Item.withText "    V"
                                                , Item.new |> Item.withText "    B"
                                                , Item.new |> Item.withText "    N"
                                                , Item.new |> Item.withText "    M"
                                                , Item.new |> Item.withText "    <,comma"
                                                , Item.new |> Item.withText "    >,."
                                                , Item.new |> Item.withText "    ?,/"
                                                , Item.new |> Item.withText "    Shift,,2.75u"
                                                , Item.new |> Item.withText "    1.5u"
                                                , Item.new |> Item.withText "    ↑"
                                                ]
                                                |> Item.childrenFromItems
                                            )
                                    , Item.new
                                        |> Item.withText "r1"
                                        |> Item.withChildren
                                            (Item.fromList
                                                [ Item.new |> Item.withText "    Ctrl,,1.25u"
                                                , Item.new |> Item.withText "    Win,,1.25u"
                                                , Item.new |> Item.withText "    Alt,,1.25u"
                                                , Item.new |> Item.withText "    ,,6.25u"
                                                , Item.new |> Item.withText "    Alt,,1.25u"
                                                , Item.new |> Item.withText "    Win,,1.25u"
                                                , Item.new |> Item.withText "    Menu,,1.25u"
                                                , Item.new |> Item.withText "    Ctl,,1.25u"
                                                , Item.new |> Item.withText "    0.5u"
                                                , Item.new |> Item.withText "    ←"
                                                , Item.new |> Item.withText "    ↓"
                                                , Item.new |> Item.withText "    →"
                                                ]
                                                |> Item.childrenFromItems
                                            )
                                    ]
                                )
                    ]
                    |> Svg.toUnstyled
              )
            ]
