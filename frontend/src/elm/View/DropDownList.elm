module View.DropDownList exposing (DropDownItem, DropDownValue, colorValue, docs, loadingView, stringValue, view)

import Attributes exposing (dataTest)
import Css
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Events
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Html.Styled.Events as Events
import List.Extra as ListEx
import Style.Color as Color
import Style.Global as GlobalStyle
import Style.Style as Style
import Style.Text as Text


type alias DropDownItem =
    { name : String
    , value : DropDownValue
    }


type DropDownValue
    = ColorValue String
    | StringValue String


colorValue : String -> DropDownValue
colorValue value =
    ColorValue value


stringValue : String -> DropDownValue
stringValue value =
    StringValue value


view : (String -> msg) -> String -> Maybe String -> (String -> msg) -> List DropDownItem -> String -> Html msg
view onToggleDropDownList dropDownId currentId onChange items selectedValue =
    let
        selectedItem : DropDownItem
        selectedItem =
            items
                |> ListEx.find (\item -> unwrapValue item.value == selectedValue)
                |> Maybe.withDefault { name = selectedValue, value = stringValue selectedValue }
    in
    Html.div
        [ Attr.css
            [ Style.widthFull
            , Text.sm
            , Css.position Css.relative
            , Color.bgTransparent
            , Css.cursor Css.pointer
            , Css.outline Css.none
            , Css.color <| Css.hex "#2e2e2e"
            , Css.property "user-select" "none"
            ]
        , dataTest dropDownId
        ]
        [ itemView selectedItem (onToggleDropDownList dropDownId)
        , if dropDownId == Maybe.withDefault "" currentId then
            dropdownView items onChange

          else
            Html.text ""
        ]


loadingView : String -> Html msg
loadingView text =
    Html.div
        [ Attr.css
            [ Style.widthFull
            , Text.sm
            , Css.position Css.relative
            , Color.bgTransparent
            , Css.cursor Css.pointer
            , Css.outline Css.none
            , Css.color <| Css.hex "#2e2e2e"
            , Css.property "user-select" "none"
            ]
        ]
        [ textItemView text
        ]


dropDownItemView : DropDownItem -> (String -> msg) -> Html msg
dropDownItemView item onChange =
    Html.div
        [ Attr.css
            [ Style.widthFull
            , Css.display Css.block
            , Style.paddingSm
            , Css.borderBottom3 (Css.px 1) Css.solid (Css.rgba 0 0 0 0.1)
            , Color.bgLight
            , Css.hover
                [ Css.backgroundColor <| Css.hex "#dddddd"
                ]
            ]
        , Events.onClick (onChange <| unwrapValue item.value)
        ]
        [ case getColor item.value of
            Just rgb ->
                Html.span
                    [ Attr.css
                        [ Css.padding2 (Css.px 0) (Css.px 12)
                        , Css.marginRight <| Css.px 5
                        , Css.backgroundColor <| Css.hex rgb
                        , Css.border3 (Css.px 1) Css.solid (Css.hex "#cccccc")
                        ]
                    ]
                    []

            Nothing ->
                Html.span [] []
        , Html.span [ Attr.css [ Style.paddingSm ] ] [ Html.text item.name ]
        ]


dropdownView : List DropDownItem -> (String -> msg) -> Html msg
dropdownView items onChange =
    Html.div
        [ Attr.css
            [ Css.position Css.absolute
            , Color.bgTransparent
            , Style.m0
            , Css.overflowY Css.scroll
            , Css.overflowX Css.hidden
            , Css.zIndex <| Css.int 10
            , Css.top <| Css.px 33
            , Css.paddingLeft <| Css.px 0
            , Css.borderTop <| Css.px 0
            , Css.width <| Css.pct 100
            , Css.height <| Css.px 192
            , Css.property "-webkit-overflow-scrolling" "touch"
            , Css.property "-ms-overflow-style" "none"
            , Css.property "scrollbar-width" "none"
            , Css.pseudoElement "-webkit-scrollbar" [ Css.display Css.none ]
            ]
        ]
    <|
        List.map (\item -> dropDownItemView item onChange) items


getColor : DropDownValue -> Maybe String
getColor value =
    case value of
        ColorValue rgb ->
            Just rgb

        _ ->
            Nothing


itemView : DropDownItem -> msg -> Html msg
itemView item onActive =
    Html.div
        [ Attr.css
            [ Css.display Css.block
            , Color.bgLight
            , Css.position Css.relative
            , Style.paddingSm
            , Css.after
                [ Style.emptyContent
                , Css.width Css.zero
                , Css.height Css.zero
                , Css.position Css.absolute
                , Css.right <| Css.px 16
                , Css.top <| Css.pct 50
                , Css.borderStyle Css.solid
                , Css.borderWidth3 (Css.px 6) (Css.px 6) Css.zero
                , Css.borderColor2 (Css.hex "#2e2e2e") Css.transparent
                , Css.marginTop <| Css.px -4
                ]
            ]
        , Events.onClickStopPropagation onActive
        ]
        [ case getColor item.value of
            Just rgb ->
                Html.span
                    [ Attr.css
                        [ Css.padding2 (Css.px 0) (Css.px 12)
                        , Css.marginRight <| Css.px 5
                        , Css.backgroundColor <| Css.hex rgb
                        , Css.border3 (Css.px 1) Css.solid (Css.hex "#cccccc")
                        ]
                    ]
                    []

            Nothing ->
                Html.span [] []
        , Html.span [ Attr.css [ Style.paddingSm ] ] [ Html.text item.name ]
        ]


textItemView : String -> Html msg
textItemView text =
    Html.div
        [ Attr.css
            [ Css.display Css.block
            , Color.bgLight
            , Css.position Css.relative
            , Style.paddingSm
            , Css.after
                [ Style.emptyContent
                , Css.width Css.zero
                , Css.height Css.zero
                , Css.position Css.absolute
                , Css.right <| Css.px 16
                , Css.top <| Css.pct 50
                , Css.borderStyle Css.solid
                , Css.borderWidth3 (Css.px 6) (Css.px 6) Css.zero
                , Css.borderColor2 (Css.hex "#2e2e2e") Css.transparent
                , Css.marginTop <| Css.px -4
                ]
            ]
        ]
        [ Html.span [ Attr.css [ Style.paddingSm ] ] [ Html.text text ]
        ]


unwrapValue : DropDownValue -> String
unwrapValue value =
    case value of
        ColorValue val ->
            val

        StringValue val ->
            val


docs : Chapter x
docs =
    Chapter.chapter "DropDownList"
        |> Chapter.renderComponent
            (Html.div [ Attr.css [ Color.bgMain ] ]
                [ GlobalStyle.style
                , view (\_ -> Actions.logAction "onToggleDropDownList")
                    "id"
                    (Just "id")
                    (\_ -> Actions.logAction "onChange")
                    [ { name = "value"
                      , value = stringValue "value"
                      }
                    , { name = "value2"
                      , value = stringValue "value2"
                      }
                    ]
                    "value"
                ]
                |> Html.toUnstyled
            )
