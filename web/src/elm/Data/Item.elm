module Data.Item exposing
    ( Children
    , Item
    , ItemType(..)
    , Items
    , childrenFromItems
    , cons
    , createText
    , empty
    , emptyChildren
    , filter
    , flatten
    , fromList
    , fromString
    , getAt
    , getBackgroundColor
    , getChildren
    , getChildrenCount
    , getFontSize
    , getForegroundColor
    , getHierarchyCount
    , getItemSettings
    , getItemType
    , getLeafCount
    , getLineNo
    , getText
    , head
    , indexedMap
    , isEmpty
    , isImage
    , isMarkdown
    , length
    , map
    , new
    , spiltText
    , splitAt
    , tail
    , unwrap
    , unwrapChildren
    , withChildren
    , withItemSettings
    , withItemType
    , withLineNo
    , withText
    )

import Constants exposing (indentSpace, inputPrefix)
import Data.Color as Color exposing (Color)
import Data.FontSize exposing (FontSize)
import Data.ItemSettings as ItemSettings exposing (ItemSettings)
import Data.Text as Text exposing (Text)
import Json.Decode as D
import List.Extra as ListEx
import Maybe


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
        , itemType : ItemType
        , itemSettings : Maybe ItemSettings
        , children : Children
        }


type ItemType
    = Activities
    | Tasks
    | Stories Int
    | Comments


new : Item
new =
    Item
        { lineNo = 0
        , text = Text.empty
        , itemType = Activities
        , itemSettings = Nothing
        , children = emptyChildren
        }


withLineNo : Int -> Item -> Item
withLineNo lineNo (Item item) =
    Item { item | lineNo = lineNo }


withText : String -> Item -> Item
withText text (Item item) =
    let
        ( displayText, settings ) =
            if isImage text then
                ( text, Nothing )

            else
                case String.split "|" text of
                    [ x, xs ] ->
                        case D.decodeString ItemSettings.decoder xs of
                            Ok s ->
                                ( x, Just s )

                            Err _ ->
                                ( x, Nothing )

                    x :: xs ->
                        let
                            maybeSettings =
                                ListEx.last xs
                                    |> Maybe.andThen
                                        (\lt ->
                                            case D.decodeString ItemSettings.decoder lt of
                                                Ok s ->
                                                    Just s

                                                Err _ ->
                                                    Nothing
                                        )

                            maybeText =
                                ListEx.init xs
                                    |> Maybe.map (\v -> String.join "|" v)
                        in
                        case ( maybeText, maybeSettings ) of
                            ( Just t, Just st ) ->
                                ( x ++ "|" ++ t, Just st )

                            ( Just t, Nothing ) ->
                                ( x ++ "|" ++ t, Nothing )

                            ( Nothing, _ ) ->
                                ( x, Nothing )

                    _ ->
                        case String.split "," text of
                            [ t, bg, fg ] ->
                                ( t
                                , ItemSettings.new
                                    |> ItemSettings.withBackgroundColor (Just (Color.fromString bg))
                                    |> ItemSettings.withForegroundColor (Just (Color.fromString fg))
                                    |> Just
                                )

                            [ t, bg ] ->
                                ( t
                                , ItemSettings.new
                                    |> ItemSettings.withBackgroundColor (Just (Color.fromString bg))
                                    |> Just
                                )

                            _ ->
                                ( text, Nothing )
    in
    Item
        { item
            | text = Text.fromString displayText
            , itemSettings = settings
        }


withItemSettings : Maybe ItemSettings -> Item -> Item
withItemSettings itemSettings (Item item) =
    Item { item | itemSettings = itemSettings }


withItemType : ItemType -> Item -> Item
withItemType itemType (Item item) =
    Item { item | itemType = itemType }


withChildren : Children -> Item -> Item
withChildren children (Item item) =
    Item { item | children = children }


getChildren : Item -> Children
getChildren (Item i) =
    i.children


getText : Item -> String
getText (Item i) =
    Text.toString i.text


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


getLineNo : Item -> Int
getLineNo (Item i) =
    i.lineNo


isImage : String -> Bool
isImage text =
    String.trim text |> String.toLower |> String.startsWith "data:image/"


isMarkdown : String -> Bool
isMarkdown text =
    String.trim text |> String.toLower |> String.startsWith "md:"


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
isEmpty items =
    length items == 0


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


childrenCount : Items -> Int
childrenCount (Items items) =
    if List.isEmpty items then
        0

    else
        List.length items + (items |> List.map (\(Item i) -> childrenCount <| unwrapChildren i.children) |> List.sum) + 1


getHierarchyCount : Item -> Int
getHierarchyCount (Item item) =
    unwrapChildren item.children
        |> hierarchyCount
        |> List.length


hierarchyCount : Items -> List Int
hierarchyCount (Items items) =
    if List.isEmpty items then
        []

    else
        1 :: List.concatMap (\(Item i) -> hierarchyCount <| unwrapChildren i.children) items


getLeafCount : Item -> Int
getLeafCount (Item item) =
    leafCount <| unwrapChildren item.children


leafCount : Items -> Int
leafCount (Items items) =
    if List.isEmpty items then
        1

    else
        items |> List.map (\(Item i) -> leafCount <| unwrapChildren i.children) |> List.sum


createText : String -> Maybe ItemSettings -> String
createText text settings =
    case settings of
        Just s ->
            text ++ "|" ++ ItemSettings.toString s

        Nothing ->
            text


spiltText : String -> ( String, ItemSettings )
spiltText text =
    let
        tokens =
            String.split "|" text
    in
    case tokens of
        [ t ] ->
            ( t, ItemSettings.new )

        [ t, settingsString ] ->
            case D.decodeString ItemSettings.decoder settingsString of
                Ok settings ->
                    ( t, settings )

                Err _ ->
                    ( t, ItemSettings.new )

        _ ->
            ( text, ItemSettings.new )


flatten : Items -> Items
flatten (Items items) =
    case items of
        [] ->
            Items items

        _ ->
            Items (items ++ List.concatMap (\(Item item) -> unwrap <| flatten <| unwrapChildren item.children) items)


hasIndent : Int -> String -> Bool
hasIndent indent text =
    let
        lineinputPrefix =
            String.repeat indent inputPrefix
    in
    if indent == 0 then
        String.left 1 text /= " "

    else
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
                Stories (indent - 1)


parse : Int -> String -> ( List String, List String )
parse indent text =
    let
        line =
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
    case List.tail line of
        Just t ->
            case
                t
                    |> ListEx.findIndex (hasIndent indent)
            of
                Just xs ->
                    ListEx.splitAt (xs + 1) line

                Nothing ->
                    ( line, [] )

        Nothing ->
            ( [], [] )


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
