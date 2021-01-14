module Data.FileType exposing (FileType(..), ddl, html, markdown, pdf, plainText, png, svg, toString)


type alias Extension =
    String


type FileType
    = Png Extension
    | Svg Extension
    | Pdf Extension
    | Html Extension
    | Ddl Extension
    | Markdown Extension
    | PlainText Extension


toString : FileType -> String
toString fileType =
    case fileType of
        Png _ ->
            "PNG"

        Svg _ ->
            "SVG"

        Pdf _ ->
            "PDF"

        Html _ ->
            "Html"

        Ddl _ ->
            "DDL"

        Markdown _ ->
            "Markdown"

        PlainText _ ->
            "Text"


png : FileType
png =
    Png ".png"


svg : FileType
svg =
    Svg ".svg"


pdf : FileType
pdf =
    Pdf ".pdf"


html : FileType
html =
    Html ".html"


ddl : FileType
ddl =
    Ddl ".sql"


markdown : FileType
markdown =
    Markdown ".md"


plainText : FileType
plainText =
    PlainText ".txt"
