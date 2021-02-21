module Translations exposing
    ( Lang(..)
    , fromString
    , messageFailed
    , messageFailedSaved
    , messageImportCompleted
    , messageNetworkError
    , messageRequestTimeout
    , messageSuccessfullySaved
    , toolPrivate
    , toolPublic
    , toolTipBack
    , toolTipExport
    , toolTipHelp
    , toolTipImport
    , toolTipNewFile
    , toolTipOpenFile
    , toolTipSave
    , toolTipSettings
    , toolTipShare
    , toolTipTags
    )


type Lang
    = En
    | Ja


fromString : String -> Lang
fromString lang =
    case lang of
        "ja" ->
            Ja

        _ ->
            En


toolTipNewFile : Lang -> String
toolTipNewFile lang =
    case lang of
        Ja ->
            "新規作成"

        _ ->
            "New File"


toolTipBack : Lang -> String
toolTipBack lang =
    case lang of
        Ja ->
            "戻る"

        _ ->
            "Back"


toolTipOpenFile : Lang -> String
toolTipOpenFile lang =
    case lang of
        Ja ->
            "開く"

        _ ->
            "Open File"


toolTipSave : Lang -> String
toolTipSave lang =
    case lang of
        Ja ->
            "保存"

        _ ->
            "Save"


toolTipImport : Lang -> String
toolTipImport lang =
    case lang of
        Ja ->
            "インポート"

        _ ->
            "Import"


toolTipExport : Lang -> String
toolTipExport lang =
    case lang of
        Ja ->
            "エクスポート"

        _ ->
            "Export"


toolTipSettings : Lang -> String
toolTipSettings lang =
    case lang of
        Ja ->
            "設定"

        _ ->
            "Settings"


toolTipTags : Lang -> String
toolTipTags lang =
    case lang of
        Ja ->
            "タグ"

        _ ->
            "Tags"


toolPublic : Lang -> String
toolPublic lang =
    case lang of
        Ja ->
            "公開"

        _ ->
            "Public"


toolPrivate : Lang -> String
toolPrivate lang =
    case lang of
        Ja ->
            "非公開"

        _ ->
            "Private"


toolTipShare : Lang -> String
toolTipShare lang =
    case lang of
        Ja ->
            "共有"

        _ ->
            "Share"


toolTipHelp : Lang -> String
toolTipHelp lang =
    case lang of
        Ja ->
            "ヘルプ"

        _ ->
            "Help"


messageFailed : Lang -> String
messageFailed lang =
    case lang of
        Ja ->
            "失敗しました。"

        _ ->
            "Failed."


messageRequestTimeout : Lang -> String
messageRequestTimeout lang =
    case lang of
        Ja ->
            "リクエストがタイムアウトしました。"

        _ ->
            "Request timeout."


messageNetworkError : Lang -> String
messageNetworkError lang =
    case lang of
        Ja ->
            "ネットワークエラーが発生しました。"

        _ ->
            "Network error."


messageSuccessfullySaved : Lang -> String -> String
messageSuccessfullySaved lang title =
    case lang of
        Ja ->
            "\"" ++ title ++ "\" を保存しました。"

        _ ->
            "Successfully \"" ++ title ++ "\" saved."


messageFailedSaved : Lang -> String -> String
messageFailedSaved lang title =
    case lang of
        Ja ->
            "\"" ++ title ++ "\" の保存に失敗しました。"

        _ ->
            "Failed \"" ++ title ++ "\" saved."


messageImportCompleted : Lang -> String
messageImportCompleted lang =
    case lang of
        Ja ->
            "インポートが完了しました。"

        _ ->
            "Import completed."
