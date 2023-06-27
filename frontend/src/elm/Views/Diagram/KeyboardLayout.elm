module Views.Diagram.KeyboardLayout exposing (docs, view)

import Css
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Events
import Html.Styled as Html
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events exposing (onBlur, onInput)
import List.Extra as ListEx
import Models.Color as Color
import Models.Diagram exposing (SelectedItem, SelectedItemInfo)
import Models.Diagram.Data as DiagramData
import Models.Diagram.KeyboardLayout as KeyboardLayout exposing (Row, innerSize, outerSize)
import Models.Diagram.KeyboardLayout.Key as Key exposing (Key)
import Models.Diagram.KeyboardLayout.Unit as Unit exposing (Unit)
import Models.Diagram.Settings as DiagramSettings
import Models.Item as Item exposing (Item)
import Models.Property as Property exposing (Property)
import String
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Views.Diagram.Views as Views
import Views.Empty as Empty


view :
    { data : DiagramData.Data
    , selectedItem : SelectedItem
    , settings : DiagramSettings.Settings
    , property : Property
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    }
    -> Svg msg
view { data, settings, selectedItem, property, onSelect, onEditSelectedItem, onEndEditSelectedItem } =
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
                        rowView
                            { row = row
                            , y = y
                            , settings = settings
                            , selectedItem = selectedItem
                            , property = property
                            , onSelect = onSelect
                            , onEditSelectedItem = onEditSelectedItem
                            , onEndEditSelectedItem = onEndEditSelectedItem
                            }
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


rowView :
    { row : Row
    , y : Float
    , settings : DiagramSettings.Settings
    , selectedItem : SelectedItem
    , property : Property
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    }
    -> Svg msg
rowView { row, y, settings, selectedItem, property, onSelect, onEditSelectedItem, onEndEditSelectedItem } =
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
                        keyView
                            { key = key
                            , position = ( x, y )
                            , settings = settings
                            , selectedItem = selectedItem
                            , property = property
                            , onSelect = onSelect
                            , onEditSelectedItem = onEditSelectedItem
                            , onEndEditSelectedItem = onEndEditSelectedItem
                            }
                    )
                    (ListEx.zip
                        row_
                        columnSizeList
                    )


keyView :
    { key : Key
    , position : ( Float, Float )
    , settings : DiagramSettings.Settings
    , selectedItem : SelectedItem
    , property : Property
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    }
    -> Svg msg
