module Types.Fuzzer exposing (..)

import Fuzz exposing (Fuzzer)
import Graphql.Enum.Diagram exposing (Diagram(..))
import Time exposing (Posix)
import Types.Color as Color exposing (Color)
import Types.DiagramId as DiagramId exposing (DiagramId)
import Types.DiagramItem exposing (DiagramItem)
import Types.DiagramLocation as DiagramLocation exposing (DiagramLocation)
import Types.FontSize as FontSize exposing (FontSize)
import Types.Item as Item exposing (Children, Item, ItemType(..), Items)
import Types.ItemSettings as ItemSettings exposing (ItemSettings)
import Types.Position exposing (Position)
import Types.Text as Text exposing (Text)
import Types.Title as Title exposing (Title)


itemSettingsFuzzer : Fuzzer ItemSettings
itemSettingsFuzzer =
    Fuzz.map4
        (\bg fg offset fontSize ->
            ItemSettings.new
                |> ItemSettings.withBackgroundColor bg
                |> ItemSettings.withForegroundColor fg
                |> ItemSettings.withOffset offset
                |> ItemSettings.withFontSize fontSize
        )
        (Fuzz.maybe colorFuzzer)
        (Fuzz.maybe colorFuzzer)
        positionFuzzer
        fontSizeFuzzer


itemTypeFuzzer : Fuzzer ItemType
itemTypeFuzzer =
    Fuzz.constant Activities


itemFuzzer : Fuzzer Item
itemFuzzer =
    Fuzz.map5
        (\lineNo text itemType itemSettings children ->
            Item.new
                |> Item.withLineNo lineNo
                |> Item.withText text
                |> Item.withItemType itemType
                |> Item.withItemSettings itemSettings
                |> Item.withChildren children
        )
        (Fuzz.intRange 0 100)
        Fuzz.string
        itemTypeFuzzer
        (Fuzz.maybe itemSettingsFuzzer)
        childrenFuzzer


itemsFuzzer : Fuzzer Items
itemsFuzzer =
    Fuzz.map Item.fromList (Fuzz.list itemFuzzer)


childrenFuzzer : Fuzzer Children
childrenFuzzer =
    Fuzz.oneOf
        [ Fuzz.constant Item.emptyChildren
        ]


diagramItemFuzzer : Fuzzer DiagramItem
diagramItemFuzzer =
    Fuzz.map DiagramItem (Fuzz.maybe diagramIdFuzzer)
        |> Fuzz.andMap textFuzzer
        |> Fuzz.andMap diagramTypeFuzzer
        |> Fuzz.andMap titleFuzzer
        |> Fuzz.andMap (Fuzz.maybe Fuzz.string)
        |> Fuzz.andMap Fuzz.bool
        |> Fuzz.andMap Fuzz.bool
        |> Fuzz.andMap Fuzz.bool
        |> Fuzz.andMap (Fuzz.maybe diagramLocationFuzzer)
        |> Fuzz.andMap posixFuzzer
        |> Fuzz.andMap posixFuzzer


diagramTypeFuzzer : Fuzzer Diagram
diagramTypeFuzzer =
    Fuzz.oneOf
        [ Fuzz.constant UserStoryMap
        , Fuzz.constant OpportunityCanvas
        , Fuzz.constant BusinessModelCanvas
        , Fuzz.constant Fourls
        , Fuzz.constant StartStopContinue
        , Fuzz.constant Kpt
        , Fuzz.constant UserPersona
        , Fuzz.constant MindMap
        , Fuzz.constant EmpathyMap
        , Fuzz.constant Table
        , Fuzz.constant SiteMap
        , Fuzz.constant GanttChart
        , Fuzz.constant ImpactMap
        , Fuzz.constant ErDiagram
        , Fuzz.constant Kanban
        , Fuzz.constant SequenceDiagram
        , Fuzz.constant Freeform
        ]


positionFuzzer : Fuzzer Position
positionFuzzer =
    Fuzz.tuple
        ( Fuzz.intRange -100 100
        , Fuzz.intRange -100 100
        )


fontSizeFuzzer : Fuzzer FontSize
fontSizeFuzzer =
    Fuzz.map (\i -> FontSize.fromInt i) (Fuzz.intRange 8 48)


colorFuzzer : Fuzzer Color
colorFuzzer =
    Fuzz.oneOf
        [ Fuzz.constant Color.white
        , Fuzz.constant Color.black
        , Fuzz.constant Color.gray
        , Fuzz.constant Color.lightGray
        , Fuzz.constant Color.yellow
        , Fuzz.constant Color.green
        , Fuzz.constant Color.blue
        , Fuzz.constant Color.orange
        , Fuzz.constant Color.pink
        , Fuzz.constant Color.red
        , Fuzz.constant Color.purple
        , Fuzz.constant Color.background1Defalut
        , Fuzz.constant Color.background2Defalut
        , Fuzz.constant Color.lineDefalut
        , Fuzz.constant Color.labelDefalut
        , Fuzz.constant Color.backgroundDefalut
        ]


diagramIdFuzzer : Fuzzer DiagramId
diagramIdFuzzer =
    Fuzz.map DiagramId.fromString Fuzz.string


textFuzzer : Fuzzer Text
textFuzzer =
    Fuzz.map Text.fromString Fuzz.string


titleFuzzer : Fuzzer Title
titleFuzzer =
    Fuzz.map Title.fromString Fuzz.string


posixFuzzer : Fuzzer Posix
posixFuzzer =
    Fuzz.map Time.millisToPosix (Fuzz.intRange 0 100000)


diagramLocationFuzzer : Fuzzer DiagramLocation
diagramLocationFuzzer =
    Fuzz.oneOf
        [ Fuzz.constant DiagramLocation.Local
        , Fuzz.constant DiagramLocation.Remote
        , Fuzz.constant DiagramLocation.Gist
        , Fuzz.constant DiagramLocation.GoogleDrive
        ]
