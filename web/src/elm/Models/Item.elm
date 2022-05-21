module Models.Item exposing
    ( Children
    , Hierarchy
    , Item
    , ItemType(..)
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
    , getItemSettings
    , getItemType
    , getLeafCount
    , getLineNo
    , getOffset
    , getOffsetSize
    , getPosition
    , getSize
    , getText
    , getTrimmedText
    , head
    , indexedMap
    , isCanvas
    , isEmpty
    , isHighlight
    , isHorizontalLine
    , isImage
    , isMarkdown
    , isText
    , isVerticalLine
    , length
    , map
    , mapWithRecursive
    , new
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
    , withItemSettings
    , withItemType
    , withLineNo
    , withOffset
    , withOffsetSize
    , withText
    , withTextOnly
    )

import Constants exposing (indentSpace, inputPrefix)
import Html.Attributes exposing (property)
import Json.Decode as D
import List.Extra as ListEx
import Maybe
import Models.Color exposing (Color)
import Models.FontSize as FontSize exposing (FontSize)
import Models.ItemSettings as ItemSettings exposing (ItemSettings)
import Models.Position exposing (Position)
import Models.Property as Property exposing (Property)
import Models.Size as Size exposing (Size)
import Models.Text as Text exposing (Text)
import Simple.Fuzzy as Fuzzy


type Children
    = Children Items


type alias Hierarchy =
    Int


type Item
    = Item
        { lineNo : Int
        , text : Text
        , comments : Maybe String
        , itemType : ItemType
        , itemSettings : Maybe ItemSettings
        , children : Children
        , highlight : Bool
        }


type ItemType
    = Activities
    | Tasks
    | Stories
    | Comments


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

    else
        let
            loadText : Int -> Int -> String -> ( List Hierarchy, Items )
            loadText lineNo indent input =
                case parse indent input of
                    ( [], _ ) ->
                        ( [ indent ], empty )

                    ( x :: xs, other ) ->
                        let
                            itemType : ItemType
                            itemType =
                                createItemType x indent

                            ( otherIndents, otherItems ) =
                                loadText (lineNo + List.length (x :: xs)) indent (String.join "\n" other)

                            ( xsIndent, xsItems ) =
                                loadText (lineNo + 1) (indent + 1) (String.join "\n" xs)
                        in
                        case itemType of
                            Comments ->
                                ( indent :: xsIndent ++ otherIndents
                                , filter (\item -> getItemType item /= Comments) otherItems
                                )

                            _ ->
                                ( indent :: xsIndent ++ otherIndents
                                , cons
                                    (new
                                        |> withLineNo lineNo
                                        |> withText x
                                        |> withItemType itemType
                                        |> withChildren (childrenFromItems xsItems)
                                    )
                                    (filter (\item -> getItemType item /= Comments) otherItems)
                                )
        in
        if String.isEmpty text then
            ( 0, empty )

        else
            let
                ( indentList, loadedItems ) =
                    loadText 0 0 text
            in
            ( indentList
                |> List.maximum
                |> Maybe.map (\x -> x - 1)
                |> Maybe.withDefault 0
            , loadedItems
            )


getAt : Int -> Items -> Maybe Item
getAt i (Items items) =
    ListEx.getAt i items


getBackgroundColor : Item -> Maybe Color
getBackgroundColor item =
    item
        |> getItemSettings
        |> Maybe.withDefault ItemSettings.new
        |> ItemSettings.getBackgroundColor


getChildren : Item -> Children
getChildren (Item i) =
    i.children


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
        |> getItemSettings
        |> Maybe.map ItemSettings.getFontSize


getFontSizeWithProperty : Item -> Property -> FontSize
getFontSizeWithProperty item property =
    case ( Property.getFontSize property, item |> getItemSettings |> Maybe.map ItemSettings.getFontSize ) of
        ( _, Just f ) ->
            f

        ( Just f, _ ) ->
            f

        _ ->
            FontSize.default


getForegroundColor : Item -> Maybe Color
getForegroundColor item =
    item
        |> getItemSettings
        |> Maybe.withDefault ItemSettings.new
        |> ItemSettings.getForegroundColor


getHierarchyCount : Item -> Int
getHierarchyCount (Item item) =
    unwrapChildren item.children
        |> hierarchyCount
        |> List.length


getItemSettings : Item -> Maybe ItemSettings
getItemSettings (Item i) =
    i.itemSettings


getItemType : Item -> ItemType
getItemType (Item i) =
    i.itemType


getLeafCount : Item -> Int
getLeafCount (Item item) =
    leafCount <| unwrapChildren item.children