keyView { key, position, settings, selectedItem, property, onSelect, onEditSelectedItem, onEndEditSelectedItem } =
    case key of
        Key.Blank _ ->
            Svg.g [] []

        Key.Key item _ _ _ _ ->
            let
                ( x, y ) =
                    position

                outerWidth =
                    Unit.toFloat (Key.unit key) * KeyboardLayout.outerSize

                outerHeight =
                    Unit.toFloat (Key.height key) * KeyboardLayout.outerSize

                innerWidth =
                    Unit.toFloat (Key.unit key) * KeyboardLayout.innerSize

                innerHeight =
                    Unit.toFloat (Key.height key) * KeyboardLayout.innerSize

                marginTop =
                    (Key.marginTop key |> Maybe.map Unit.toFloat |> Maybe.withDefault 0.0) * outerSize

                ( foreColor, backColor ) =
                    Item.getSettings item
                        |> Maybe.map (\_ -> Views.getItemColor settings property item)
                        |> Maybe.withDefault
                            ( Color.fromString <| Maybe.withDefault settings.color.label <| settings.color.text
                            , Color.fromString "#FEFEFE"
                            )

                textView =
                    Svg.g []
                        [ Svg.text_
                            [ SvgAttr.x <| String.fromFloat <| x + 6
                            , SvgAttr.y <| String.fromFloat <| y + 16 + marginTop
                            , SvgAttr.fontSize "12px"
                            , SvgAttr.fill <| Color.toString foreColor
                            ]
                            [ Key.topLegend key
                                |> Maybe.withDefault ""
                                |> Svg.text
                            ]
                        , Svg.text_
                            [ SvgAttr.x <| String.fromFloat <| x + 6
                            , SvgAttr.y <| String.fromFloat <| y + 38 + marginTop
                            , SvgAttr.fontSize "12px"
                            , SvgAttr.fill <| Color.toString foreColor
                            ]
                            [ Svg.text <| Maybe.withDefault "" <| Key.bottomLegend key ]
                        ]
            in
            Svg.g []
                [ Svg.rect
                    [ SvgAttr.x <| String.fromFloat <| x
                    , SvgAttr.y <| String.fromFloat <| y + marginTop
                    , SvgAttr.width <| String.fromFloat outerWidth
                    , SvgAttr.height <| String.fromFloat outerHeight
                    , SvgAttr.stroke "rgba(0,0,0,0.6)"
                    , SvgAttr.strokeWidth "1"
                    , SvgAttr.fill <| Color.toString backColor
                    , SvgAttr.rx "2"
                    ]
                    []
                , Svg.rect
                    [ SvgAttr.x <| String.fromFloat <| x + 4.0
                    , SvgAttr.y <| String.fromFloat <| y + 3.0 + marginTop
                    , SvgAttr.width <| String.fromFloat <| innerWidth + adjustSize (Key.unit key)
                    , SvgAttr.height <| String.fromFloat <| innerHeight + adjustSize (Key.height key)
                    , SvgAttr.stroke "rgba(0,0,0,0.1)"
                    , SvgAttr.strokeWidth "1"
                    , SvgAttr.fill <| Color.toString backColor
                    , SvgAttr.rx "4"
                    , Events.onClickStopPropagation <|
                        onSelect <|
                            Just { item = item, position = ( x |> round, y - innerSize |> round ), displayAllMenu = True }
                    ]
                    []
                , case selectedItem of
                    Just item_ ->
                        if Item.eq item_ item then
                            Svg.foreignObject
                                [ SvgAttr.x <| String.fromFloat <| x + 6
                                , SvgAttr.y <| String.fromFloat <| y + 16 + marginTop
                                , SvgAttr.width <| String.fromFloat <| innerWidth + adjustSize (Key.unit key)
                                , SvgAttr.height <| String.fromFloat <| innerHeight + adjustSize (Key.height key)
                                ]
                                [ Html.input
                                    [ Attr.id "edit-item"
                                    , Attr.type_ "text"
                                    , Attr.autofocus True
                                    , Attr.autocomplete False
                                    , css
                                        [ Css.padding4 (Css.px 8) (Css.px 8) (Css.px 8) Css.zero
                                        , DiagramSettings.fontFamiliy settings
                                        , Css.color <| Css.hex <| Maybe.withDefault settings.color.label <| settings.color.text
                                        , Css.backgroundColor Css.transparent
                                        , Css.borderStyle Css.none
                                        , Css.outline Css.none
                                        , Css.width <| Css.px <| innerWidth + adjustSize (Key.unit key)
                                        , Css.fontSize <| Css.px 12
                                        , Css.marginTop <| Css.px 2
                                        , Css.marginLeft <| Css.px 2
                                        , Css.focus [ Css.outline Css.none ]
                                        ]
                                    , Attr.value <| " " ++ String.trimLeft (Item.getMultiLineText item_)
                                    , onInput onEditSelectedItem
                                    , onBlur <| onSelect Nothing
                                    , Events.onEnter <| onEndEditSelectedItem item_
                                    ]
                                    []
                                ]

                        else
                            textView

                    Nothing ->
                        textView
                ]


