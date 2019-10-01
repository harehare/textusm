module Views.DropDownList exposing (colorValue, stringValue, view)

import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import List.Extra exposing (find)
import Models.Model exposing (Msg(..))


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


getColor : DropDownValue -> String
getColor value =
    case value of
        ColorValue rgb ->
            rgb

        _ ->
            "transparent"


view : String -> Maybe String -> (String -> Msg) -> List DropDownItem -> String -> Html Msg
view dropDownId currentId onChange items selectedValue =
    let
        selectedItem =
            items
                |> find (\item -> unwrapValue item.value == selectedValue)
                |> Maybe.withDefault { name = "", value = stringValue selectedValue }
    in
    div
        [ class "dropdown-list"
        ]
        [ itemView selectedItem (ToggleDropDownList dropDownId)
        , if dropDownId == Maybe.withDefault "" currentId then
            dropdownView items onChange

          else
            text ""
        ]


dropdownView : List DropDownItem -> (String -> Msg) -> Html Msg
dropdownView items onChange =
    div
        [ class "list"
        ]
        (List.map (\item -> dropDownItemView item onChange) items)


itemView : DropDownItem -> Msg -> Html Msg
itemView item onActive =
    div
        [ class
            "item"
        , onClick onActive
        ]
        [ span
            [ style "padding" "0 12px"
            , style "margin-right" "5px"
            , style "background-color" (getColor item.value)
            ]
            []
        , span [ style "padding" "8px" ] [ text item.name ]
        ]


dropDownItemView : DropDownItem -> (String -> Msg) -> Html Msg
dropDownItemView item onChange =
    div
        [ class
            "dropdown-item"
        , onClick (onChange <| unwrapValue item.value)
        ]
        [ span
            [ style "padding" "0 12px"
            , style "margin-right" "5px"
            , style "background-color" (getColor item.value)
            ]
            []
        , span [ style "padding" "8px" ] [ text item.name ]
        ]