getLineNo : Item -> Int
getLineNo (Item i) =
    i.lineNo


getOffset : Item -> Position
getOffset item =
    item
        |> getItemSettings
        |> Maybe.withDefault ItemSettings.new
        |> ItemSettings.getOffset


getOffsetSize : Item -> Size
getOffsetSize item =
    item
        |> getItemSettings
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
    Text.toString i.text


getTrimmedText : Item -> String
getTrimmedText item =
    getText item |> String.trim


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


isHorizontalLine : Item -> Bool
isHorizontalLine item =
    getText item |> String.trim |> String.toLower |> String.startsWith "---"


isImage : Item -> Bool
isImage item =
    getText item |> String.trim |> String.toLower |> String.startsWith "data:image/"



-- Items


isMarkdown : Item -> Bool
isMarkdown item =
    getText item |> String.trim |> String.toLower |> String.startsWith "md:"


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
        , text = Text.empty
        , comments = Nothing
        , itemType = Activities
        , itemSettings = Nothing
        , children = emptyChildren
        , highlight = False
        }


search : Items -> String -> Items
search items query =
    mapWithRecursive (\item -> withHighlight (Fuzzy.match query (getText item)) item) items


searchClear : Items -> Items
searchClear items =
    mapWithRecursive (withHighlight False) items


split : String -> ( String, ItemSettings, Maybe String )
split text =
    let
        tokens : List String
        tokens =
            String.split textSeparator text
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
            case D.decodeString ItemSettings.decoder settingsString of
                Ok settings ->
                    ( t, settings, comment )

                Err _ ->
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
    case getItemSettings item of
        Just s ->
            getText item ++ comment ++ textSeparator ++ ItemSettings.toString s

        Nothing ->
            getText item ++ comment


unwrap : Items -> List Item
unwrap (Items items) =
    items


unwrapChildren : Children -> Items
unwrapChildren (Children (Items items)) =
    Items (items |> List.filter (\(Item i) -> i.itemType /= Comments))


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


withItemSettings : Maybe ItemSettings -> Item -> Item
withItemSettings itemSettings (Item item) =
    Item { item | itemSettings = itemSettings }


withItemType : ItemType -> Item -> Item
withItemType itemType (Item item) =
    Item { item | itemType = itemType }


withLineNo : Int -> Item -> Item
withLineNo lineNo (Item item) =
    Item { item | lineNo = lineNo }


withOffset : Position -> Item -> Item
withOffset newPosition item =
    withItemSettings (Just (getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.withOffset newPosition)) item


withOffsetSize : Size -> Item -> Item
withOffsetSize newSize item =
    withItemSettings (Just (getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.withOffsetSize (Just newSize))) item


withText : String -> Item -> Item
withText text (Item item) =
    let
        ( displayText, settings, comments ) =
            if isImage <| withTextOnly text (Item item) then
                ( text, Nothing, Nothing )

            else
                let
                    tokens : List (List Char)
                    tokens =
                        String.split textSeparator text
                            |> List.map String.toList

                    tuple : ( String, Maybe String )
                    tuple =
                        case tokens of
                            [ x, '{' :: xs ] ->
                                ( String.fromList x, Just <| String.fromList <| '{' :: xs )

                            _ :: _ :: _ ->
                                ( List.take (List.length tokens - 1) tokens
                                    |> List.map String.fromList
                                    |> String.join textSeparator
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
                        case D.decodeString ItemSettings.decoder s of
                            Ok settings_ ->
                                ( text_, Just settings_, comments_ )

                            Err _ ->
                                ( text_ ++ textSeparator ++ s, Nothing, comments_ )

                    ( _, Nothing ) ->
                        let
                            ( text_, comments_ ) =
                                splitLine text
                        in
                        ( text_, Nothing, comments_ )
    in
    Item { item | text = Text.fromString displayText, comments = comments, itemSettings = settings }


withTextOnly : String -> Item -> Item
withTextOnly text (Item item) =
    Item { item | text = Text.fromString text }


childrenCount : Items -> Int
childrenCount (Items items) =
    if List.isEmpty items then
        0

    else
        List.length items + (items |> List.map (\(Item i) -> childrenCount <| unwrapChildren i.children) |> List.sum) + 1



-- private


commentPrefix : String
commentPrefix =
    "#"


createItemType : String -> Int -> ItemType
createItemType text indent =
    if text |> String.trim |> String.startsWith commentPrefix then
        Comments

    else
        case indent of
            0 ->
                Activities

            1 ->
                Tasks

            _ ->
                Stories


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


textSeparator : String
textSeparator =
    "|"
