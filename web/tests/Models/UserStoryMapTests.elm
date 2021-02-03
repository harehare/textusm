module Models.UserStoryMapTests exposing (suite)

import Data.Item as Item
import Expect
import Models.Views.UserStoryMap as UserStoryMap
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "UserStoryMap test"
        [ describe "countByStories"
            [ test "Activitites and tasks counted shoud be always 1" <|
                \() ->
                    Expect.equal (UserStoryMap.from "test\ntest\n    test\n    test" Item.empty |> UserStoryMap.countPerReleaseLevel) [ 1, 1 ]
            , test "User stories counted shoud be maximum number within a release level." <|
                \() ->
                    Expect.equal
                        (UserStoryMap.from
                            "test\n    test\n    test\n        test\n        test\n            test\n            test\n            test\n            test\n            test\n            test\ntest\n    test\n    test\n        test\n        test\n        test\n        test"
                            Item.empty
                            |> UserStoryMap.countPerReleaseLevel
                        )
                        [ 1, 1, 4, 6 ]
            ]
        ]
