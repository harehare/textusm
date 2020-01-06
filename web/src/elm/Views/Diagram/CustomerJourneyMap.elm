module Views.Diagram.CustomerJourneyMap exposing (view)

import Html as Html exposing (div, img)
import Html.Attributes as Attr
import Models.Diagram exposing (Model, Msg(..), Settings)
import Models.Item as Item exposing (Item, ItemType(..))
import String
import Svg exposing (Svg, foreignObject, g, rect, svg, text)
import Svg.Attributes exposing (class, color, fill, fontFamily, fontSize, height, stroke, transform, width, x, y)
import Svg.Events exposing (onClick)
import Utils


view : Model -> Svg Msg
view model =
    g
        [ transform
            ("translate("
                ++ String.fromInt
                    (if isInfinite <| toFloat <| model.x then
                        0

                     else
                        model.x
                    )
                ++ ","
                ++ String.fromInt
                    (if isInfinite <| toFloat <| model.y then
                        0

                     else
                        model.y
                    )
                ++ ")"
            )
        ]
        (if List.isEmpty model.items then
            []

         else
            headerView model.settings model.items
                ++ rowView model.settings
                    (model.items
                        |> List.head
                        |> Maybe.withDefault Item.emptyItem
                        |> .children
                        |> Item.unwrapChildren
                    )
                ++ (model.items
                        |> List.indexedMap
                            (\i item ->
                                columnView model.settings (i + 1) <| Item.unwrapChildren item.children
                            )
                        |> List.concat
                   )
        )


headerView : Settings -> List Item -> List (Svg Msg)
headerView settings items =
    itemView settings ( settings.color.activity.color, settings.color.activity.backgroundColor ) ( 0, 0 ) Item.emptyItem
        :: List.indexedMap
            (\i item ->
                itemView settings ( settings.color.activity.color, settings.color.activity.backgroundColor ) ( settings.size.width * (i + 1), 0 ) item
            )
            items


rowView : Settings -> List Item -> List (Svg Msg)
rowView settings items =
    List.indexedMap
        (\i item ->
            itemView
                settings
                ( settings.color.task.color, settings.color.task.backgroundColor )
                ( 0, settings.size.height * (i + 1) )
                item
        )
        items


columnView : Settings -> Int -> List Item -> List (Svg Msg)
columnView settings index items =
    List.indexedMap
        (\i item ->
            let
                text =
                    Item.unwrapChildren item.children
                        |> List.map (\ii -> ii.text)
                        |> String.join "\n"
            in
            itemView
                settings
                ( settings.color.story.color, settings.color.story.backgroundColor )
                ( settings.size.width * index, settings.size.height * (i + 1) )
                { item | text = text }
        )
        items


itemView : Settings -> ( String, String ) -> ( Int, Int ) -> Item -> Svg Msg
itemView settings ( colour, backgroundColor ) ( posX, posY ) item =
    let
        svgWidth =
            String.fromInt settings.size.width

        svgHeight =
            String.fromInt settings.size.height
    in
    svg
        [ width svgWidth
        , height svgHeight
        , x (String.fromInt posX)
        , y (String.fromInt posY)
        , onClick (ItemClick item)
        ]
        [ rect
            [ width svgWidth
            , height svgHeight
            , fill backgroundColor
            , stroke "rgba(192,192,192,0.5)"
            ]
            []
        , foreignObject
            [ width svgWidth
            , height svgHeight
            , fill backgroundColor
            , color colour
            , fontSize (item.text |> String.replace " " "" |> Utils.calcFontSize settings.size.width)
            , fontFamily settings.font
            , class ".select-none"
            ]
            [ if Utils.isImageUrl item.text then
                img
                    [ Attr.style "object-fit" "cover"
                    , Attr.style "width" (String.fromInt settings.size.width)
                    , Attr.src item.text
                    ]
                    []

              else
                div
                    [ Attr.style "padding" "8px"
                    , Attr.style "font-family" ("'" ++ settings.font ++ "', sans-serif")
                    , Attr.style "word-wrap" "break-word"
                    ]
                    [ Html.text item.text ]
            ]
        ]
