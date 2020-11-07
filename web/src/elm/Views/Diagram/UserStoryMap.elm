module Views.Diagram.UserStoryMap exposing (view)

import Asset exposing (userStoryMap)
import Basics exposing (max)
import Constants
import Data.Item as Item exposing (Item, ItemType(..), Items)
import Data.Position exposing (Position)
import Html exposing (div)
import Html.Attributes as Attr
import List
import List.Extra exposing (zip)
import Models.Diagram as Diagram exposing (Model, Msg(..), SelectedItem, Settings, fontStyle)
import Models.Views.UserStoryMap as UserStoryMap exposing (UserStoryMap)
import String
import Svg exposing (Svg, foreignObject, g, line, text_)
import Svg.Attributes exposing (class, color, fontSize, fontWeight, height, stroke, strokeWidth, style, width, x, x1, x2, y, y1, y2)
import Svg.Keyed as Keyed
import Svg.Lazy exposing (lazy, lazy4, lazy5)
import Views.Diagram.Views as Views
import Views.Empty as Empty


view : Model -> Svg Msg
view model =
    case model.data of
        Diagram.UserStoryMap userStoryMap ->
            g
                []
                [ lazy labelView
                    { settings = model.settings
                    , width = model.svg.width
                    , userStoryMap = userStoryMap
                    }
                , lazy mainView
                    { settings = model.settings
                    , selectedItem = model.selectedItem
                    , items = UserStoryMap.getItems userStoryMap
                    , countByTasks = UserStoryMap.countPerTasks userStoryMap
                    , countByHierarchy = UserStoryMap.countPerStories userStoryMap
                    }
                ]

        _ ->
            Empty.view


mainView : { settings : Settings, selectedItem : SelectedItem, items : Items, countByTasks : List Int, countByHierarchy : List Int } -> Svg Msg
mainView { settings, selectedItem, items, countByTasks, countByHierarchy } =
    Keyed.node "g"
        []
        (zip
            countByTasks
            (Item.unwrap items)
            |> List.indexedMap
                (\i ( count, item ) ->
                    ( "activity-" ++ String.fromInt i, activityView settings (List.drop 2 countByHierarchy) ( Constants.leftMargin + count * (settings.size.width + Constants.itemMargin), 10 ) selectedItem item )
                )
        )


