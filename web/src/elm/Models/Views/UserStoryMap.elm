module Models.Views.UserStoryMap exposing (UserStoryMap, countPerStories, countPerTasks, from, getHierarchy, getItems, getReleaseLevel, storyCount, taskCount)

import Data.Item as Item exposing (ItemType(..), Items)
import Dict exposing (Dict)
import List.Extra exposing (scanl)
import State as State exposing (Step(..))


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
        , countPerStories = countByStories text
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


countByTasks : Items -> CountPerTasks
countByTasks items =
    scanl (\it v -> v + Item.length (Item.unwrapChildren <| Item.getChildren it)) 0 (Item.unwrap items)


getTextIndent : String -> Int
getTextIndent text =
    (String.length text - (text |> String.trimLeft |> String.length)) // 4


countByStories : String -> List Int
countByStories text =
    let
        go { currentCount, currentIndent, lines, result } =
            case lines of
                x :: xs ->
                    let
                        indent =
                            getTextIndent x

                        ( indentCount, nextResult ) =
                            if indent == currentIndent then
                                ( currentCount + 1, result )

                            else
                                ( 1
                                , if Dict.member currentIndent result then
                                    Dict.update currentIndent
                                        (Maybe.map
                                            (\v ->
                                                if currentCount > v then
                                                    currentCount

                                                else
                                                    v
                                            )
                                        )
                                        result

                                  else
                                    Dict.insert currentIndent currentCount result
                                )
                    in
                    Loop
                        { currentCount = indentCount
                        , currentIndent = indent
                        , lines = xs
                        , result = nextResult
                        }

                _ ->
                    Done result
    in
    1
        :: 1
        :: (State.tailRec go { currentCount = 1, currentIndent = 0, lines = String.lines text, result = Dict.empty }
                |> Dict.values
                |> List.drop 2
           )
