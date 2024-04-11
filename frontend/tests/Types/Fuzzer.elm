module Types.Fuzzer exposing (colorFuzzer, diagramItemFuzzer, diagramTypeFuzzer, itemFuzzer, itemSettingsFuzzer, settingsFuzzer)

import Diagram.Types.CardSize as CardSize exposing (CardSize)
import Diagram.Types.Id as DiagramId exposing (DiagramId)
import Diagram.Types.Item exposing (DiagramItem)
import Diagram.Types.Location as DiagramLocation exposing (Location)
import Diagram.Types.Scale as Scale exposing (Scale)
import Diagram.Types.Settings exposing (ColorSetting, ColorSettings)
import Diagram.Types.Type exposing (DiagramType(..))
import Fuzz exposing (Fuzzer)
import Time exposing (Posix)
import Types.Color as Color exposing (Color)
import Types.Font as Font
import Types.FontSize as FontSize exposing (FontSize)
import Types.Item as Item exposing (Children, Item)
import Types.Item.Settings as ItemSettings
import Types.Position exposing (Position)
import Types.Settings exposing (EditorSettings, Settings)
import Types.SplitDirection as SplitDirection exposing (SplitDirection)
import Types.Text as Text exposing (Text)
import Types.Theme as Theme exposing (Theme)
import Types.Title as Title exposing (Title)


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
        , Fuzz.constant Color.backgroundDarkDefalut
        , Fuzz.constant Color.teal
        , Fuzz.constant Color.olive
        , Fuzz.constant Color.lime
        , customColorFuzzer
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
        |> Fuzz.andMap (Fuzz.maybe diagramLocationFuzzer)
        |> Fuzz.andMap posixFuzzer
        |> Fuzz.andMap posixFuzzer


diagramTypeFuzzer : Fuzzer DiagramType
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


itemFuzzer : Fuzzer Item
itemFuzzer =
    Fuzz.map
        (\lineNo text comments itemSettings children ->
            Item.new
                |> Item.withLineNo lineNo
                |> Item.withText text
                |> Item.withComments comments
                |> Item.withSettings itemSettings
                |> Item.withChildren children
        )
        (Fuzz.intRange 0 100)
        |> Fuzz.andMap
            (Fuzz.map
                (\s ->
                    let
                        tokens : List String
                        tokens =
                            String.split "#" s
                    in
                    (if List.length tokens > 1 then
                        tokens
                            |> List.map
                                (\s_ ->
                                    if String.endsWith "\\" s_ then
                                        s_ ++ "#"

                                    else
                                        s_
                                )
                            |> String.concat

                     else
                        s
                    )
                        |> String.replace "|" ""
                        |> String.trim
                )
                Fuzz.string
            )
        |> Fuzz.andMap
            (Fuzz.string
                |> Fuzz.map
                    (\s ->
                        if s |> String.trim |> String.isEmpty then
                            Nothing

                        else
                            Just (String.replace "#" "" s |> String.replace "|" "")
                    )
            )
        |> Fuzz.andMap (Fuzz.maybe itemSettingsFuzzer)
        |> Fuzz.andMap childrenFuzzer


itemSettingsFuzzer : Fuzzer ItemSettings.Settings
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


childrenFuzzer : Fuzzer Children
childrenFuzzer =
    Fuzz.oneOf
        [ Fuzz.constant Item.emptyChildren
        ]


customColorFuzzer : Fuzzer Color
customColorFuzzer =
    Fuzz.map Color.fromString rgbFuzzer


diagramIdFuzzer : Fuzzer DiagramId
diagramIdFuzzer =
    Fuzz.map DiagramId.fromString Fuzz.string


diagramLocationFuzzer : Fuzzer Location
diagramLocationFuzzer =
    Fuzz.oneOf
        [ Fuzz.constant DiagramLocation.Local
        , Fuzz.constant DiagramLocation.Remote
        , Fuzz.constant DiagramLocation.Gist
        ]


fontSizeFuzzer : Fuzzer FontSize
fontSizeFuzzer =
    Fuzz.map (\i -> FontSize.fromInt i) (Fuzz.intRange 8 48)


hexFuzzer : Fuzzer String
hexFuzzer =
    Fuzz.oneOf
        [ Fuzz.constant "A"
        , Fuzz.constant "B"
        , Fuzz.constant "C"
        , Fuzz.constant "D"
        , Fuzz.constant "E"
        , Fuzz.constant "F"
        , Fuzz.constant "0"
        , Fuzz.constant "1"
        , Fuzz.constant "2"
        , Fuzz.constant "3"
        , Fuzz.constant "4"
        , Fuzz.constant "5"
        , Fuzz.constant "6"
        , Fuzz.constant "7"
        , Fuzz.constant "8"
        , Fuzz.constant "9"
        ]


