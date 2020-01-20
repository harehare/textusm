-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module TextUSM.Enum.Diagram exposing (..)

import Json.Decode as Decode exposing (Decoder)


{-|

  - UserStoryMap -
  - OpportunityCanvas -
  - BusinessModelCanvas -
  - Fourls -
  - StartStopContinue -
  - Kpt -
  - UserPersona -
  - Markdown -
  - MindMap -
  - EmpathyMap -
  - CustomerJourneyMap -
  - SiteMap -
  - GanttChart -

-}
type Diagram
    = UserStoryMap
    | OpportunityCanvas
    | BusinessModelCanvas
    | Fourls
    | StartStopContinue
    | Kpt
    | UserPersona
    | Markdown
    | MindMap
    | EmpathyMap
    | CustomerJourneyMap
    | SiteMap
    | GanttChart


list : List Diagram
list =
    [ UserStoryMap, OpportunityCanvas, BusinessModelCanvas, Fourls, StartStopContinue, Kpt, UserPersona, Markdown, MindMap, EmpathyMap, CustomerJourneyMap, SiteMap, GanttChart ]


decoder : Decoder Diagram
decoder =
    Decode.string
        |> Decode.andThen
            (\string ->
                case string of
                    "USER_STORY_MAP" ->
                        Decode.succeed UserStoryMap

                    "OPPORTUNITY_CANVAS" ->
                        Decode.succeed OpportunityCanvas

                    "BUSINESS_MODEL_CANVAS" ->
                        Decode.succeed BusinessModelCanvas

                    "FOURLS" ->
                        Decode.succeed Fourls

                    "START_STOP_CONTINUE" ->
                        Decode.succeed StartStopContinue

                    "KPT" ->
                        Decode.succeed Kpt

                    "USER_PERSONA" ->
                        Decode.succeed UserPersona

                    "MARKDOWN" ->
                        Decode.succeed Markdown

                    "MIND_MAP" ->
                        Decode.succeed MindMap

                    "EMPATHY_MAP" ->
                        Decode.succeed EmpathyMap

                    "CUSTOMER_JOURNEY_MAP" ->
                        Decode.succeed CustomerJourneyMap

                    "SITE_MAP" ->
                        Decode.succeed SiteMap

                    "GANTT_CHART" ->
                        Decode.succeed GanttChart

                    _ ->
                        Decode.fail ("Invalid Diagram type, " ++ string ++ " try re-running the @dillonkearns/elm-graphql CLI ")
            )


{-| Convert from the union type representating the Enum to a string that the GraphQL server will recognize.
-}
toString : Diagram -> String
toString enum =
    case enum of
        UserStoryMap ->
            "USER_STORY_MAP"

        OpportunityCanvas ->
            "OPPORTUNITY_CANVAS"

        BusinessModelCanvas ->
            "BUSINESS_MODEL_CANVAS"

        Fourls ->
            "FOURLS"

        StartStopContinue ->
            "START_STOP_CONTINUE"

        Kpt ->
            "KPT"

        UserPersona ->
            "USER_PERSONA"

        Markdown ->
            "MARKDOWN"

        MindMap ->
            "MIND_MAP"

        EmpathyMap ->
            "EMPATHY_MAP"

        CustomerJourneyMap ->
            "CUSTOMER_JOURNEY_MAP"

        SiteMap ->
            "SITE_MAP"

        GanttChart ->
            "GANTT_CHART"


{-| Convert from a String representation to an elm representation enum.
This is the inverse of the Enum `toString` function. So you can call `toString` and then convert back `fromString` safely.

    Swapi.Enum.Episode.NewHope
        |> Swapi.Enum.Episode.toString
        |> Swapi.Enum.Episode.fromString
        == Just NewHope

This can be useful for generating Strings to use for <select> menus to check which item was selected.

-}
fromString : String -> Maybe Diagram
fromString enumString =
    case enumString of
        "USER_STORY_MAP" ->
            Just UserStoryMap

        "OPPORTUNITY_CANVAS" ->
            Just OpportunityCanvas

        "BUSINESS_MODEL_CANVAS" ->
            Just BusinessModelCanvas

        "FOURLS" ->
            Just Fourls

        "START_STOP_CONTINUE" ->
            Just StartStopContinue

        "KPT" ->
            Just Kpt

        "USER_PERSONA" ->
            Just UserPersona

        "MARKDOWN" ->
            Just Markdown

        "MIND_MAP" ->
            Just MindMap

        "EMPATHY_MAP" ->
            Just EmpathyMap

        "CUSTOMER_JOURNEY_MAP" ->
            Just CustomerJourneyMap

        "SITE_MAP" ->
            Just SiteMap

        "GANTT_CHART" ->
            Just GanttChart

        _ ->
            Nothing
