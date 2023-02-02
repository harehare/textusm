module Models.Item exposing
    ( Children
    , Hierarchy
    , Item
    , Items
    , childrenFromItems
    , cons
    , count
    , empty
    , emptyChildren
    , flatten
    , fromList
    , fromString
    , getAt
    , getBackgroundColor
    , getChildren
    , getChildrenCount
    , getChildrenItems
    , getComments
    , getFontSize
    , getFontSizeWithProperty
    , getForegroundColor
    , getHierarchyCount
    , getIndent
    , getLeafCount
    , getLineNo
    , getMultiLineText
    , getOffset
    , getOffsetSize
    , getPosition
    , getSettings
    , getSize
    , getText
    , getTextOnly
    , getTrimmedText
    , head
    , indexedMap
    , isCanvas
    , isComment
    , isEmpty
    , isHighlight
    , isHorizontalLine
    , isImage
    , isMarkdown
    , isText
    , isVerticalLine
    , itemFromString
    , length
    , map
    , mapWithRecursive
    , new
    , resetOffset
    , search
    , searchClear
    , split
    , splitAt
    , tail
    , toLineString
    , unwrap
    , unwrapChildren
    , withChildren
    , withComments
    , withHighlight
    , withLineNo
    , withOffset
    , withOffsetSize
    , withSettings
    , withText
    , withTextOnly
    )

import Constants exposing (indentSpace, inputPrefix)
import List.Extra as ListEx
import Maybe
import Models.Color exposing (Color)
import Models.FontSize as FontSize exposing (FontSize)
import Models.Item.Settings as ItemSettings
import Models.Item.Value as ItemValue
import Models.Position exposing (Position)
import Models.Property as Property exposing (Property)
import Models.Size as Size exposing (Size)
import Simple.Fuzzy as Fuzzy


type Children
    = Children Items


type alias Hierarchy =
    Int


type Item
    = Item
        { lineNo : Int
        , value : ItemValue.Value
        , comments : Maybe String
        , settings : Maybe ItemSettings.Settings
        , children : Children
        , highlight : Bool
        }


type Items
    = Items (List Item)


childrenFromItems : Items -> Children
childrenFromItems (Items items) =
    Children (Items items)


cons : Item -> Items -> Items
cons item (Items items) =
    Items (item :: items)


count : (Item -> Bool) -> Items -> Int
count f items =
    items |> flatten |> unwrap |> ListEx.count f


empty : Items
empty =
    Items []


emptyChildren : Children
emptyChildren =
    Children empty


flatten : Items -> Items
flatten (Items items) =
    case items of
        [] ->
            Items items

        _ ->
            Items (items ++ List.concatMap (\(Item item) -> unwrap <| flatten <| unwrapChildren item.children) items)


fromList : List Item -> Items
fromList items =
    Items items


fromString : String -> ( Hierarchy, Items )
fromString text =
    if text == "" then
        ( 0, empty )

    else if String.isEmpty text then
        ( 0, empty )

    else
        let
            ( indentList, loadedItems ) =
                loadText_ { indent = 0, input = text, lineNo = 0 }
        in
        ( indentList
            |> List.maximum
            |> Maybe.map (\x -> x - 1)
            |> Maybe.withDefault 0
        , loadedItems
        )


itemFromString : Int -> String -> Item
itemFromString lineNo text =
    new |> withText text |> withLineNo lineNo


getAt : Int -> Items -> Maybe Item
getAt i (Items items) =
    ListEx.getAt i items


getBackgroundColor : Item -> Maybe Color
getBackgroundColor item =
    item
        |> getSettings
        |> Maybe.withDefault ItemSettings.new
        |> ItemSettings.getBackgroundColor


getChildren : Item -> Children
getChildren (Item i) =
    i.children


getIndent : Item -> Int
getIndent (Item i) =
    ItemValue.getIndent i.value


getChildrenCount : Item -> Int
getChildrenCount (Item item) =
    childrenCount <| unwrapChildren item.children


getChildrenItems : Item -> Items
getChildrenItems (Item i) =
    i.children |> unwrapChildren


getComments : Item -> Maybe String
getComments (Item i) =
    Maybe.map (\c -> commentPrefix ++ c) i.comments


getFontSize : Item -> Maybe FontSize
getFontSize item =
    item
        |> getSettings
        |> Maybe.map ItemSettings.getFontSize


