module Constants exposing (commentSize, ganttItemSize, inputPrefix, itemHeight, itemMargin, itemSpan, itemWidth, largeItemHeight, largeItemWidth, leftMargin, smallItemMargin)


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
    30


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
