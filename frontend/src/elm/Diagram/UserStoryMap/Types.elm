module Diagram.UserStoryMap.Types exposing
    ( CountPerTasks
    , Hierarchy
    , UserStoryMap
    , countPerReleaseLevel
    , countPerTasks
    , from
    , getHierarchy
    , getItems
    , size
    )

import Bool.Extra as BoolEx
import Constants
import Diagram.Types.CardSize as CardSize
import Diagram.Types.Settings as DiagramSettings
import Dict
import List.Extra exposing (scanl)
import State exposing (Step(..))
import Types.Item as Item exposing (Items)
import Types.Property as Property exposing (Property)
import Types.Size exposing (Size)


type alias CountPerTasks =
    List Int


type alias Hierarchy =
    Int


type UserStoryMap
    = UserStoryMap
        { items : Items
        , countPerReleaseLevel : CountPerStories
        , countPerTasks : CountPerTasks
        , hierarchy : Int
        , property : Property
        }


countPerReleaseLevel : UserStoryMap -> CountPerTasks
countPerReleaseLevel (UserStoryMap userStoryMap) =
    userStoryMap.countPerReleaseLevel


countPerTasks : UserStoryMap -> CountPerTasks
countPerTasks (UserStoryMap userStoryMap) =
    userStoryMap.countPerTasks


from : String -> Hierarchy -> Items -> UserStoryMap
from text hierarchy items =
    UserStoryMap
        { items = items
        , countPerReleaseLevel = countByStories text
        , countPerTasks = countByTasks items
        , hierarchy = hierarchy
        , property = Property.empty
        }


getHierarchy : UserStoryMap -> Int
getHierarchy (UserStoryMap userStoryMap) =
    userStoryMap.hierarchy


getItems : UserStoryMap -> Items
getItems (UserStoryMap userStoryMap) =
    userStoryMap.items


size : DiagramSettings.Settings -> UserStoryMap -> Size
size settings userStoryMap =
    ( Constants.leftMargin + (CardSize.toInt settings.size.width + Constants.itemMargin * 2) * (taskCount userStoryMap + 1)
    , (CardSize.toInt settings.size.height + Constants.itemMargin) * (storyCount userStoryMap + 2)
    )


countByStories : String -> List Int
countByStories text =
    let
        go :
            { a
                | currentCount : Int
                , currentIndent : Int
                , lines : List String
                , result : Dict.Dict Int Int
            }
            ->
                Step
                    { currentCount : Int
                    , currentIndent : Int
                    , lines : List String
                    , result : Dict.Dict Int Int
                    }
                    (Dict.Dict Int Int)
        go { currentCount, currentIndent, lines, result } =
            case lines of
                x :: [] ->
                    loop { currentCount = currentCount, currentIndent = currentIndent, head = x, result = result, tail = [] }

                x :: xs ->
                    loop { currentCount = currentCount, currentIndent = currentIndent, head = x, result = result, tail = xs }

                _ ->
                    Done <|
                        BoolEx.ifElse
                            (Dict.update currentIndent
                                (Maybe.map
                                    (\v ->
                                        if currentCount > v then
                                            currentCount

                                        else
                                            v
                                    )
                                )
                                result
                            )
                            (Dict.insert currentIndent currentCount result)
                            (Dict.member currentIndent result)

        loop :
            { a
                | currentCount : Int
                , currentIndent : Int
                , head : String
                , result : Dict.Dict Int Int
                , tail : List String
            }
            ->
                Step
                    { currentCount : Int
                    , currentIndent : Int
                    , lines : List String
                    , result : Dict.Dict Int Int
                    }
                    b
        loop { currentCount, currentIndent, head, result, tail } =
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
                                (Maybe.map (\v -> BoolEx.ifElse currentCount v (currentCount > v)))
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
    in
    1
        :: 1
        :: (State.tailRec go { currentCount = 1, currentIndent = 0, lines = String.lines text, result = Dict.empty }
                |> Dict.values
                |> List.drop 2
           )


countByTasks : Items -> CountPerTasks
countByTasks items =
    scanl (\it v -> v + Item.length (Item.unwrapChildren <| Item.getChildren it)) 0 (Item.unwrap items)


type alias CountPerStories =
    List Int


getTextIndent : String -> Int
getTextIndent text =
    (String.length text - (text |> String.trimLeft |> String.length)) // 4


storyCount : UserStoryMap -> Int
storyCount (UserStoryMap userStoryMap) =
    List.sum userStoryMap.countPerReleaseLevel


taskCount : UserStoryMap -> Int
taskCount (UserStoryMap userStoryMap) =
    List.maximum userStoryMap.countPerTasks
        |> Maybe.withDefault 1
