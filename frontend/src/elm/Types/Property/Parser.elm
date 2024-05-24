module Types.Property.Parser exposing
    ( Parsed(..)
    , backgroundColor
    , backgroundImage
    , canvasBackgroundColor
    , cardBackgroundColor1
    , cardBackgroundColor2
    , cardBackgroundColor3
    , cardForegroundColor1
    , cardForegroundColor2
    , cardForegroundColor3
    , cardHeight
    , cardWidth
    , fontSize
    , lineColor
    , lineSize
    , nodeHeight
    , nodeWidth
    , parser
    , releaseLevel
    , textColor
    , title
    , toolbar
    , userActivities
    , userStories
    , userTasks
    , zoomControl
    )

import Constants
import Parser
    exposing
        ( (|.)
        , (|=)
        , Parser
        , chompUntilEndOr
        , getChompedString
        , int
        , keyword
        , map
        , oneOf
        , spaces
        , succeed
        , symbol
        )


type Parsed
    = Parsed String String


parser : Parser Parsed
parser =
    succeed (\name value -> Parsed name value)
        |. symbol Constants.commentPrefix
        |. spaces
        |= getChompedString
            (oneOf
                [ succeed ()
                    |. symbol release
                    |. (int |> map String.fromInt)
                , keyword backgroundColor
                , keyword backgroundImage
                , keyword canvasBackgroundColor
                , keyword cardBackgroundColor1
                , keyword cardBackgroundColor2
                , keyword cardBackgroundColor3
                , keyword cardForegroundColor1
                , keyword cardForegroundColor2
                , keyword cardForegroundColor3
                , keyword cardHeight
                , keyword cardWidth
                , keyword fontSize
                , keyword lineColor
                , keyword lineSize
                , keyword nodeHeight
                , keyword nodeWidth
                , keyword textColor
                , keyword title
                , keyword toolbar
                , keyword userActivities
                , keyword userStories
                , keyword userTasks
                , keyword zoomControl
                ]
            )
        |. spaces
        |. symbol ":"
        |. spaces
        |= getChompedString (chompUntilEndOr "\n")


backgroundColor : String
backgroundColor =
    "background_color"


backgroundImage : String
backgroundImage =
    "background_image"


cardForegroundColor1 : String
cardForegroundColor1 =
    "card_foreground_color1"


cardBackgroundColor1 : String
cardBackgroundColor1 =
    "card_background_color1"


cardForegroundColor2 : String
cardForegroundColor2 =
    "card_foreground_color2"


cardBackgroundColor2 : String
cardBackgroundColor2 =
    "card_background_color2"


cardForegroundColor3 : String
cardForegroundColor3 =
    "card_foreground_color3"


cardBackgroundColor3 : String
cardBackgroundColor3 =
    "card_background_color3"


canvasBackgroundColor : String
canvasBackgroundColor =
    "canvas_background_color"


cardWidth : String
cardWidth =
    "card_width"


cardHeight : String
cardHeight =
    "card_height"


fontSize : String
fontSize =
    "font_size"


lineColor : String
lineColor =
    "line_color"


lineSize : String
lineSize =
    "line_size"


nodeWidth : String
nodeWidth =
    "node_width"


nodeHeight : String
nodeHeight =
    "node_height"


release : String
release =
    "release"


releaseLevel : Int -> String
releaseLevel level =
    release ++ String.fromInt level


title : String
title =
    "title"


userActivities : String
userActivities =
    "user_activities"


userTasks : String
userTasks =
    "user_tasks"


userStories : String
userStories =
    "user_stories"


toolbar : String
toolbar =
    "toolbar"


textColor : String
textColor =
    "text_color"


zoomControl : String
zoomControl =
    "zoom_control"