labelView : { settings : Settings, width : Int, userStoryMap : UserStoryMap } -> Svg Msg
labelView { settings, width, userStoryMap } =
    let
        posX =
            16

        hierarchy =
            UserStoryMap.getHierarchy userStoryMap

        countPerStories =
            UserStoryMap.countPerStories userStoryMap
    in
    g []
        (([ if hierarchy > 0 then
                line
                    [ x1 <| String.fromInt posX
                    , y1 <| String.fromInt (Constants.itemMargin // 2 + (settings.size.height + Constants.itemMargin) * 2)
                    , x2 <| String.fromInt width
                    , y2 <| String.fromInt (Constants.itemMargin // 2 + (settings.size.height + Constants.itemMargin) * 2)
                    , stroke settings.color.line
                    , strokeWidth "2"
                    ]
                    []

            else
                line [] []
          , if hierarchy > 0 then
                labelTextView settings ( posX, 10 ) (UserStoryMap.getReleaseLevel userStoryMap "user_activities" "USER ACTIVITIES")

            else
                text_ [] []
          , if hierarchy > 0 then
                labelTextView settings ( posX, settings.size.height + 25 ) (UserStoryMap.getReleaseLevel userStoryMap "user_tasks" "USER TASKS")

            else
                text_ [] []
          ]
            ++ (if hierarchy > 1 then
                    [ labelTextView settings ( posX, settings.size.height * 2 + 50 ) (UserStoryMap.getReleaseLevel userStoryMap "user_stories" "USER STORIES")
                    , labelTextView settings ( posX, settings.size.height * 2 + 80 ) (UserStoryMap.getReleaseLevel userStoryMap "release1" "RELEASE 1")
                    ]

                else
                    [ text_ [] [] ]
               )
         )
            ++ (List.range 1 (hierarchy - 2)
                    |> List.map
                        (\xx ->
                            if List.length countPerStories - 2 > xx then
                                let
                                    releaseY =
                                        Constants.itemMargin
                                            // 2
                                            + Constants.itemMargin
                                            + ((settings.size.height + Constants.itemMargin)
                                                * (countPerStories
                                                    |> List.take (xx + 2)
                                                    |> List.sum
                                                  )
                                              )
                                            + ((xx - 1) * Constants.itemMargin)
                                in
                                [ line
                                    [ x1 <| String.fromInt posX
                                    , y1 <| String.fromInt releaseY
                                    , x2 <| String.fromInt width
                                    , y2 <| String.fromInt releaseY
                                    , stroke settings.color.line
                                    , strokeWidth "2"
                                    ]
                                    []
                                , labelTextView settings ( posX, releaseY + Constants.itemMargin ) (UserStoryMap.getReleaseLevel userStoryMap ("release" ++ String.fromInt (xx + 1)) ("RELEASE " ++ String.fromInt (xx + 1)))
                                ]

                            else
                                [ line [] [] ]
                        )
                    |> List.concat
               )
        )


activityView : Settings -> List Int -> Position -> SelectedItem -> Item -> Svg Msg
activityView settings verticalCount ( posX, posY ) selectedItem item =
    Keyed.node "g"
        []
        (( "activity-" ++ Item.getText item
         , lazy Views.cardView { settings = settings, position = ( posX, posY ), selectedItem = selectedItem, item = item }
         )
            :: (Item.unwrapChildren (Item.getChildren item)
                    |> Item.indexedMap
                        (\i it ->
                            ( "task-" ++ Item.getText it
                            , taskView
                                settings
                                verticalCount
                                ( posX
                                    + (i * settings.size.width)
                                    + (if i > 0 then
                                        i * Constants.itemMargin

                                       else
                                        0
                                      )
                                , posY + Constants.itemMargin + settings.size.height
                                )
                                selectedItem
                                it
                            )
                        )
               )
        )


taskView : Settings -> List Int -> Position -> SelectedItem -> Item -> Svg Msg
taskView settings verticalCount ( posX, posY ) selectedItem item =
    let
        children =
            Item.unwrapChildren <| Item.getChildren item
    in
    Keyed.node "g"
        []
        (( "task-" ++ Item.getText item
         , lazy Views.cardView { settings = settings, position = ( posX, posY ), selectedItem = selectedItem, item = item }
         )
            :: (children
                    |> Item.indexedMap
                        (\i it ->
                            ( "story-" ++ Item.getText it
                            , storyView settings
                                verticalCount
                                (Item.length children)
                                ( posX
                                , posY
                                    + ((i + 1) * settings.size.height)
                                    + (Constants.itemMargin * 2)
                                    + (if i > 0 then
                                        Constants.itemMargin * i

                                       else
                                        0
                                      )
                                )
                                selectedItem
                                it
                            )
                        )
               )
        )


storyView : Settings -> List Int -> Int -> Position -> SelectedItem -> Item -> Svg Msg
storyView settings verticalCount parentCount ( posX, posY ) selectedItem item =
    let
        itemCount =
            List.head verticalCount |> Maybe.withDefault 1

        children =
            Item.unwrapChildren <| Item.getChildren item

        childrenLength =
            Item.length children

        tail =
            List.tail verticalCount |> Maybe.withDefault []
    in
    Keyed.node "g"
        []
        (( "story-" ++ Item.getText item
         , lazy Views.cardView { settings = settings, position = ( posX, posY ), selectedItem = selectedItem, item = item }
         )
            :: (children
                    |> Item.indexedMap
                        (\i it ->
                            ( "story-" ++ Item.getText item
                            , storyView
                                settings
                                tail
                                childrenLength
                                ( posX
                                , posY
                                    + (Basics.max 1 (itemCount - parentCount + i + 1)
                                        * (Constants.itemMargin + settings.size.height)
                                      )
                                    + Constants.itemMargin
                                )
                                selectedItem
                                it
                            )
                        )
               )
        )


labelTextView : Settings -> Position -> String -> Svg Msg
labelTextView settings ( posX, posY ) t =
    foreignObject
        [ x <| String.fromInt posX
        , y <| String.fromInt posY
        , width "100"
        , height "30"
        , color settings.color.label
        , fontSize "12"
        , fontWeight "bold"
        , class ".select-none"
        ]
        [ div
            [ Attr.style "font-family" (fontStyle settings)
            , Attr.style "word-wrap" "break-word"
            ]
            [ Html.text t ]
        ]