getFontSizeWithProperty : Item -> Property -> FontSize
getFontSizeWithProperty item property =
    case ( Property.getFontSize property, item |> getSettings |> Maybe.map ItemSettings.getFontSize ) of
        ( _, Just f ) ->
            f

        ( Just f, _ ) ->
            f

        _ ->
            FontSize.default


getForegroundColor : Item -> Maybe Color
getForegroundColor item =
    item
        |> getSettings
        |> Maybe.withDefault ItemSettings.new
        |> ItemSettings.getForegroundColor


getHierarchyCount : Item -> Int
getHierarchyCount (Item item) =
    unwrapChildren item.children
        |> hierarchyCount
        |> List.length


getSettings : Item -> Maybe ItemSettings.Settings
getSettings (Item i) =
    i.settings


getLeafCount : Item -> Int
getLeafCount (Item item) =
    leafCount <| unwrapChildren item.children


getLineNo : Item -> Int
getLineNo (Item i) =
    i.lineNo


getOffset : Item -> Position
getOffset item =
    item
        |> getSettings
        |> Maybe.withDefault ItemSettings.new
        |> ItemSettings.getOffset


getOffsetSize : Item -> Size
getOffsetSize item =
    item
        |> getSettings
        |> Maybe.withDefault ItemSettings.new
        |> ItemSettings.getOffsetSize
        |> Maybe.withDefault Size.zero


getPosition : Item -> Position -> Position
getPosition item basePosition =
    let
        ( offsetX, offsetY ) =
            getOffset item
    in
    Tuple.mapBoth (\x -> x + offsetX) (\y -> y + offsetY) basePosition


getSize : Item -> Size -> Position
getSize item baseSize =
    let
        ( offsetWidth, offsetHeight ) =
            getOffsetSize item
    in
    Tuple.mapBoth (\x -> x + offsetWidth) (\y -> y + offsetHeight) baseSize


getText : Item -> String
getText (Item i) =
    ItemValue.toString i.value


getMultiLineText : Item -> String
getMultiLineText item =
    String.replace "\n" "\\n" <| getText item


getFullText : Item -> String
getFullText (Item i) =
    ItemValue.toFullString i.value


getTrimmedText : Item -> String
getTrimmedText item =
    getText item |> String.trim


getTextOnly : Item -> String
getTextOnly (Item item) =
    ItemValue.toString item.value |> String.trim


head : Items -> Maybe Item
head (Items items) =
    List.head items


indexedMap : (Int -> Item -> b) -> Items -> List b
indexedMap f (Items items) =
    List.indexedMap f items


isCanvas : Item -> Bool
isCanvas item =
    getComments item |> Maybe.map (\comments -> String.replace " " "" comments == "#canvas") |> Maybe.withDefault False


isEmpty : Items -> Bool
isEmpty (Items items) =
    List.isEmpty items


isHighlight : Item -> Bool
isHighlight (Item i) =
    i.highlight


isComment : Item -> Bool
isComment (Item i) =
    ItemValue.isCooment i.value


isHorizontalLine : Item -> Bool
isHorizontalLine item =
    getText item |> String.trim |> String.toLower |> String.startsWith "---"


isImage : Item -> Bool
isImage (Item item) =
    ItemValue.isImage item.value || ItemValue.isImageData item.value



-- Items


isMarkdown : Item -> Bool
isMarkdown (Item item) =
    ItemValue.isMarkdown item.value


isText : Item -> Bool
isText item =
    getComments item |> Maybe.map (\comments -> String.replace " " "" comments == "#text") |> Maybe.withDefault False


isVerticalLine : Item -> Bool
isVerticalLine item =
    getText item |> String.trim |> String.toLower |> String.startsWith "/"


length : Items -> Int
length (Items items) =
    List.length items


map : (Item -> a) -> Items -> List a
map f (Items items) =
    List.map f items


mapWithRecursive : (Item -> Item) -> Items -> Items
mapWithRecursive f (Items items) =
    Items <| List.map (mapWithRecursiveHelper f) items


new : Item
new =
    Item
        { lineNo = 0
        , value = ItemValue.empty
        , comments = Nothing
        , settings = Nothing
        , children = emptyChildren
        , highlight = False
        }


