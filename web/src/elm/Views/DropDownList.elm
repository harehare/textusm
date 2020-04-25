module Views.DropDownList exposing (DropDownItem, DropDownValue, colorValue, stringValue, view)

import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import List.Extra exposing (find)


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
                |> find (\item -> unwrapValue item.value == selectedValue)
                |> Maybe.withDefault { name = "", value = stringValue selectedValue }
    in
    div
        [ class "dropdown-list"
        ]
        [ itemView selectedItem (onToggleDropDownList dropDownId)
        , if dropDownId == Maybe.withDefault "" currentId then
            dropdownView items onChange

          else
            text ""
        ]


dropdownView : List DropDownItem -> (String -> msg) -> Html msg
dropdownView items onChange =
    div
        [ class "list"
        ]
        (List.map (\item -> dropDownItemView item onChange) items)


itemView : DropDownItem -> msg -> Html msg
itemView item onActive =
    div
        [ class
            "item"
        , onClick onActive
        ]
        [ case getColor item.value of
            Just rgb ->
                span
                    [ style "padding" "0 12px"
                    , style "margin-right" "5px"
                    , style "background-color" rgb
                    , style "border" "1px solid #ccc"
                    ]
                    []

            Nothing ->
                span [] []
        , span [ style "padding" "8px" ] [ text item.name ]
        ]


dropDownItemView : DropDownItem -> (String -> msg) -> Html msg
dropDownItemView item onChange =
    div
        [ class
            "dropdown-item"
        , onClick (onChange <| unwrapValue item.value)
        ]
        [ case getColor item.value of
            Just rgb ->
                span
                    [ style "padding" "0 12px"
                    , style "margin-right" "5px"
                    , style "background-color" rgb
                    , style "border" "1px solid #ccc"
                    ]
                    []

            Nothing ->
                span [] []
        , span [ style "padding" "8px" ] [ text item.name ]
        ]
