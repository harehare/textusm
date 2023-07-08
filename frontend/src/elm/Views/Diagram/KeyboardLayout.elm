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
import Models.Diagram.KeyboardLayout as KeyboardLayout exposing (Row)
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
                rows : List Row
                rows =
                    KeyboardLayout.rows k

                rowSizeList : List Float
                rowSizeList =
                    KeyboardLayout.rowSizeList (\_ -> 0.0) rows
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
                columnSizeList : List Float
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

        Key.Key { item } ->
            let
                ( x, y ) =
                    position

                outerWidth : Float
                outerWidth =
                    Unit.toFloat (Key.unit key) * KeyboardLayout.outerSize

                outerHeight : Float
                outerHeight =
                    Unit.toFloat (Key.height key) * KeyboardLayout.outerSize

                innerWidth : Float
                innerWidth =
                    Unit.toFloat (Key.unit key) * KeyboardLayout.innerSize

                innerHeight : Float
                innerHeight =
                    Unit.toFloat (Key.height key) * KeyboardLayout.innerSize

                marginTop : Float
                marginTop =
                    (Key.marginTop key |> Maybe.map Unit.toFloat |> Maybe.withDefault 0.0) * KeyboardLayout.outerSize

                ( foreColor, backColor ) =
                    Item.getSettings item
                        |> Maybe.map (\_ -> Views.getItemColor settings property item)
                        |> Maybe.withDefault
                            ( Color.fromString <| Maybe.withDefault settings.color.label <| settings.color.text
                            , Color.fromString "#FEFEFE"
                            )

                textView : Svg msg
                textView =
                    Svg.g
                        []
                        [ Svg.text_
                            [ SvgAttr.x <| String.fromFloat <| x + 6
                            , SvgAttr.y <| String.fromFloat <| y + 16 + marginTop
                            , SvgAttr.fontSize "12px"
                            , SvgAttr.fill <| Color.toString foreColor
                            , SvgAttr.fontFamily <| DiagramSettings.fontStyle settings
                            , SvgAttr.cursor "pointer"
                            , SvgAttr.width <| String.fromFloat innerWidth ++ "px"
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
                            , SvgAttr.fontFamily <| DiagramSettings.fontStyle settings
                            , SvgAttr.cursor "pointer"
                            , SvgAttr.width <| String.fromFloat innerWidth ++ "px"
                            ]
                            [ Svg.text <| Maybe.withDefault "" <| Key.bottomLegend key ]
                        ]
            in
            Svg.g
                [ Events.onClickStopPropagation <|
                    onSelect <|
                        Just { item = item, position = ( x |> round, y - KeyboardLayout.innerSize |> round ), displayAllMenu = True }
                ]
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
                    , SvgAttr.cursor "pointer"
                    ]
                    []
                , case selectedItem of
                    Just item_ ->
                        if Item.eq item_ item then
                            Svg.foreignObject
                                [ SvgAttr.x <| String.fromFloat <| x + 2
                                , SvgAttr.y <| String.fromFloat <| y - 6
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
                                        , Css.color <| Css.hex <| Color.toString foreColor
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
                            Item.fromString "r4\n    Esc\n    !,1\n    @,2\n    {sharp},3\n    $,4\n    %,5\n    ^,6\n    &,7\n    *,8\n    (,9\n    ),0\n    _,-\n    =,+\n    Backspace,,2u\nr4\n    Tab,,1.5u\n    Q\n    W\n    E\n    R\n    T\n    Y\n    U\n    I\n    O\n    P\n    {,[\n    },]\n    |,\\,1.5u\nr3\n    Caps Lock,,1.75u\n    A\n    S\n    D\n    F\n    G\n    H\n    J\n    K\n    L\n    :,;\n    \",'\n    Enter,,2.25u\nr2\n    Shift,,2.25u\n    Z\n    X\n    C\n    V\n    B\n    N\n    M\n    <,{comma}\n    >,.\n    ?,/\n    Shift,,2.75u\nr1\n    Ctrl,,1.25u\n    Win,,1.25u\n    Alt,,1.25u\n    ,,6.25u\n    Alt,,1.25u\n    Win,,1.25u\n    Menu,,1.25u\n    Ctl,,1.25u"
                                |> Tuple.second
                                |> KeyboardLayout.from
                                |> DiagramData.KeyboardLayout
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
                            Item.fromString "r4\n    Esc\n    !,1\n    @,2\n    {sharp},3\n    $,4\n    %,5\n    ^,6\n    &,7\n    *,8\n    (,9\n    ),0\n    _,-\n    =,+\n    |,\\\n    ~,`\nr4\n    Tab,,1.5u\n    Q\n    W\n    E\n    R\n    T\n    Y\n    U\n    I\n    O\n    P\n    {,[\n    },]\n    Backspace,,1.5u\nr3\n    Control,,1.75u\n    A\n    S\n    D\n    F\n    G\n    H\n    J\n    K\n    L\n    :,;\n    \",'\n    Enter,,2.25u\nr2\n    Shift,,2.25u\n    Z\n    X\n    C\n    V\n    B\n    N\n    M\n    <,{comma}\n    >,.\n    ?,/\n    Shift,,1.75u\n    Fn\nr1\n    1.25u\n    Opt\n    Alt,,1.75u\n    ,,7u\n    Alt,,1.75u\n    Opt\n    1.25u\n"
                                |> Tuple.second
                                |> KeyboardLayout.from
                                |> DiagramData.KeyboardLayout
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
                            Item.fromString "r4\n    Esc\n    1u\n    F1\n    F2\n    F3\n    F4\n    0.5u\n    F5\n    F6\n    F7\n    F8\n    0.5u\n    F9\n    F10\n    F11\n    F12\n    0.5u\n    PrtSc\n    Scroll,Lock\n    Pause,Break\nr4\n    Esc\n    !,1\n    @,2\n    {sharp},3\n    $,4\n    %,5\n    ^,6\n    &,7\n    *,8\n    (,9\n    ),0\n    _,-\n    =,+\n    Backspace,,2u\n    0.5u\n    Insert\n    Home\n    PgUp\nr4\n    Tab,,1.5u\n    Q\n    W\n    E\n    R\n    T\n    Y\n    U\n    I\n    O\n    P\n    {,[\n    },]\n    |,\\,1.5u\n    0.5u\n    Delete\n    End\n    PgDn\nr3\n    Caps Lock,,1.75u\n    A\n    S\n    D\n    F\n    G\n    H\n    J\n    K\n    L\n    :,;\n    \",'\n    Enter,,2.25u\nr2\n    Shift,,2.25u\n    Z\n    X\n    C\n    V\n    B\n    N\n    M\n    <,{comma}\n    >,.\n    ?,/\n    Shift,,2.75u\n    1.5u\n    ↑\nr1\n    Ctrl,,1.25u\n    Win,,1.25u\n    Alt,,1.25u\n    ,,6.25u\n    Alt,,1.25u\n    Win,,1.25u\n    Menu,,1.25u\n    Ctl,,1.25u\n    0.5u\n    ←\n    ↓\n    →\n"
                                |> Tuple.second
                                |> KeyboardLayout.from
                                |> DiagramData.KeyboardLayout
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
                            Item.fromString "r4\n    Esc\n    1u\n    F1\n    F2\n    F3\n    F4\n    0.5u\n    F5\n    F6\n    F7\n    F8\n    0.5u\n    F9\n    F10\n    F11\n    F12\n    0.5u\n    Home\n    End\n    PgUp\n    PgDn\nr4\n    Esc\n    !,1\n    @,2\n    {sharp},3\n    $,4\n    %,5\n    ^,6\n    &,7\n    *,8\n    (,9\n    ),0\n    _,-\n    =,+\n    Backspace,,2u\n    0.5u\n    Num,Lock\n    /\n    *\n    -\nr4\n    Tab,,1.5u\n    Q\n    W\n    E\n    R\n    T\n    Y\n    U\n    I\n    O\n    P\n    {,[\n    },]\n    |,\\,1.5u\n    0.5u\n    7,Home\n    8,↑\n    9,PgUp\n    +,,,2u\nr3\n    Caps Lock,,1.75u\n    A\n    S\n    D\n    F\n    G\n    H\n    J\n    K\n    L\n    :,;\n    \",'\n    Enter,,2.25u\n    0.5u\n    4, ←\n    5\n    6,→\nr2\n    Shift,,2.25u\n    Z\n    X\n    C\n    V\n    B\n    N\n    M\n    <,{comma}\n    >,.\n    ?,/\n    Shift,,1.75u\n    0.25u\n    ↑,,,,0.25u\n    0.25u\n    1,End\n    2,↓\n    3,PgDn\n    Enter,,,2u\nr1\n    Ctrl,,1.5u\n    Alt,,1.5u\n    ,,7u\n    Alt,,1.5u\n    Ctl,,1.5u\n    0.25u\n    ←,,,,0.25u\n    ↓,,,,0.25u\n    →,,,,0.25u\n    0.25u\n    0,Ins\n    .,Del\n"
                                |> Tuple.second
                                |> KeyboardLayout.from
                                |> DiagramData.KeyboardLayout
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