search : Items -> String -> Items
search items query =
    mapWithRecursive (\item -> withHighlight (Fuzzy.match query (getText item)) item) items


searchClear : Items -> Items
searchClear items =
    mapWithRecursive (withHighlight False) items


split : String -> ( String, ItemSettings.Settings, Maybe String )
split text =
    let
        ( _, tokens ) =
            splitText text
    in
    case tokens of
        [ text_ ] ->
            let
                ( t, comment ) =
                    splitLine text_
            in
            ( t, ItemSettings.new, comment )

        [ text_, settingsString ] ->
            let
                ( t, comment ) =
                    splitLine text_
            in
            case ItemSettings.fromString settingsString of
                Just settings ->
                    ( t, settings, comment )

                Nothing ->
                    ( t, ItemSettings.new, comment )

        _ ->
            ( text, ItemSettings.new, Nothing )


splitAt : Int -> Items -> ( Items, Items )
splitAt i (Items items) =
    let
        ( left, right ) =
            ListEx.splitAt i items
    in
    ( Items left, Items right )


tail : Items -> Maybe Items
tail (Items items) =
    List.tail items
        |> Maybe.map (\i -> Items i)


toLineString : Item -> String
toLineString item =
    let
        comment : String
        comment =
            Maybe.withDefault "" (getComments item)
    in
    case getSettings item of
        Just s ->
            getFullText item ++ comment ++ textSeparator ++ ItemSettings.toString s

        Nothing ->
            getFullText item ++ comment


unwrap : Items -> List Item
unwrap (Items items) =
    items


unwrapChildren : Children -> Items
unwrapChildren (Children (Items items)) =
    Items (items |> List.filter (\(Item i) -> not <| ItemValue.isCooment i.value))


withChildren : Children -> Item -> Item
withChildren children (Item item) =
    Item { item | children = children }


withComments : Maybe String -> Item -> Item
withComments comments (Item item) =
    Item
        { item
            | comments =
                comments
                    |> Maybe.andThen
                        (\c ->
                            if c |> String.trim |> String.isEmpty then
                                Nothing

                            else
                                Just c
                        )
        }


withHighlight : Bool -> Item -> Item
withHighlight h (Item item) =
    Item { item | highlight = h }


withSettings : Maybe ItemSettings.Settings -> Item -> Item
withSettings itemSettings (Item item) =
    Item { item | settings = itemSettings }


withLineNo : Int -> Item -> Item
withLineNo lineNo (Item item) =
    Item { item | lineNo = lineNo }


withOffset : Position -> Item -> Item
withOffset newPosition item =
    withSettings (Just (getSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.withOffset newPosition)) item


withOffsetSize : Size -> Item -> Item
withOffsetSize newSize item =
    withSettings (Just (getSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.withOffsetSize (Just newSize))) item


withText : String -> Item -> Item
withText text (Item item) =
    let
        ( displayText, settings, comments ) =
            let
                ( sep, tokens ) =
                    splitText text
                        |> Tuple.mapSecond (List.map String.toList)

                tuple : ( String, Maybe String )
                tuple =
                    case tokens of
                        [ x, '{' :: xs ] ->
                            ( String.fromList x, Just <| String.fromList <| '{' :: xs )

                        _ :: _ :: _ ->
                            ( List.take (List.length tokens - 1) tokens
                                |> List.map String.fromList
                                |> String.join sep
                            , ListEx.last tokens |> Maybe.map String.fromList
                            )

                        _ ->
                            ( text, Nothing )
            in
            case tuple of
                ( t, Just s ) ->
                    let
                        ( text_, comments_ ) =
                            splitLine t
                    in
                    case ItemSettings.fromString s of
                        Just settings_ ->
                            ( text_, Just settings_, comments_ )

                        Nothing ->
                            ( text_ ++ sep ++ s, Nothing, comments_ )

                ( _, Nothing ) ->
                    let
                        ( text_, comments_ ) =
                            splitLine text
                    in
                    ( text_, Nothing, comments_ )
    in
    Item { item | value = ItemValue.fromString displayText, comments = comments, settings = settings }


withTextOnly : String -> Item -> Item
withTextOnly text (Item item) =
    Item { item | value = ItemValue.update item.value text }


