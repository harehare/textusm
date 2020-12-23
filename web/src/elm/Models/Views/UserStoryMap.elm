module Models.Views.UserStoryMap exposing (UserStoryMap, countPerStories, countPerTasks, from, getHierarchy, getItems, getReleaseLevel, storyCount, taskCount)

import Data.Item as Item exposing (ItemType(..), Items)
import Dict exposing (Dict)
import List.Extra exposing (scanl, unique)


type alias Hierarchy =
    Int


type alias CountPerStories =
    List Int


type alias CountPerTasks =
    List Int


type alias ReleaseLevel =
    Dict String String


type UserStoryMap
    = UserStoryMap
        { items : Items
        , hierarchy : Hierarchy
        , countPerStories : CountPerStories
        , countPerTasks : CountPerTasks
        , releaseLevel : ReleaseLevel
        }


from : Hierarchy -> String -> Items -> UserStoryMap
from hierarchy text items =
    UserStoryMap
        { items = items
        , hierarchy = hierarchy
        , countPerTasks = countByTasks items
        , countPerStories = countByStories hierarchy items
        , releaseLevel = parseComment text
        }


getReleaseLevel : UserStoryMap -> String -> String -> String
getReleaseLevel (UserStoryMap userStoryMap) key default =
    Dict.get key userStoryMap.releaseLevel |> Maybe.withDefault default


getItems : UserStoryMap -> Items
getItems (UserStoryMap userStoryMap) =
    userStoryMap.items


getHierarchy : UserStoryMap -> Hierarchy
getHierarchy (UserStoryMap userStoryMap) =
    userStoryMap.hierarchy


countPerTasks : UserStoryMap -> CountPerTasks
countPerTasks (UserStoryMap userStoryMap) =
    userStoryMap.countPerTasks


countPerStories : UserStoryMap -> CountPerTasks
countPerStories (UserStoryMap userStoryMap) =
    userStoryMap.countPerStories


taskCount : UserStoryMap -> Int
taskCount (UserStoryMap userStoryMap) =
    List.maximum userStoryMap.countPerTasks |> Maybe.withDefault 1


storyCount : UserStoryMap -> Int
storyCount (UserStoryMap userStoryMap) =
    List.sum userStoryMap.countPerStories


parseComment : String -> ReleaseLevel
parseComment text =
    String.lines text
        |> List.filter (\t -> String.trim t |> String.startsWith "#")
        |> List.map
            (\line ->
                case String.split ":" line of
                    [ name, value ] ->
                        ( String.replace "#" "" name |> String.trim |> String.toLower, String.trim value )

                    _ ->
                        ( "", "" )
            )
        |> Dict.fromList


transpose : List (List comparable) -> List (List comparable)
transpose ll =
    case ll of
        [] ->
            []

        [] :: xss ->
            transpose xss

        (x :: xs) :: xss ->
            let
                heads =
                    List.filterMap List.head xss
                        |> unique

                tails =
                    List.filterMap List.tail xss
                        |> unique
            in
            (x :: heads) :: transpose (xs :: tails)


countByTasks : Items -> CountPerTasks
countByTasks items =
    scanl (\it v -> v + Item.length (Item.unwrapChildren <| Item.getChildren it)) 0 (Item.unwrap items)


countByStories : Int -> Items -> CountPerStories
countByStories hierarchy items =
    let
        countUp : Items -> List (List Int)
        countUp countItems =
            [ countItems
                |> Item.filter (\x -> Item.getItemType x /= Tasks && Item.getItemType x /= Activities)
                |> Item.length
            ]
                :: (countItems
                        |> Item.map
                            (\it ->
                                let
                                    results =
                                        countUp (Item.unwrapChildren <| Item.getChildren it)
                                            |> transpose
                                in
                                if List.length results > hierarchy then
                                    List.map
                                        (\it2 ->
                                            List.maximum it2 |> Maybe.withDefault 0
                                        )
                                        results

                                else
                                    results
                                        |> List.concat
                                        |> List.filter (\x -> x /= 0)
                            )
                   )
    in
    1
        :: 1
        :: (countUp items
                |> transpose
                |> List.map
                    (\it ->
                        List.maximum it |> Maybe.withDefault 0
                    )
           )
