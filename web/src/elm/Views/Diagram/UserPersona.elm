module Views.Diagram.UserPersona exposing (view)

import Constants exposing (..)
import Html exposing (div, img)
import Html.Attributes as Attr
import List.Extra exposing (getAt)
import Models.Diagram exposing (Model, Msg(..), Settings)
import Models.Item as Item exposing (Children, Item, ItemType(..))
import String
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (..)
import Svg.Lazy exposing (..)


view : Model -> Svg Msg
view model =
    let
        drawItems =
            model.items |> List.filter (\item -> item.itemType /= Comments)

        itemHeight =
            Basics.max Constants.itemHeight (14 * (List.maximum model.countByTasks |> Maybe.withDefault 0))
    in
    g
        [ transform
            ("translate("
                ++ String.fromInt model.x
                ++ ","
                ++ String.fromInt model.y
                ++ ")"
            )
        , fill "#F5F5F6"
        ]
        [ -- Name
          canvasImageView model.settings
            Constants.itemWidth
            itemHeight
            "0"
            "0"
            (drawItems
                |> getAt 0
                |> Maybe.withDefault
                    { lineNo = 0
                    , text = ""
                    , itemType = Activities
                    , children = Item.empty
                    }
            )

        -- Who am i...
        , canvasView model.settings
            Constants.itemWidth
            itemHeight
            (String.fromInt (Constants.itemWidth - 5))
            "0"
            (drawItems
                |> getAt 1
                |> Maybe.withDefault
                    { lineNo = 0
                    , text = ""
                    , itemType = Activities
                    , children = Item.empty
                    }
            )

        -- three reasons to use your product
        , canvasView model.settings
            (round (Constants.itemWidth * 1.5 - 5))
            itemHeight
            (String.fromInt (round (toFloat Constants.itemWidth * 2) - 10))
            "0"
            (drawItems
                |> getAt 2
                |> Maybe.withDefault
                    { lineNo = 0
                    , text = ""
                    , itemType = Activities
                    , children = Item.empty
                    }
            )

        -- three reasons to buy your product
        , canvasView model.settings
            (round (Constants.itemWidth * 1.5))
            itemHeight
            (String.fromInt (round (toFloat Constants.itemWidth * 3.5) - 20))
            "0"
            (drawItems
                |> getAt 3
                |> Maybe.withDefault
                    { lineNo = 0
                    , text = ""
                    , itemType = Activities
                    , children = Item.empty
                    }
            )

        -- My interests
        , canvasView model.settings
            Constants.itemWidth
            itemHeight
            "0"
            (String.fromInt (itemHeight - 5))
            (drawItems
                |> getAt 4
                |> Maybe.withDefault
                    { lineNo = 0
                    , text = ""
                    , itemType = Activities
                    , children = Item.empty
                    }
            )

        -- My personality
        , canvasView model.settings
            Constants.itemWidth
            itemHeight
            (String.fromInt (Constants.itemWidth - 5))
            (String.fromInt (itemHeight - 5))
            (drawItems
                |> getAt 5
                |> Maybe.withDefault
                    { lineNo = 0
                    , text = ""
                    , itemType = Activities
                    , children = Item.empty
                    }
            )

        -- My skils
        , canvasView model.settings
            Constants.itemWidth
            itemHeight
            (String.fromInt (Constants.itemWidth * 2 - 10))
            (String.fromInt (itemHeight - 5))
            (drawItems
                |> getAt 6
                |> Maybe.withDefault
                    { lineNo = 0
                    , text = ""
                    , itemType = Activities
                    , children = Item.empty
                    }
            )

        -- My dreams
        , canvasView model.settings
            Constants.itemWidth
            itemHeight
            (String.fromInt (Constants.itemWidth * 3 - 15))
            (String.fromInt (itemHeight - 5))
            (drawItems
                |> getAt 7
                |> Maybe.withDefault
                    { lineNo = 0
                    , text = ""
                    , itemType = Activities
                    , children = Item.empty
                    }
            )

        -- My relationship with technology
        , canvasView model.settings
            Constants.itemWidth
            itemHeight
            (String.fromInt (Constants.itemWidth * 4 - 20))
            (String.fromInt (itemHeight - 5))
            (drawItems
                |> getAt 8
                |> Maybe.withDefault
                    { lineNo = 0
                    , text = ""
                    , itemType = Activities
                    , children = Item.empty
                    }
            )
        ]


canvasImageView : Settings -> Int -> Int -> String -> String -> Item -> Svg Msg
canvasImageView settings svgWidth svgHeight posX posY item =
    let
        lines =
            Item.unwrapChildren item.children
                |> List.filter (\i -> i.itemType /= Comments)
                |> List.map (\i -> i.text)
    in
    svg
        [ width (String.fromInt svgWidth)
        , height (String.fromInt svgHeight)
        , x posX
        , y posY
        ]
        [ g []
            [ rectView (String.fromInt svgWidth) (String.fromInt svgHeight) settings.color.line
            , imageView settings (Constants.itemWidth - 5) svgHeight 5 5 (lines |> List.head |> Maybe.withDefault "")
            , titleView settings 10 10 item.text
            ]
        ]


canvasView : Settings -> Int -> Int -> String -> String -> Item -> Svg Msg
canvasView settings svgWidth svgHeight posX posY item =
    let
        lines =
            Item.unwrapChildren item.children
                |> List.filter (\i -> i.itemType /= Comments)
                |> List.map (\i -> i.text)
    in
    svg
        [ width (String.fromInt svgWidth)
        , height (String.fromInt svgHeight)
        , x posX
        , y posY
        ]
        [ g []
            [ rectView (String.fromInt svgWidth) (String.fromInt svgHeight) settings.color.line
            , titleView settings 10 10 item.text
            , textView settings (Constants.largeItemWidth - 13) svgHeight 10 35 lines
            ]
        ]


rectView : String -> String -> String -> Svg Msg
rectView w h color =
    rect
        [ width w
        , height h
        , stroke color
        , strokeWidth "10"
        ]
        []


titleView : Settings -> Int -> Int -> String -> Svg Msg
titleView settings posX posY title =
    text_
        [ x (String.fromInt posX)
        , y (String.fromInt (posY + 14))
        , fontFamily settings.font
        , fill settings.color.label
        , fontSize "16"
        , fontWeight "bold"
        , class "svg-text"
        ]
        [ text title ]


textView : Settings -> Int -> Int -> Int -> Int -> List String -> Svg Msg
textView settings w h posX posY lines =
    g []
        [ foreignObject
            [ x (String.fromInt posX)
            , y (String.fromInt posY)
            , width (String.fromInt w)
            , height (String.fromInt h)
            , color settings.color.comment.color
            , fontSize "14"
            , fontFamily settings.font
            , class "svg-text"
            ]
            (lines
                |> List.map
                    (\line ->
                        div
                            [ Attr.style "font-family" ("'" ++ settings.font ++ "', sans-serif")
                            , Attr.style "word-wrap" "break-word"
                            , Attr.style "padding" "0 8px 8px 0"
                            ]
                            [ Html.text line ]
                    )
            )
        ]


imageView settings w h posX posY url =
    svg
        [ width (String.fromInt w)
        , height (String.fromInt h)
        ]
        [ image
            [ x (String.fromInt posX)
            , y (String.fromInt posY)
            , width (String.fromInt w)
            , height (String.fromInt h)
            , xlinkHref url
            ]
            []
        ]
