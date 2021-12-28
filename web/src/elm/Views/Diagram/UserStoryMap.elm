module Views.Diagram.UserStoryMap exposing (view)

import Constants
import Html.Attributes exposing (property)
import Html.Styled as Html
import Html.Styled.Attributes as Attr
import List
import List.Extra as ListEx
import Models.Diagram as Diagram exposing (Model, Msg, SelectedItem, Settings)
import Models.Diagram.UserStoryMap as UserStoryMap exposing (UserStoryMap)
import Models.Item as Item exposing (Item, Items)
import Models.Position exposing (Position)
import Models.Property as Property exposing (Property)
import String
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Svg.Styled.Keyed as Keyed
import Svg.Styled.Lazy as Lazy
import Views.Diagram.Views as Views
import Views.Empty as Empty


view : Model -> Svg Msg
view model =
    case model.data of
        Diagram.UserStoryMap userStoryMap ->
            Svg.g
                []
                [ Lazy.lazy labelView
                    { settings = model.settings
                    , width = model.svg.width
                    , userStoryMap = userStoryMap
                    , property = model.property
                    }
                , Lazy.lazy mainView
                    { settings = model.settings
                    , selectedItem = model.selectedItem
                    , items = UserStoryMap.getItems userStoryMap
                    , countByTasks = UserStoryMap.countPerTasks userStoryMap
                    , countByReleaseLevel = UserStoryMap.countPerReleaseLevel userStoryMap
                    , property = model.property
                    }
                ]

        _ ->
            Empty.view


mainView : { settings : Settings, property : Property, selectedItem : SelectedItem, items : Items, countByTasks : List Int, countByReleaseLevel : List Int } -> Svg Msg
mainView { settings, selectedItem, items, countByTasks, countByReleaseLevel } =
    Keyed.node "g"
        []
        (ListEx.zip
            countByTasks
            (Item.unwrap items)
            |> List.indexedMap
                (\i ( count, item ) ->
                    ( "activity-" ++ String.fromInt i, activityView settings (List.drop 2 countByReleaseLevel) ( Constants.leftMargin + count * (settings.size.width + Constants.itemMargin), 10 ) selectedItem item )
                )
        )


labelView : { settings : Settings, property : Property, width : Int, userStoryMap : UserStoryMap } -> Svg Msg
labelView { settings, property, width, userStoryMap } =
    let
        posX =
            16

        hierarchy =
            UserStoryMap.getHierarchy userStoryMap

        countPerReleaseLevel =
            UserStoryMap.countPerReleaseLevel userStoryMap
    in
    Svg.g []
        (([ if hierarchy > 0 then
                Svg.line
                    [ SvgAttr.x1 <| String.fromInt posX
                    , SvgAttr.y1 <| String.fromInt (Constants.itemMargin // 2 + (settings.size.height + Constants.itemMargin) * 2)
                    , SvgAttr.x2 <| String.fromInt width
                    , SvgAttr.y2 <| String.fromInt (Constants.itemMargin // 2 + (settings.size.height + Constants.itemMargin) * 2)
                    , SvgAttr.stroke settings.color.line
                    , SvgAttr.strokeWidth "2"
                    ]
                    []

            else
                Svg.line [] []
          , if hierarchy > 0 then
                labelTextView settings ( posX, 10 ) (Property.getUserActivity property |> Maybe.withDefault "USER ACTIVITIES")

            else
                Svg.g [] []
          , if hierarchy > 0 then
                labelTextView settings ( posX, settings.size.height + 25 ) (Property.getUserTask property |> Maybe.withDefault "USER TASKS")

            else
                Svg.g [] []
          ]
            ++ (if hierarchy > 1 then
                    [ labelTextView settings ( posX, settings.size.height * 2 + 50 ) (Property.getUserStory property |> Maybe.withDefault "USER STORIES")
                    , labelTextView settings ( posX, settings.size.height * 2 + 80 ) (Property.getReleaseLevel 1 property |> Maybe.withDefault "RELEASE 1")
                    ]

                else
                    [ Svg.g [] [] ]
               )
         )
            ++ (List.range 1 (hierarchy - 2)
                    |> List.map
                        (\xx ->
                            if List.length countPerReleaseLevel - 2 > xx then
                                let
                                    releaseY =
                                        Constants.itemMargin
                                            // 2
                                            + Constants.itemMargin
                                            + ((settings.size.height + Constants.itemMargin)
                                                * (countPerReleaseLevel
                                                    |> List.take (xx + 2)
                                                    |> List.sum
                                                  )
                                              )
                                            + ((xx - 1) * Constants.itemMargin)
                                in
                                [ Svg.line
                                    [ SvgAttr.x1 <| String.fromInt posX
                                    , SvgAttr.y1 <| String.fromInt releaseY
                                    , SvgAttr.x2 <| String.fromInt width
                                    , SvgAttr.y2 <| String.fromInt releaseY
                                    , SvgAttr.stroke settings.color.line
                                    , SvgAttr.strokeWidth "2"
                                    ]
                                    []
                                , labelTextView settings ( posX, releaseY + Constants.itemMargin ) (Property.getReleaseLevel (xx + 1) property |> Maybe.withDefault ("RELEASE " ++ String.fromInt (xx + 1)))
                                ]

                            else
                                [ Svg.line [] [] ]
                        )
                    |> List.concat
               )
        )


activityView : Settings -> List Int -> Position -> SelectedItem -> Item -> Svg Msg
activityView settings verticalCount ( posX, posY ) selectedItem item =
    Keyed.node "g"
        []
        (( "activity-" ++ Item.getText item
         , Lazy.lazy Views.card
            { settings = settings
            , position = ( posX, posY )
            , selectedItem = selectedItem
            , item = item
            , canMove = True
            }
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
         , Lazy.lazy Views.card
            { settings = settings
            , position = ( posX, posY )
            , selectedItem = selectedItem
            , item = item
            , canMove = True
            }
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
         , Lazy.lazy Views.card
            { settings = settings
            , position = ( posX, posY )
            , selectedItem = selectedItem
            , item = item
            , canMove = True
            }
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
    Svg.foreignObject
        [ SvgAttr.x <| String.fromInt posX
        , SvgAttr.y <| String.fromInt posY
        , SvgAttr.width "100"
        , SvgAttr.height "40"
        , SvgAttr.color settings.color.label
        , SvgAttr.fontSize "12"
        , SvgAttr.fontWeight "bold"
        ]
        [ Html.div
            [ Attr.style "font-family" (Diagram.fontStyle settings)
            , Attr.style "word-wrap" "break-word"
            ]
            [ Html.text t ]
        ]