docs : Chapter x
docs =
    Chapter.chapter "KeyboardLayout"
        |> Chapter.renderComponentList
            [ ( "60%"
              , Svg.svg
                    [ SvgAttr.width "100%"
                    , SvgAttr.height "512px"
                    , SvgAttr.viewBox "0 0 1024 512"
                    ]
                    [ view
                        { data =
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
                        , settings = DiagramSettings.default
                        , selectedItem = Nothing
                        , property = Property.empty
                        , onEditSelectedItem = \_ -> Actions.logAction "onEditSelectedItem"
                        , onEndEditSelectedItem = \_ -> Actions.logAction "onEndEditSelectedItem"
                        , onSelect = \_ -> Actions.logAction "onEndEditSelectedItem"
                        }
                    ]
                    |> Svg.toUnstyled
              )
            , ( "HHKB"
              , Svg.svg
                    [ SvgAttr.width "100%"
                    , SvgAttr.height "512px"
                    , SvgAttr.viewBox "0 0 1024 512"
                    ]
                    [ view
                        { data =
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
                        , settings = DiagramSettings.default
                        , selectedItem = Nothing
                        , property = Property.empty
                        , onEditSelectedItem = \_ -> Actions.logAction "onEditSelectedItem"
                        , onEndEditSelectedItem = \_ -> Actions.logAction "onEndEditSelectedItem"
                        , onSelect = \_ -> Actions.logAction "onEndEditSelectedItem"
                        }
                    ]
                    |> Svg.toUnstyled
              )
            , ( "TKL"
              , Svg.svg
                    [ SvgAttr.width "100%"
                    , SvgAttr.height "512px"
                    , SvgAttr.viewBox "0 0 1024 512"
                    ]
                    [ view
                        { data =
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
                        , settings = DiagramSettings.default
                        , selectedItem = Nothing
                        , property = Property.empty
                        , onEditSelectedItem = \_ -> Actions.logAction "onEditSelectedItem"
                        , onEndEditSelectedItem = \_ -> Actions.logAction "onEndEditSelectedItem"
                        , onSelect = \_ -> Actions.logAction "onEndEditSelectedItem"
                        }
                    ]
                    |> Svg.toUnstyled
              )
            , ( "1800"
              , Svg.svg
                    [ SvgAttr.width "100%"
                    , SvgAttr.height "512px"
                    , SvgAttr.viewBox "0 0 1024 512"
                    ]
                    [ view
                        { data =
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
                                                    , Item.new |> Item.withText "    Home"
                                                    , Item.new |> Item.withText "    End"
                                                    , Item.new |> Item.withText "    PgUp"
                                                    , Item.new |> Item.withText "    PgDn"
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
                                                    , Item.new |> Item.withText "    Num,Lock"
                                                    , Item.new |> Item.withText "    /"
                                                    , Item.new |> Item.withText "    *"
                                                    , Item.new |> Item.withText "    -"
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
                                                    , Item.new |> Item.withText "    7,Home"
                                                    , Item.new |> Item.withText "    8,↑"
                                                    , Item.new |> Item.withText "    9,PgUp"
                                                    , Item.new |> Item.withText "    +,,,2u"
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
                                                    , Item.new |> Item.withText "    0.5u"
                                                    , Item.new |> Item.withText "    4, ←"
                                                    , Item.new |> Item.withText "    5"
                                                    , Item.new |> Item.withText "    6,→"
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
                                                    , Item.new |> Item.withText "    0.25u"
                                                    , Item.new |> Item.withText "    ↑,,,,0.25u"
                                                    , Item.new |> Item.withText "    0.25u"
                                                    , Item.new |> Item.withText "    1,End"
                                                    , Item.new |> Item.withText "    2,↓"
                                                    , Item.new |> Item.withText "    3,PgDn"
                                                    , Item.new |> Item.withText "    Enter,,,2u"
                                                    ]
                                                    |> Item.childrenFromItems
                                                )
                                        , Item.new
                                            |> Item.withText "r1"
                                            |> Item.withChildren
                                                (Item.fromList
                                                    [ Item.new |> Item.withText "    Ctrl,,1.5u"
                                                    , Item.new |> Item.withText "    Alt,,1.5u"
                                                    , Item.new |> Item.withText "    ,,7u"
                                                    , Item.new |> Item.withText "    Alt,,1.5u"
                                                    , Item.new |> Item.withText "    Ctl,,1.5u"
                                                    , Item.new |> Item.withText "    0.25u"
                                                    , Item.new |> Item.withText "    ←,,,,0.25u"
                                                    , Item.new |> Item.withText "    ↓,,,,0.25u"
                                                    , Item.new |> Item.withText "    →,,,,0.25u"
                                                    , Item.new |> Item.withText "    0.25u"
                                                    , Item.new |> Item.withText "    0,Ins"
                                                    , Item.new |> Item.withText "    .,Del"
                                                    ]
                                                    |> Item.childrenFromItems
                                                )
                                        ]
                                    )
                        , settings = DiagramSettings.default
                        , selectedItem = Nothing
                        , property = Property.empty
                        , onEditSelectedItem = \_ -> Actions.logAction "onEditSelectedItem"
                        , onEndEditSelectedItem = \_ -> Actions.logAction "onEndEditSelectedItem"
                        , onSelect = \_ -> Actions.logAction "onEndEditSelectedItem"
                        }
                    ]
                    |> Svg.toUnstyled
              )
            ]