themeFuzzer : Fuzzer Theme
themeFuzzer =
    Fuzz.oneOf
        [ Fuzz.constant Theme.Dark
        , Fuzz.constant Theme.Light
        , Fuzz.constant <| Theme.System True
        ]


splitDirectionFuzzer : Fuzzer SplitDirection
splitDirectionFuzzer =
    Fuzz.oneOf
        [ Fuzz.constant SplitDirection.Vertical
        , Fuzz.constant SplitDirection.Horizontal
        ]


positionFuzzer : Fuzzer Position
positionFuzzer =
    Fuzz.pair
        (Fuzz.intRange -100 100)
        (Fuzz.intRange -100 100)


posixFuzzer : Fuzzer Posix
posixFuzzer =
    Fuzz.map Time.millisToPosix (Fuzz.intRange 0 100000)


rgbFuzzer : Fuzzer String
rgbFuzzer =
    Fuzz.map
        (\c1 c2 c3 c4 c5 c6 ->
            "#" ++ c1 ++ c2 ++ c3 ++ c4 ++ c5 ++ c6
        )
        hexFuzzer
        |> Fuzz.andMap hexFuzzer
        |> Fuzz.andMap hexFuzzer
        |> Fuzz.andMap hexFuzzer
        |> Fuzz.andMap hexFuzzer
        |> Fuzz.andMap hexFuzzer


textFuzzer : Fuzzer Text
textFuzzer =
    Fuzz.map Text.fromString Fuzz.string


titleFuzzer : Fuzzer Title
titleFuzzer =
    Fuzz.map Title.fromString Fuzz.string


colorSettingFuzzer : Fuzzer ColorSetting
colorSettingFuzzer =
    Fuzz.map ColorSetting colorFuzzer
        |> Fuzz.andMap colorFuzzer


scaleFuzzer : Fuzzer Scale
scaleFuzzer =
    Fuzz.map Scale.fromFloat Fuzz.float


cardSizeFuzzer : Fuzzer CardSize
cardSizeFuzzer =
    Fuzz.map CardSize.fromInt Fuzz.int


colorSettingsFuzzer : Fuzzer ColorSettings
colorSettingsFuzzer =
    Fuzz.map ColorSettings colorSettingFuzzer
        |> Fuzz.andMap colorSettingFuzzer
        |> Fuzz.andMap colorSettingFuzzer
        |> Fuzz.andMap colorFuzzer
        |> Fuzz.andMap colorFuzzer
        |> Fuzz.andMap (Fuzz.maybe colorFuzzer)


diagramSettingsFuzzer : Fuzzer Diagram.Types.Settings.Settings
diagramSettingsFuzzer =
    Fuzz.map Diagram.Types.Settings.Settings (Fuzz.map Font.googleFont Fuzz.string)
        |> Fuzz.andMap (Fuzz.map Diagram.Types.Settings.CardRect cardSizeFuzzer |> Fuzz.andMap cardSizeFuzzer)
        |> Fuzz.andMap colorSettingsFuzzer
        |> Fuzz.andMap colorFuzzer
        |> Fuzz.andMap (Fuzz.maybe Fuzz.bool)
        |> Fuzz.andMap (Fuzz.maybe scaleFuzzer)
        |> Fuzz.andMap (Fuzz.maybe Fuzz.bool)
        |> Fuzz.andMap (Fuzz.maybe Fuzz.bool)
        |> Fuzz.andMap (Fuzz.maybe Fuzz.bool)


settingsFuzzer : Fuzzer Settings
settingsFuzzer =
    Fuzz.map Settings (Fuzz.maybe Fuzz.int)
        |> Fuzz.andMap (Fuzz.map Font.googleFont Fuzz.string)
        |> Fuzz.andMap (Fuzz.maybe diagramIdFuzzer)
        |> Fuzz.andMap diagramSettingsFuzzer
        |> Fuzz.andMap (Fuzz.maybe textFuzzer)
        |> Fuzz.andMap (Fuzz.maybe titleFuzzer)
        |> Fuzz.andMap
            (Fuzz.maybe <|
                (Fuzz.map EditorSettings
                    (Fuzz.map FontSize.fromInt Fuzz.int)
                    |> Fuzz.andMap Fuzz.bool
                    |> Fuzz.andMap Fuzz.bool
                )
            )
        |> Fuzz.andMap (Fuzz.maybe diagramItemFuzzer)
        |> Fuzz.andMap (Fuzz.maybe diagramLocationFuzzer)
        |> Fuzz.andMap (Fuzz.maybe themeFuzzer)
        |> Fuzz.andMap (Fuzz.maybe splitDirectionFuzzer)
