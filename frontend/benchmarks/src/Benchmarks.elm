module Benchmarks exposing (main)

import Array
import Benchmark exposing (Benchmark, benchmark, describe)
import Benchmark.Runner exposing (BenchmarkProgram, program)
import Parser
import Types.Item.Parser as ItemParser
import Types.Property.Parser as PropertyParser
import Types.Property as Property


property : Benchmark
property =
    describe "property"
        [
        benchmark "parse" <| \_ -> """
            # background-color: #FEFEFE"
            # card_height: 60
            # user_activities: user_activities
            # zoom_control: true
            """ |> Property.fromString
        ]


item : Benchmark
item =
    describe "item"
        [ benchmark "parse" <| \_ -> ItemParser.parse "text # comment : |{\"bg\": \"#FEFEFE\"}"
        ]


main : BenchmarkProgram
main =
    program <|
        Benchmark.describe "all"
            [ property, item ]
