module Models.Item exposing
    ( Children
    , Hierarchy
    , Item
    , ItemType(..)
    , Items
    , childrenFromItems
    , cons
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
    , head
    , indexedMap
    , isEmpty
    , isHorizontalLine
    , isImage
    , isMarkdown
    , isVerticalLine
    , length
    , map
    , new
    , split
    , splitAt
    , tail
    , toLineString
    , unwrap
    , unwrapChildren
    , withChildren
    , withComments
    , withItemSettings
    , withItemType
    , withLineNo
    , withOffset
    , withOffsetSize
    , withText
    , withTextOnly
    )

import Constants exposing (indentSpace, inputPrefix)
import Json.Decode as D
import List.Extra as ListEx
import Maybe
import Models.Color exposing (Color)
import Models.FontSize exposing (FontSize)
import Models.ItemSettings as ItemSettings exposing (ItemSettings)
import Models.Position exposing (Position)
import Models.Size as Size exposing (Size)
import Models.Text as Text exposing (Text)


type alias Hierarchy =
    Int


type Children
    = Children Items


type Items
    = Items (List Item)


type Item
    = Item
        { lineNo : Int
        , text : Text
        , comments : Maybe String
        , itemType : ItemType
        , itemSettings : Maybe ItemSettings
        , children : Children
        }


type ItemType
    = Activities
    | Tasks
    | Stories
    | Comments


textSeparator : String
textSeparator =
    "|"


new : Item
new =
    Item
        { lineNo = 0
        , text = Text.empty
        , comments = Nothing
        , itemType = Activities
        , itemSettings = Nothing
        , children = emptyChildren
        }


withLineNo : Int -> Item -> Item
withLineNo lineNo (Item item) =
    Item { item | lineNo = lineNo }


withTextOnly : String -> Item -> Item
withTextOnly text (Item item) =
    Item { item | text = Text.fromString text }


withText : String -> Item -> Item
withText text (Item item) =
    let
        ( displayText, settings, comments ) =
            if isImage <| withTextOnly text (Item item) then
                ( text, Nothing, Nothing )

            else
                let
                    tokens =
                        String.split textSeparator text
                            |> List.map String.toList

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
                    ( _, Nothing ) ->
                        let
                            ( text_, comments_ ) =
                                splitLine text
                        in
                        ( text_, Nothing, comments_ )

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
    in
    Item { item | text = Text.fromString displayText, itemSettings = settings, comments = comments }


withItemSettings : Maybe ItemSettings -> Item -> Item
withItemSettings itemSettings (Item item) =
    Item { item | itemSettings = itemSettings }


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


withItemType : ItemType -> Item -> Item
withItemType itemType (Item item) =
    Item { item | itemType = itemType }


withChildren : Children -> Item -> Item
withChildren children (Item item) =
    Item { item | children = children }


withOffset : Position -> Item -> Item
withOffset newPosition item =
    withItemSettings (Just (getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.withOffset newPosition)) item


withOffsetSize : Size -> Item -> Item
withOffsetSize newSize item =
    withItemSettings (Just (getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.withOffsetSize (Just newSize))) item


getChildren : Item -> Children
getChildren (Item i) =
    i.children


getChildrenItems : Item -> Items
getChildrenItems (Item i) =
    i.children |> unwrapChildren


getText : Item -> String
getText (Item i) =
    Text.toString i.text


getComments : Item -> Maybe String
getComments (Item i) =
    Maybe.map (\c -> "#" ++ c) i.comments


getItemType : Item -> ItemType
getItemType (Item i) =
    i.itemType


getItemSettings : Item -> Maybe ItemSettings
getItemSettings (Item i) =
    i.itemSettings


getForegroundColor : Item -> Maybe Color
getForegroundColor item =
    item
        |> getItemSettings
        |> Maybe.withDefault ItemSettings.new
        |> ItemSettings.getForegroundColor


getBackgroundColor : Item -> Maybe Color
getBackgroundColor item =
    item
        |> getItemSettings
        |> Maybe.withDefault ItemSettings.new
        |> ItemSettings.getBackgroundColor


getFontSize : Item -> FontSize
getFontSize item =
    item
        |> getItemSettings
        |> Maybe.withDefault ItemSettings.new
        |> ItemSettings.getFontSize


getOffset : Item -> Position
getOffset item =
    item
        |> getItemSettings
        |> Maybe.withDefault ItemSettings.new
        |> ItemSettings.getOffset


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


getOffsetSize : Item -> Size
getOffsetSize item =
    item
        |> getItemSettings
        |> Maybe.withDefault ItemSettings.new
        |> ItemSettings.getOffsetSize
        |> Maybe.withDefault Size.zero


getLineNo : Item -> Int
getLineNo (Item i) =
    i.lineNo


isImage : Item -> Bool
isImage item =
    getText item |> String.trim |> String.toLower |> String.startsWith "data:image/"


isMarkdown : Item -> Bool
isMarkdown item =
    getText item |> String.trim |> String.toLower |> String.startsWith "md:"


isHorizontalLine : Item -> Bool
isHorizontalLine item =
    getText item |> String.trim |> String.toLower |> String.startsWith "---"


