module Constants exposing
    ( canvasOffset
    , fontSize
    , fragmentOffset
    , ganttItemSize
    , imageDataPrefix
    , imagePrefix
    , indentSpace
    , inputPrefix
    , itemHeight
    , itemMargin
    , itemSpan
    , itemWidth
    , largeItemHeight
    , largeItemWidth
    , leftMargin
    , legacySettingsPrefix
    , markdownPrefix
    , messageMargin
    , participantMargin
    , settingsPrefix
    , space
    , tableMargin
    , tableRowHeight
    , commentPrefix
    )


canvasOffset : Int
canvasOffset =
    5


fontSize : String
fontSize =
    "14"


fragmentOffset : Int
fragmentOffset =
    70


ganttItemSize : Int
ganttItemSize =
    32


indentSpace : Int
indentSpace =
    4


inputPrefix : String
inputPrefix =
    "    "


itemHeight : Int
itemHeight =
    300


itemMargin : Int
itemMargin =
    16


itemSpan : Int
itemSpan =
    40


itemWidth : Int
itemWidth =
    300


largeItemHeight : Int
largeItemHeight =
    600


largeItemWidth : Int
largeItemWidth =
    600


leftMargin : Int
leftMargin =
    140


messageMargin : Int
messageMargin =
    100


participantMargin : Int
participantMargin =
    150


space : String
space =
    "    "


tableMargin : Int
tableMargin =
    160


tableRowHeight : Int
tableRowHeight =
    40


settingsPrefix : String
settingsPrefix =
    ": |"


legacySettingsPrefix : String
legacySettingsPrefix =
    "|"


markdownPrefix : String
markdownPrefix =
    "md:"


imagePrefix : String
imagePrefix =
    "image:"


imageDataPrefix : String
imageDataPrefix =
    "data:image/"


commentPrefix : String
commentPrefix =
    "#"
