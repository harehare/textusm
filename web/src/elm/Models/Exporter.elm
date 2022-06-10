port module Models.Exporter exposing (Export(..), ExportInfo, copy, copyBase64, copyable, download, downloadable, export)

import File.Download as Download
import Graphql.Enum.Diagram exposing (Diagram)
import Models.Diagram.ER as ER
import Models.Diagram.GanttChart as GanttChart
import Models.Diagram.SequenceDiagram as SequenceDiagram
import Models.Diagram.Table as Table
import Models.DiagramData as DiagramData exposing (DiagramData(..))
import Models.DiagramType as DiagramType
import Models.FileType as FileType exposing (FileType)
import Models.Item exposing (Items)
import Models.Size as Size exposing (Size)
import Models.Text as Text exposing (Text)
import Models.Title as Title exposing (Title)
import Ports
import Time


type Export
    = Downloadable FileType
    | Copyable FileType


type alias ExportInfo =
    { width : Int
    , height : Int
    , id : String
    , title : String
    , text : String
    , x : Float
    , y : Float
    , diagramType : String
    }


port downloadHtml : ExportInfo -> Cmd msg


port downloadPdf : ExportInfo -> Cmd msg


port downloadPng : ExportInfo -> Cmd msg


port downloadSvg : ExportInfo -> Cmd msg


port copyToClipboardPng : ExportInfo -> Cmd msg


port copyBase64 : ExportInfo -> Cmd msg


copy : Export -> String -> Maybe (Cmd msg)
copy exportDiagram content =
    case exportDiagram of
        Downloadable _ ->
            Nothing

        Copyable _ ->
            Just <| Ports.copyText content


copyable : FileType -> Export
copyable fileType =
    Copyable fileType


download : Export -> Title -> String -> Maybe (Cmd msg)
download exportDiagram title content =
    case exportDiagram of
        Downloadable fileType ->
            Just <| Download.string (Title.toString title ++ FileType.extension fileType) "text/plain" content

        Copyable _ ->
            Nothing


downloadable : FileType -> Export
downloadable fileType =
    Downloadable fileType


export :
    Export
    ->
        { title : Title
        , text : Text
        , size : Size
        , diagramType : Diagram
        , items : Items
        , data : DiagramData
        }
    -> Maybe (Cmd msg)
export e { title, text, size, diagramType, items, data } =
    case e of
        Downloadable fileType ->
            case fileType of
                FileType.PlainText _ ->
                    download e title (Text.toString text)

                _ ->
                    let
                        action =
                            case fileType of
                                FileType.Png ex ->
                                    Just ( downloadPng, ex )

                                FileType.Svg ex ->
                                    Just ( downloadSvg, ex )

                                FileType.Pdf ex ->
                                    Just ( downloadPdf, ex )

                                FileType.Html ex ->
                                    Just ( downloadHtml, ex )

                                _ ->
                                    Nothing
                    in
                    action
                        |> Maybe.map
                            (\( a, extension ) ->
                                a
                                    { diagramType = DiagramType.toString diagramType
                                    , height = Size.getHeight size
                                    , id = "usm"
                                    , text = Text.toString text
                                    , title = Title.toString title ++ extension
                                    , width = Size.getWidth size
                                    , x = 0
                                    , y = 0
                                    }
                            )

        Copyable fileType ->
            case fileType of
                FileType.Png _ ->
                    Just <|
                        copyToClipboardPng
                            { diagramType = DiagramType.toString diagramType
                            , height = Size.getHeight size
                            , id = "usm"
                            , text = Text.toString text
                            , title = ""
                            , width = Size.getWidth size
                            , x = 0
                            , y = 0
                            }

                FileType.Ddl _ ->
                    let
                        ( _, tables ) =
                            ER.from items

                        ddl : String
                        ddl =
                            List.map ER.tableToString tables
                                |> String.join "\n"
                    in
                    copy e ddl

                FileType.Markdown _ ->
                    copy e (Table.toString (Table.from items))

                FileType.Mermaid _ ->
                    let
                        mermaidString : Maybe String
                        mermaidString =
                            case data of
                                DiagramData.ErDiagram data_ ->
                                    Just <| ER.toMermaidString data_

                                DiagramData.SequenceDiagram data_ ->
                                    Just <| SequenceDiagram.toMermaidString data_

                                DiagramData.GanttChart data_ ->
                                    Maybe.map (\d -> GanttChart.toMermaidString title Time.utc d) data_

                                _ ->
                                    Nothing
                    in
                    Maybe.andThen (copy e) mermaidString

                FileType.Base64 ->
                    Just <|
                        copyBase64
                            { diagramType = DiagramType.toString diagramType
                            , height = Size.getHeight size
                            , id = "usm"
                            , text = Text.toString text
                            , title = Title.toString title
                            , width = Size.getWidth size
                            , x = 0
                            , y = 0
                            }

                _ ->
                    Nothing
