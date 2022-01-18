module Models.Diagram.UserStoryMap exposing
    ( CountPerTasks
    , Hierarchy
    , UserStoryMap
    , countPerReleaseLevel
    , countPerTasks
    , from
    , getHierarchy
    , getItems
    , storyCount
    , taskCount
    )

import Dict
import List.Extra exposing (scanl)
import Models.Item as Item exposing (Items)
import Models.Property as Property exposing (Property)
import State exposing (Step(..))


type alias CountPerStories =
    List Int


type alias Hierarchy =
    Int


type alias CountPerTasks =
    List Int


type UserStoryMap
    = UserStoryMap
        { items : Items
        , countPerReleaseLevel : CountPerStories
        , countPerTasks : CountPerTasks
        , hierarchy : Int
        , property : Property
        }


from : String -> Hierarchy -> Items -> UserStoryMap
from text hierarchy items =
    UserStoryMap
        { items = items
        , countPerTasks = countByTasks items
        , countPerReleaseLevel = countByStories text
        , hierarchy = hierarchy
        , property = Property.empty
        }


getItems : UserStoryMap -> Items
getItems (UserStoryMap userStoryMap) =
    userStoryMap.items


getHierarchy : UserStoryMap -> Int
getHierarchy (UserStoryMap userStoryMap) =
    userStoryMap.hierarchy


countPerTasks : UserStoryMap -> CountPerTasks
countPerTasks (UserStoryMap userStoryMap) =
    userStoryMap.countPerTasks


countPerReleaseLevel : UserStoryMap -> CountPerTasks
countPerReleaseLevel (UserStoryMap userStoryMap) =
    userStoryMap.countPerReleaseLevel


taskCount : UserStoryMap -> Int
taskCount (UserStoryMap userStoryMap) =
    List.maximum userStoryMap.countPerTasks
        |> Maybe.withDefault 1


storyCount : UserStoryMap -> Int
storyCount (UserStoryMap userStoryMap) =
    List.sum userStoryMap.countPerReleaseLevel


countByTasks : Items -> CountPerTasks
countByTasks items =
    scanl (\it v -> v + Item.length (Item.unwrapChildren <| Item.getChildren it)) 0 (Item.unwrap items)


getTextIndent : String -> Int
getTextIndent text =
    (String.length text - (text |> String.trimLeft |> String.length)) // 4


countByStories : String -> List Int
countByStories text =
    let
        loop { currentCount, currentIndent, result, head, tail } =
            let
                indent : Int
                indent =
                    getTextIndent head

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
                , lines = tail
                , result = nextResult
                }

        go { currentCount, currentIndent, lines, result } =
            case lines of
                x :: [] ->
                    loop { currentCount = currentCount, currentIndent = currentIndent, result = result, head = x, tail = [] }

                x :: xs ->
                    loop { currentCount = currentCount, currentIndent = currentIndent, result = result, head = x, tail = xs }

                _ ->
                    if Dict.member currentIndent result then
                        Done <|
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
                        Done <| Dict.insert currentIndent currentCount result
    in
    1
        :: 1
        :: (State.tailRec go { currentCount = 1, currentIndent = 0, lines = String.lines text, result = Dict.empty }
                |> Dict.values
                |> List.drop 2
           )