childrenCount : Items -> Int
childrenCount (Items items) =
    if List.isEmpty items then
        0

    else
        List.length items + (items |> List.map (\(Item i) -> childrenCount <| unwrapChildren i.children) |> List.sum) + 1


commentPrefix : String
commentPrefix =
    "#"



-- private


isCommentLine : String -> Bool
isCommentLine text =
    text |> String.trim |> String.startsWith commentPrefix


filter : (Item -> Bool) -> Items -> Items
filter f (Items items) =
    Items (List.filter f items)


hasIndent : Int -> String -> Bool
hasIndent indent text =
    if indent == 0 then
        String.left 1 text /= " "

    else
        let
            lineinputPrefix : String
            lineinputPrefix =
                String.repeat indent inputPrefix
        in
        String.startsWith lineinputPrefix text
            && (String.slice (indent * indentSpace) (indent * indentSpace + 1) text /= " ")


hierarchyCount : Items -> List Int
hierarchyCount (Items items) =
    if List.isEmpty items then
        []

    else
        1 :: List.concatMap (\(Item i) -> hierarchyCount <| unwrapChildren i.children) items


leafCount : Items -> Int
leafCount (Items items) =
    if List.isEmpty items then
        1

    else
        items |> List.map (\(Item i) -> leafCount <| unwrapChildren i.children) |> List.sum


loadText_ : { indent : Int, input : String, lineNo : Int } -> ( List Hierarchy, Items )
loadText_ { indent, input, lineNo } =
    case parse indent input of
        ( [], _ ) ->
            ( [ indent ], empty )

        ( (h :: rest) as parsed, other ) ->
            -- TODO: load multi lines
            -- h が複数行の場合は複数行読み込む
            -- rest に | がない場合はすべての行を1つにまとめる
            let
                ( otherIndents, otherItems ) =
                    loadText_ { indent = indent, input = String.join "\n" other, lineNo = lineNo + List.length parsed }

                ( xsIndent, xsItems ) =
                    loadText_ { indent = indent + 1, input = String.join "\n" rest, lineNo = lineNo + 1 }
            in
            if isCommentLine h then
                ( indent :: xsIndent ++ otherIndents
                , filter (\(Item item) -> not <| ItemValue.isCooment item.value) otherItems
                )

            else
                ( indent :: xsIndent ++ otherIndents
                , cons
                    (new
                        |> withLineNo lineNo
                        |> withText h
                        |> withChildren (childrenFromItems xsItems)
                    )
                    (filter (\(Item item) -> not <| ItemValue.isCooment item.value) otherItems)
                )


mapWithRecursiveHelper : (Item -> Item) -> Item -> Item
mapWithRecursiveHelper f item =
    case getChildren item of
        Children (Items []) ->
            f item

        _ ->
            withChildren
                (getChildren item
                    |> unwrapChildren
                    |> unwrap
                    |> List.map (mapWithRecursiveHelper f)
                    |> Items
                    |> Children
                )
                (f item)


parse : Int -> String -> ( List String, List String )
parse indent text =
    let
        l : List String
        l =
            String.lines text
                |> List.filter
                    (\x ->
                        let
                            str : String
                            str =
                                x |> String.trim
                        in
                        not (String.isEmpty str)
                    )
    in
    case List.tail l of
        Just t ->
            case
                t
                    |> ListEx.findIndex (hasIndent indent)
            of
                Just xs ->
                    ListEx.splitAt (xs + 1) l

                Nothing ->
                    ( l, [] )

        Nothing ->
            ( [], [] )


splitLine : String -> ( String, Maybe String )
splitLine text =
    case String.split commentPrefix text of
        [ _ ] ->
            ( text, Nothing )

        [ text_, comments ] ->
            ( text_, Just comments )

        _ ->
            ( "", Nothing )


splitText : String -> ( String, List String )
splitText text =
    let
        tokens : List String
        tokens =
            String.split textSeparator text
    in
    if List.length tokens > 1 then
        ( textSeparator, tokens )

    else
        ( legacyTextSeparator, String.split legacyTextSeparator text )


resetOffset : Item -> Item
resetOffset (Item item) =
    (item.settings
        |> Maybe.map ItemSettings.resetOffset
        |> withSettings
    )
        (Item item)


textSeparator : String
textSeparator =
    ": |"


legacyTextSeparator : String
legacyTextSeparator =
    "|"
