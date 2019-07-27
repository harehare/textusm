module Views.Diagram.UserStoryMap exposing (view)

import Basics exposing (max)
import Constants exposing (..)
import Html exposing (div, img)
import Html.Attributes as Attr
import Json.Decode as D
import List
import List.Extra exposing (getAt, zip)
import Models.Diagram exposing (Comment, Model, Msg(..), Settings)
import Models.Item as Item exposing (Children, Item, ItemType(..))
import String
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (onClick, onMouseOut, onMouseOver, stopPropagationOn)
import Svg.Keyed as Keyed
import Svg.Lazy exposing (lazy2, lazy4, lazy5)
import Utils exposing (calcFontSize)


view : Model -> Svg Msg
view model =
    g
        [ transform
            ("translate("
                ++ String.fromInt model.x
                ++ ","
                ++ String.fromInt model.y
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
        , case model.comment of
            Just xs ->
                lazy2 commentContentView model.settings xs

            Nothing ->
                g [] []
        ]


mainView : Settings -> List Item -> List Int -> List Int -> Svg Msg
mainView settings items countByTasks countByHierarchy =
    Keyed.node "g"
        []
        (zip
            countByTasks
            items
            |> List.filter (\( _, i ) -> i.itemType /= Comments)
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


itemView : Settings -> ItemType -> Int -> Int -> Item -> Svg Msg
itemView settings itemType posX posY item =
    let
        ( color, backgroundColor ) =
            case itemType of
                Activities ->
                    ( settings.color.activity.color, settings.color.activity.backgroundColor )

                Tasks ->
                    ( settings.color.task.color, settings.color.task.backgroundColor )

                _ ->
                    ( settings.color.story.color, settings.color.story.backgroundColor )
    in
    svg
        [ width (String.fromInt settings.size.width)
        , height (String.fromInt settings.size.height)
        , x (String.fromInt posX)
        , y (String.fromInt posY)
        , onClick (ItemClick item)
        , stopPropagationOn "dblclick" (D.map (\d -> ( d, True )) (D.succeed (ItemDblClick item)))
        ]
        [ g
            []
            [ rectView
                (String.fromInt settings.size.width)
                (String.fromInt (settings.size.height - 1))
                backgroundColor
            , textView settings "0" "0" color item.text
            ]
        ]


commentView : Settings -> Int -> Int -> String -> Svg Msg
commentView settings posX posY text =
    rect
        [ x (String.fromInt posX)
        , y (String.fromInt posY)
        , width (String.fromInt commentSize)
        , height (String.fromInt commentSize)
        , fill settings.color.comment.backgroundColor
        , color settings.color.comment.color
        , onMouseOver (ShowComment { x = posX, y = posY, text = text })
        , onMouseOut HideComment
        ]
        []


commentContentView : Settings -> Comment -> Svg Msg
commentContentView settings comment =
    g []
        [ rect
            [ x (String.fromInt comment.x)
            , y (String.fromInt (comment.y + commentSize))
            , width (String.fromInt settings.size.width)
            , height (String.fromInt settings.size.height)
            , fill settings.color.comment.backgroundColor
            , color settings.color.comment.color
            , fontSize (calcFontSize settings.size.width comment.text)
            , fontFamily settings.font
            , class "svg-text"
            ]
            []
        , foreignObject
            [ x (String.fromInt comment.x)
            , y (String.fromInt (comment.y + commentSize))
            , width (String.fromInt settings.size.width)
            , height (String.fromInt settings.size.height)
            , fill settings.color.comment.backgroundColor
            , color settings.color.comment.color
            , fontSize (calcFontSize settings.size.width comment.text)
            , fontFamily settings.font
            ]
            [ div
                [ Attr.style "padding" "8px"
                , Attr.style "font-family" ("'" ++ settings.font ++ "', sans-serif")
                , Attr.style "color" settings.color.comment.color
                , Attr.style "backgrond-color" settings.color.comment.backgroundColor
                , Attr.style "word-wrap" "break-word"
                ]
                [ Html.text comment.text ]
            ]
        ]


activityView : Settings -> List Int -> Int -> Int -> Item -> Svg Msg
activityView settings verticalCount posX posY item =
    Keyed.node "g"
        []
        ([ ( "activity-" ++ item.text
           , itemView settings Activities posX posY item
           )
         , ( "comment-" ++ item.text
           , case item.comment of
                Just xs ->
                    commentView settings (posX + settings.size.width - commentSize - 5) posY xs

                Nothing ->
                    text_ [] []
           )
         ]
            ++ (Item.unwrapChildren item.children
                    |> List.filter (\i -> i.itemType /= Comments)
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
        ([ ( "task-" ++ item.text
           , itemView settings Tasks posX posY item
           )
         , ( "comment-" ++ item.text
           , case item.comment of
                Just xs ->
                    commentView settings (posX + settings.size.width - commentSize - 5) posY xs

                Nothing ->
                    text_ [] []
           )
         ]
            ++ (children
                    |> List.filter (\i -> i.itemType /= Comments)
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
        ([ ( "story-" ++ item.text
           , itemView settings (Stories 1) posX posY item
           )
         , ( "comment-" ++ item.text
           , case item.comment of
                Just xs ->
                    commentView settings (posX + settings.size.width - commentSize - 5) posY xs

                Nothing ->
                    text_ [] []
           )
         ]
            ++ (children
                    |> List.filter (\i -> i.itemType /= Comments)
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


rectView : String -> String -> String -> Svg Msg
rectView posX poxY color =
    rect
        [ width posX
        , height poxY
        , fill color
        , stroke "rgba(192,192,192,0.5)"
        ]
        []


textView : Settings -> String -> String -> String -> String -> Svg Msg
textView settings posX posY c t =
    foreignObject
        [ x posX
        , y posY
        , width (String.fromInt settings.size.width)
        , height (String.fromInt settings.size.height)
        , fill c
        , color c
        , fontSize (calcFontSize settings.size.width t)
        , fontFamily settings.font
        , class "svg-text"
        ]
        [ if
            (String.startsWith "/" t || String.startsWith "https://" t || String.startsWith "http://" t)
                && (String.endsWith ".svg" t || String.endsWith ".png" t || String.endsWith ".jpg" t)
          then
            img
                [ Attr.style "object-fit" "cover"
                , Attr.style "width" (String.fromInt settings.size.width)
                , Attr.src t
                ]
                []

          else
            div
                [ Attr.style "padding" "8px"
                , Attr.style "font-family" ("'" ++ settings.font ++ "', sans-serif")
                , Attr.style "word-wrap" "break-word"
                ]
                [ Html.text t ]
        ]


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
        , class "svg-text"
        ]
        [ div
            [ Attr.style "font-family" ("'" ++ settings.font ++ "', sans-serif")
            , Attr.style "word-wrap" "break-word"
            ]
            [ Html.text t ]
        ]
