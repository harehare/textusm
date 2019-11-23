module Views.Diagram.UserStoryMap exposing (view)

import Basics exposing (max)
import Constants exposing (..)
import Html exposing (div)
import Html.Attributes as Attr
import Json.Decode as D
import List
import List.Extra exposing (getAt, zip)
import Models.Diagram exposing (Model, Msg(..), Settings)
import Models.Item as Item exposing (Item, ItemType(..))
import String
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (onClick, stopPropagationOn)
import Svg.Keyed as Keyed
import Svg.Lazy exposing (lazy4, lazy5)
import Utils
import Views.Diagram.Views as Views


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
        , fill model.settings.backgroundColor
        ]
        [ lazy5 labelView
            model.labels
            model.settings
            model.hierarchy
            model.svg.width
            model.countByHierarchy
        , lazy4 mainView
            model.settings
            model.items
            model.countByTasks
            model.countByHierarchy
        ]


mainView : Settings -> List Item -> List Int -> List Int -> Svg Msg
mainView settings items countByTasks countByHierarchy =
    Keyed.node "g"
        []
        (zip
            countByTasks
            items
            |> List.indexedMap
                (\i ( count, item ) ->
                    ( "activity-" ++ String.fromInt i, activityView settings (List.drop 2 countByHierarchy) (leftMargin * 2 + count * (settings.size.width + itemMargin)) 10 item )
                )
        )


labelView : List String -> Settings -> Int -> Int -> List Int -> Svg Msg
labelView labels settings hierarchy width countByHierarchy =
    let
        textX =
            "16"
    in
    g []
        (([ if hierarchy > 0 then
                line
                    [ x1 textX
                    , y1 (String.fromInt (itemMargin // 2 + (settings.size.height + itemMargin) * 2))
                    , x2 (String.fromInt width)
                    , y2 (String.fromInt (itemMargin // 2 + (settings.size.height + itemMargin) * 2))
                    , stroke settings.color.line
                    , strokeWidth "2"
                    ]
                    []

            else
                line [] []
          , if hierarchy > 0 then
                labelTextView settings textX "10" (getAt 0 labels |> Maybe.withDefault "USER ACTIVITIES")

            else
                text_ [] []
          , if hierarchy > 0 then
                labelTextView settings textX "90" (getAt 1 labels |> Maybe.withDefault "USER TASKS")

            else
                text_ [] []
          ]
            ++ (if hierarchy > 1 then
                    [ labelTextView settings textX "185" (getAt 2 labels |> Maybe.withDefault "USER STORIES")
                    , labelTextView settings textX "215" (getAt 3 labels |> Maybe.withDefault "RELEASE 1")
                    ]

                else
                    [ text_ [] [] ]
               )
         )
            ++ (List.range 1 (hierarchy - 2)
                    |> List.map
                        (\xx ->
                            if List.length countByHierarchy - 2 > xx then
                                let
                                    releaseY =
                                        itemMargin
                                            // 2
                                            + itemMargin
                                            + ((settings.size.height + itemMargin)
                                                * (countByHierarchy
                                                    |> List.take (xx + 2)
                                                    |> List.sum
                                                  )
                                              )
                                            + ((xx - 1) * itemMargin)
                                in
                                [ line
                                    [ x1 textX
                                    , y1 (String.fromInt releaseY)
                                    , x2 (String.fromInt width)
                                    , y2 (String.fromInt releaseY)
                                    , stroke settings.color.line
                                    , strokeWidth "2"
                                    ]
                                    []
                                , labelTextView settings textX (String.fromInt (releaseY + itemMargin)) (getAt (xx + 3) labels |> Maybe.withDefault ("RELEASE " ++ String.fromInt (xx + 1)))
                                ]

                            else
                                [ line [] [] ]
                        )
                    |> List.concat
               )
        )


activityView : Settings -> List Int -> Int -> Int -> Item -> Svg Msg
activityView settings verticalCount posX posY item =
    Keyed.node "g"
        []
        (( "activity-" ++ item.text
         , Views.cardView settings ( posX, posY ) item
         )
            :: (Item.unwrapChildren item.children
                    |> List.indexedMap
                        (\i it ->
                            ( "task-" ++ it.text
                            , taskView
                                settings
                                verticalCount
                                (posX
                                    + (i * settings.size.width)
                                    + (if i > 0 then
                                        i * itemMargin

                                       else
                                        0
                                      )
                                )
                                (posY + itemMargin + settings.size.height)
                                it
                            )
                        )
               )
        )


taskView : Settings -> List Int -> Int -> Int -> Item -> Svg Msg
taskView settings verticalCount posX posY item =
    let
        children =
            Item.unwrapChildren item.children
    in
    Keyed.node "g"
        []
        (( "task-" ++ item.text
         , Views.cardView settings ( posX, posY ) item
         )
            :: (children
                    |> List.indexedMap
                        (\i it ->
                            ( "story-" ++ it.text
                            , storyView settings
                                verticalCount
                                (List.length children)
                                posX
                                (posY
                                    + ((i + 1) * settings.size.height)
                                    + (itemMargin * 2)
                                    + (if i > 0 then
                                        itemMargin * i

                                       else
                                        0
                                      )
                                )
                                it
                            )
                        )
               )
        )


storyView : Settings -> List Int -> Int -> Int -> Int -> Item -> Svg Msg
storyView settings verticalCount parentCount posX posY item =
    let
        itemCount =
            List.head verticalCount |> Maybe.withDefault 1

        children =
            Item.unwrapChildren item.children

        childrenLength =
            List.length children

        tail =
            List.tail verticalCount |> Maybe.withDefault []
    in
    Keyed.node "g"
        []
        (( "story-" ++ item.text
         , Views.cardView settings ( posX, posY ) item
         )
            :: (children
                    |> List.indexedMap
                        (\i it ->
                            ( "story-" ++ item.text
                            , storyView
                                settings
                                tail
                                childrenLength
                                posX
                                (posY
                                    + (Basics.max 1 (itemCount - parentCount + i + 1)
                                        * (itemMargin + settings.size.height)
                                      )
                                    + itemMargin
                                )
                                it
                            )
                        )
               )
        )


labelTextView : Settings -> String -> String -> String -> Svg Msg
labelTextView settings posX posY t =
    foreignObject
        [ x posX
        , y posY
        , width "100"
        , height "30"
        , color settings.color.label
        , fontSize "11"
        , fontWeight "bold"
        , fontFamily settings.font
        , class ".select-none"
        ]
        [ div
            [ Attr.style "font-family" ("'" ++ settings.font ++ "', sans-serif")
            , Attr.style "word-wrap" "break-word"
            ]
            [ Html.text t ]
        ]
