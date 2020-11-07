module Constants exposing (commentSize, fontSize, fragmentOffset, ganttItemSize, indentSpace, inputPrefix, itemHeight, itemMargin, itemSpan, itemWidth, largeItemHeight, largeItemWidth, leftMargin, messageMargin, participantMargin, smallItemMargin, space, tableMargin, tableRowHeight)


space : String
space =
    "    "


indentSpace : Int
indentSpace =
    4


fontSize : String
fontSize =
    "14"


itemSpan : Int
itemSpan =
    40


commentSize : Int
commentSize =
    13


itemMargin : Int
itemMargin =
    16


ganttItemSize : Int
ganttItemSize =
    32


smallItemMargin : Int
smallItemMargin =
    itemMargin // 8


leftMargin : Int
leftMargin =
    140


inputPrefix : String
inputPrefix =
    "    "


itemWidth : Int
itemWidth =
    300


itemHeight : Int
itemHeight =
    300


largeItemWidth : Int
largeItemWidth =
    600


largeItemHeight : Int
largeItemHeight =
    600


tableRowHeight : Int
tableRowHeight =
    40


tableMargin : Int
tableMargin =
    160


participantMargin : Int
participantMargin =
    150


messageMargin : Int
messageMargin =
    100


fragmentOffset : Int
fragmentOffset =
    70
