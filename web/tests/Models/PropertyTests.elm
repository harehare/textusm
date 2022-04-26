module Models.PropertyTests exposing (suite)

import Expect
import Models.Color as Color
import Models.FontSize as FontSize
import Models.Property as Property
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "PropertyTests test"
        [ test "empty string" <|
            \() ->
                Expect.equal (Property.fromString "") Property.empty
        , test "invalid string" <|
            \() ->
                Expect.equal (Property.fromString "test: v") Property.empty
        , test "If valid background_color exists" <|
            \() ->
                Expect.equal (Property.getBackgroundColor (Property.fromString "#background_color: #FF0000")) (Just <| Color.fromString "#FF0000")
        , test "If valid line_color exists" <|
            \() ->
                Expect.equal (Property.getLineColor (Property.fromString "#line_color: #F00000")) (Just <| Color.fromString "#F00000")
        , test "If valid line_size exists" <|
            \() ->
                Expect.equal (Property.getLineSize (Property.fromString "#line_size: 3")) (Just 3)
        , test "If invalid line_color exists" <|
            \() ->
                Expect.equal (Property.getLineSize (Property.fromString "#line_size: v")) Nothing
        , test "If valid user_activities exists" <|
            \() ->
                Expect.equal (Property.getUserActivity (Property.fromString "#user_activities: v")) (Just "v")
        , test "If valid user_tasks exists" <|
            \() ->
                Expect.equal (Property.getUserTask (Property.fromString "#user_tasks: v")) (Just "v")
        , test "If valid user_stories exists" <|
            \() ->
                Expect.equal (Property.getUserStory (Property.fromString "#user_stories: v")) (Just "v")
        , test "If valid title exists" <|
            \() ->
                Expect.equal (Property.getTitle (Property.fromString "#title: v")) (Just "v")
        , test "If valid zoom_control exists" <|
            \() ->
                Expect.equal (Property.getZoomControl (Property.fromString "#zoom_control: true")) (Just True)
        , test "If invalid zoom_control exists" <|
            \() ->
                Expect.equal (Property.getZoomControl (Property.fromString "#zoom_control: v")) (Just False)
        , test "If valid card_foreground_color1 exists" <|
            \() ->
                Expect.equal (Property.getCardForegroundColor1 (Property.fromString "#card_foreground_color1: #FF0000")) (Just <| Color.fromString "#FF0000")
        , test "If valid card_foreground_color2 exists" <|
            \() ->
                Expect.equal (Property.getCardForegroundColor2 (Property.fromString "#card_foreground_color2: #FF0000")) (Just <| Color.fromString "#FF0000")
        , test "If valid card_foreground_color3 exists" <|
            \() ->
                Expect.equal (Property.getCardForegroundColor3 (Property.fromString "#card_foreground_color3: #FF0000")) (Just <| Color.fromString "#FF0000")
        , test "If valid card_background_color1 exists" <|
            \() ->
                Expect.equal (Property.getCardBackgroundColor1 (Property.fromString "#card_background_color1: #FF0000")) (Just <| Color.fromString "#FF0000")
        , test "If valid card_background_color2 exists" <|
            \() ->
                Expect.equal (Property.getCardBackgroundColor2 (Property.fromString "#card_background_color2: #FF0000")) (Just <| Color.fromString "#FF0000")
        , test "If valid card_background_color3 exists" <|
            \() ->
                Expect.equal (Property.getCardBackgroundColor3 (Property.fromString "#card_background_color3: #FF0000")) (Just <| Color.fromString "#FF0000")
        , test "If valid toolbar exists" <|
            \() ->
                Expect.equal (Property.getToolbar (Property.fromString "#toolbar: true")) (Just True)
        , test "If invalid toolbar exists" <|
            \() ->
                Expect.equal (Property.getToolbar (Property.fromString "#toolbar: v")) (Just False)
        , test "If valid card_width exists" <|
            \() ->
                Expect.equal (Property.getCardWidth (Property.fromString "#card_width: 10")) (Just 10)
        , test "If invalid card_width not exists" <|
            \() ->
                Expect.equal (Property.getCardWidth (Property.fromString "#card_width: a")) Nothing
        , test "If valid card_height exists" <|
            \() ->
                Expect.equal (Property.getCardHeight (Property.fromString "#card_height: 10")) (Just 10)
        , test "If invalid card_height exists" <|
            \() ->
                Expect.equal (Property.getCardHeight (Property.fromString "#card_height: a")) Nothing
        , test "If valid font_size exists" <|
            \() ->
                Expect.equal (Property.getFontSize (Property.fromString "#font_size: 10")) (Just <| FontSize.fromInt 10)
        , test "If invalid font_size exists" <|
            \() ->
                Expect.equal (Property.getFontSize (Property.fromString "#font_size: a")) Nothing
        , test "If valid text_color exists" <|
            \() ->
                Expect.equal (Property.getTextColor (Property.fromString "#text_color: #FF0000")) (Just <| Color.fromString "#FF0000")
        , test "If invalid text_color exists" <|
            \() ->
                Expect.equal (Property.getTextColor (Property.fromString "#text_color: a")) (Just <| Color.background1Defalut)
        , test "If valid node_width exists" <|
            \() ->
                Expect.equal (Property.getNodeWidth (Property.fromString "#node_width: 10")) (Just 10)
        , test "If invalid node_width not exists" <|
            \() ->
                Expect.equal (Property.getNodeWidth (Property.fromString "#node_width: a")) Nothing
        , test "If valid node_height exists" <|
            \() ->
                Expect.equal (Property.getNodeHeight (Property.fromString "#node_height: 10")) (Just 10)
        , test "If invalid node_height exists" <|
            \() ->
                Expect.equal (Property.getNodeHeight (Property.fromString "#node_height: a")) Nothing
        ]
