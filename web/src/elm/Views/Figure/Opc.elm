module Views.Figure.Opc exposing (view)

import Constants exposing (..)
import Html exposing (div)
import Html.Attributes as Attr
import List.Extra exposing (getAt)
import Models.Figure exposing (Children(..), Color, Comment, Item, ItemType(..), Model, Msg(..), Settings)
import String
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (..)
import Svg.Lazy exposing (..)
import Utils exposing (calcFontSize)


itemWidth =
    300


itemHeight =
    300


view : Model -> Svg Msg
view model =
    let
        posX =
            model.svg.width // 2

        posY =
            model.svg.height // 2

        drawItems =
            model.items |> List.filter (\item -> item.itemType /= Comments)
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
        [ -- Users and Customers
          canvasView model.settings
            itemWidth
            (itemHeight * 2)
            "0"
            "0"
            (drawItems
                |> getAt 2
                |> Maybe.withDefault
                    { text = ""
                    , comment = Nothing
                    , itemType = Activities
                    , children = Children []
                    }
            )

        -- Problems
        , canvasView model.settings
            itemWidth
            itemHeight
            (String.fromInt (itemWidth - 5))
            "0"
            (drawItems
                |> getAt 0
                |> Maybe.withDefault
                    { text = ""
                    , comment = Nothing
                    , itemType = Activities
                    , children = Children []
                    }
            )

        -- Solutions Today
        , canvasView model.settings
            itemWidth
            (itemHeight + 5)
            (String.fromInt (itemWidth - 5))
            (String.fromInt (itemHeight - 5))
            (drawItems
                |> getAt 3
                |> Maybe.withDefault
                    { text = ""
                    , comment = Nothing
                    , itemType = Activities
                    , children = Children []
                    }
            )

        -- Solution Ideas
        , canvasView model.settings
            itemWidth
            (itemHeight * 2)
            (String.fromInt (itemWidth * 2 - 10))
            "0"
            (drawItems
                |> getAt 1
                |> Maybe.withDefault
                    { text = ""
                    , comment = Nothing
                    , itemType = Activities
                    , children = Children []
                    }
            )

        -- ️How will Users use Solution?
        , canvasView model.settings
            itemWidth
            itemHeight
            (String.fromInt (itemWidth * 3 - 15))
            "0"
            (drawItems
                |> getAt 5
                |> Maybe.withDefault
                    { text = ""
                    , comment = Nothing
                    , itemType = Activities
                    , children = Children []
                    }
            )

        -- Adoption Strategy
        , canvasView model.settings
            itemWidth
            (itemHeight + 5)
            (String.fromInt (itemWidth * 3 - 15))
            (String.fromInt (itemHeight - 5))
            (drawItems
                |> getAt 7
                |> Maybe.withDefault
                    { text = ""
                    , comment = Nothing
                    , itemType = Activities
                    , children = Children []
                    }
            )

        -- User Metrics
        , canvasView model.settings
            itemWidth
            (itemHeight * 2)
            (String.fromInt (itemWidth * 4 - 20))
            "0"
            (drawItems
                |> getAt 6
                |> Maybe.withDefault
                    { text = ""
                    , comment = Nothing
                    , itemType = Activities
                    , children = Children []
                    }
            )

        -- Business Challenges
        , canvasView model.settings
            (round (toFloat itemWidth * 2) - 5)
            (itemHeight + 5)
            "0"
            (String.fromInt (itemHeight * 2 - 5))
            (drawItems
                |> getAt 4
                |> Maybe.withDefault
                    { text = ""
                    , comment = Nothing
                    , itemType = Activities
                    , children = Children []
                    }
            )

        -- Budget
        , canvasView model.settings
            itemWidth
            (itemHeight + 5)
            (String.fromInt (round (toFloat itemWidth * 2) - 10))
            (String.fromInt (itemHeight * 2 - 5))
            (drawItems
                |> getAt 9
                |> Maybe.withDefault
                    { text = ""
                    , comment = Nothing
                    , itemType = Activities
                    , children = Children []
                    }
            )

        -- Business Benefits and Metrics
        , canvasView model.settings
            (round (toFloat itemWidth * 2) - 5)
            (itemHeight + 5)
            (String.fromInt (round (toFloat itemWidth * 3) - 15))
            (String.fromInt (itemHeight * 2 - 5))
            (drawItems
                |> getAt 8
                |> Maybe.withDefault
                    { text = ""
                    , comment = Nothing
                    , itemType = Activities
                    , children = Children []
                    }
            )
        ]


canvasView : Settings -> Int -> Int -> String -> String -> Item -> Svg Msg
canvasView settings svgWidth svgHeight posX posY item =
    let
        lines =
            case item.children of
                Children [] ->
                    []

                Children c ->
                    List.map (\i -> i.text) c
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
            , textView settings itemWidth 25 10 30 lines
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
        (lines
            |> List.indexedMap
                (\i line ->
                    foreignObject
                        [ x (String.fromInt posX)
                        , y (String.fromInt ((i + 1) * posY))
                        , width (String.fromInt w)
                        , height (String.fromInt h)
                        , color settings.color.comment.color
                        , fontSize (calcFontSize itemWidth line)
                        , fontFamily settings.font
                        , class "svg-text"
                        ]
                        [ div
                            [ Attr.style "padding" "8px"
                            , Attr.style "font-family" ("'" ++ settings.font ++ "', sans-serif")
                            , Attr.style "word-wrap" "break-word"
                            ]
                            [ Html.text line ]
                        ]
                )
        )
