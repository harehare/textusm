module Views.DropDownList exposing (DropDownItem, DropDownValue, colorValue, stringValue, view)

import Events
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import List.Extra as ListEx


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


unwrapValue : DropDownValue -> String
unwrapValue value =
    case value of
        ColorValue val ->
            val

        StringValue val ->
            val


getColor : DropDownValue -> Maybe String
getColor value =
    case value of
        ColorValue rgb ->
            Just rgb

        _ ->
            Nothing


view : (String -> msg) -> String -> Maybe String -> (String -> msg) -> List DropDownItem -> String -> Html msg
view onToggleDropDownList dropDownId currentId onChange items selectedValue =
    let
        selectedItem =
            items
                |> ListEx.find (\item -> unwrapValue item.value == selectedValue)
                |> Maybe.withDefault { name = "", value = stringValue selectedValue }
    in
    Html.div
        [ Attr.class "dropdown-list"
        ]
        [ itemView selectedItem (onToggleDropDownList dropDownId)
        , if dropDownId == Maybe.withDefault "" currentId then
            dropdownView items onChange

          else
            Html.text ""
        ]


dropdownView : List DropDownItem -> (String -> msg) -> Html msg
dropdownView items onChange =
    Html.div [ Attr.class "list" ] <|
        List.map (\item -> dropDownItemView item onChange) items


itemView : DropDownItem -> msg -> Html msg
itemView item onActive =
    Html.div
        [ Attr.class
            "item"
        , Events.onClickStopPropagation onActive
        ]
        [ case getColor item.value of
            Just rgb ->
                Html.span
                    [ Attr.style "padding" "0 12px"
                    , Attr.style "margin-right" "5px"
                    , Attr.style "background-color" rgb
                    , Attr.style "border" "1px solid #ccc"
                    ]
                    []

            Nothing ->
                Html.span [] []
        , Html.span [ Attr.style "padding" "8px" ] [ Html.text item.name ]
        ]


dropDownItemView : DropDownItem -> (String -> msg) -> Html msg
dropDownItemView item onChange =
    Html.div
        [ Attr.class
            "dropdown-item"
        , Events.onClick (onChange <| unwrapValue item.value)
        ]
        [ case getColor item.value of
            Just rgb ->
                Html.span
                    [ Attr.style "padding" "0 12px"
                    , Attr.style "margin-right" "5px"
                    , Attr.style "background-color" rgb
                    , Attr.style "border" "1px solid #ccc"
                    ]
                    []

            Nothing ->
                Html.span [] []
        , Html.span [ Attr.style "padding" "8px" ] [ Html.text item.name ]
        ]