isVerticalLine : Item -> Bool
isVerticalLine item =
    getText item |> String.trim |> String.toLower |> String.startsWith "/"


getAt : Int -> Items -> Maybe Item
getAt i (Items items) =
    ListEx.getAt i items


head : Items -> Maybe Item
head (Items items) =
    List.head items


tail : Items -> Maybe Items
tail (Items items) =
    List.tail items
        |> Maybe.map (\i -> Items i)


map : (Item -> a) -> Items -> List a
map f (Items items) =
    List.map f items


filter : (Item -> Bool) -> Items -> Items
filter f (Items items) =
    Items (List.filter f items)


empty : Items
empty =
    Items []


cons : Item -> Items -> Items
cons item (Items items) =
    Items (item :: items)


indexedMap : (Int -> Item -> b) -> Items -> List b
indexedMap f (Items items) =
    List.indexedMap f items


length : Items -> Int
length (Items items) =
    List.length items


isEmpty : Items -> Bool
isEmpty (Items items) =
    List.isEmpty items


unwrap : Items -> List Item
unwrap (Items items) =
    items


splitAt : Int -> Items -> ( Items, Items )
splitAt i (Items items) =
    let
        ( left, right ) =
            ListEx.splitAt i items
    in
    ( Items left, Items right )


childrenFromItems : Items -> Children
childrenFromItems (Items items) =
    Children (Items items)


fromList : List Item -> Items
fromList items =
    Items items


emptyChildren : Children
emptyChildren =
    Children empty


unwrapChildren : Children -> Items
unwrapChildren (Children (Items items)) =
    Items (items |> List.filter (\(Item i) -> i.itemType /= Comments))


getChildrenCount : Item -> Int
getChildrenCount (Item item) =
    childrenCount <| unwrapChildren item.children


getHierarchyCount : Item -> Int
getHierarchyCount (Item item) =
    unwrapChildren item.children
        |> hierarchyCount
        |> List.length


getLeafCount : Item -> Int
getLeafCount (Item item) =
    leafCount <| unwrapChildren item.children


toLineString : Item -> String
toLineString item =
    let
        comment =
            Maybe.withDefault "" (getComments item)
    in
    case getItemSettings item of
        Just s ->
            getText item ++ comment ++ textSeparator ++ ItemSettings.toString s

        Nothing ->
            getText item ++ comment


split : String -> ( String, ItemSettings, Maybe String )
split text =
    let
        tokens =
            String.split textSeparator text
    in
    case tokens of
        [ text_ ] ->
            let
                ( text__, comment ) =
                    splitLine text_
            in
            ( text__, ItemSettings.new, comment )

        [ text_, settingsString ] ->
            let
                ( text__, comment ) =
                    splitLine text_
            in
            case D.decodeString ItemSettings.decoder settingsString of
                Ok settings ->
                    ( text__, settings, comment )

                Err _ ->
                    ( text__, ItemSettings.new, comment )

        _ ->
            ( text, ItemSettings.new, Nothing )


flatten : Items -> Items
flatten (Items items) =
    case items of
        [] ->
            Items items

        _ ->
            Items (items ++ List.concatMap (\(Item item) -> unwrap <| flatten <| unwrapChildren item.children) items)


fromString : String -> ( Hierarchy, Items )
fromString text =
    if text == "" then
        ( 0, empty )

    else
        let
            loadText : Int -> Int -> String -> ( List Hierarchy, Items )
            loadText lineNo indent input =
                case parse indent input of
                    ( x :: xs, other ) ->
                        let
                            ( xsIndent, xsItems ) =
                                loadText (lineNo + 1) (indent + 1) (String.join "\n" xs)

                            ( otherIndents, otherItems ) =
                                loadText (lineNo + List.length (x :: xs)) indent (String.join "\n" other)

                            itemType =
                                createItemType x indent
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

                    ( [], _ ) ->
                        ( [ indent ], empty )
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



-- private


parse : Int -> String -> ( List String, List String )
parse indent text =
    let
        l =
            String.lines text
                |> List.filter
                    (\x ->
                        let
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
    case String.split "#" text of
        [ _ ] ->
            ( text, Nothing )

        [ text_, comments ] ->
            ( text_, Just comments )

        _ ->
            ( "", Nothing )


childrenCount : Items -> Int
childrenCount (Items items) =
    if List.isEmpty items then
        0

    else
        List.length items + (items |> List.map (\(Item i) -> childrenCount <| unwrapChildren i.children) |> List.sum) + 1


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


hasIndent : Int -> String -> Bool
hasIndent indent text =
    if indent == 0 then
        String.left 1 text /= " "

    else
        let
            lineinputPrefix =
                String.repeat indent inputPrefix
        in
        String.startsWith lineinputPrefix text
            && (String.slice (indent * indentSpace) (indent * indentSpace + 1) text /= " ")


createItemType : String -> Int -> ItemType
createItemType text indent =
    if text |> String.trim |> String.startsWith "#" then
        Comments

    else
        case indent of
            0 ->
                Activities

            1 ->
                Tasks

            _ ->
                Stories
