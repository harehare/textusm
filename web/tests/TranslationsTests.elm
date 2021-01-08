module TranslationsTests exposing (suite)

import Expect
import Test exposing (Test, describe, test)
import Translations


suite : Test
suite =
    describe "Translations test"
        [ describe "fromString test"
            [ test "ja" <|
                \() ->
                    Expect.equal (Translations.fromString "ja") Translations.Ja
            , test "en" <|
                \() ->
                    Expect.equal (Translations.fromString "en") Translations.En
            , test "de" <|
                \() ->
                    Expect.equal (Translations.fromString "de") Translations.En
            ]
        ]
