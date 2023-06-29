module Views.DropDownList exposing (DropDownItem, DropDownValue, colorValue, docs, loadingView, stringValue, view)

import Css
    exposing
        ( absolute
        , after
        , backgroundColor
        , block
        , border3
        , borderBottom3
        , borderColor2
        , borderStyle
        , borderTop
        , borderWidth3
        , color
        , cursor
        , display
        , height
        , hex
        , hidden
        , hover
        , int
        , marginRight
        , marginTop
        , none
        , outline
        , overflowX
        , overflowY
        , padding2
        , paddingLeft
        , pct
        , pointer
        , position
        , property
        , pseudoElement
        , px
        , relative
        , rgba
        , right
        , scroll
        , solid
        , top
        , transparent
        , width
        , zIndex
        , zero
        )
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
                |> Maybe.withDefault { name = "", value = stringValue selectedValue }
    in
    Html.div
        [ Attr.css
            [ Style.widthFull
            , Text.sm
            , position relative
            , Color.bgTransparent
            , cursor pointer
            , outline none
            , color <| hex "#2e2e2e"
            , property "user-select" "none"
            ]
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
            , position relative
            , Color.bgTransparent
            , cursor pointer
            , outline none
            , color <| hex "#2e2e2e"
            , property "user-select" "none"
            ]
        ]
        [ textItemView text
        ]


dropDownItemView : DropDownItem -> (String -> msg) -> Html msg
dropDownItemView item onChange =
    Html.div
        [ Attr.css
            [ Style.widthFull
            , display block
            , Style.paddingSm
            , borderBottom3 (px 1) solid (rgba 0 0 0 0.1)
            , Color.bgLight
            , hover
                [ backgroundColor <| hex "#dddddd"
                ]
            ]
        , Events.onClick (onChange <| unwrapValue item.value)
        ]
        [ case getColor item.value of
            Just rgb ->
                Html.span
                    [ Attr.css
                        [ padding2 (px 0) (px 12)
                        , marginRight <| px 5
                        , backgroundColor <| hex rgb
                        , border3 (px 1) solid (hex "#cccccc")
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
            [ position absolute
            , Color.bgTransparent
            , Style.m0
            , overflowY scroll
            , overflowX hidden
            , zIndex <| int 10
            , top <| px 33
            , paddingLeft <| px 0
            , borderTop <| px 0
            , width <| pct 100
            , height <| px 192
            , property "-webkit-overflow-scrolling" "touch"
            , property "-ms-overflow-style" "none"
            , property "scrollbar-width" "none"
            , pseudoElement "-webkit-scrollbar" [ display none ]
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
            [ display block
            , Color.bgLight
            , position relative
            , Style.paddingSm
            , after
                [ Style.emptyContent
                , width zero
                , height zero
                , position absolute
                , right <| px 16
                , top <| pct 50
                , borderStyle solid
                , borderWidth3 (px 6) (px 6) zero
                , borderColor2 (hex "#2e2e2e") transparent
                , marginTop <| px -4
                ]
            ]
        , Events.onClickStopPropagation onActive
        ]
        [ case getColor item.value of
            Just rgb ->
                Html.span
                    [ Attr.css
                        [ padding2 (px 0) (px 12)
                        , marginRight <| px 5
                        , backgroundColor <| hex rgb
                        , border3 (px 1) solid (hex "#cccccc")
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
            [ display block
            , Color.bgLight
            , position relative
            , Style.paddingSm
            , after
                [ Style.emptyContent
                , width zero
                , height zero
                , position absolute
                , right <| px 16
                , top <| pct 50
                , borderStyle solid
                , borderWidth3 (px 6) (px 6) zero
                , borderColor2 (hex "#2e2e2e") transparent
                , marginTop <| px -4
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
