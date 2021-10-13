module Message exposing
    ( Lang(..)
    , Message
    , fromString
    , messagEerrorOccurred
    , messageBadRequest
    , messageFailedPublished
    , messageFailedRevokeToken
    , messageFailedSaveSettings
    , messageFailedSaved
    , messageFailedSharing
    , messageImportCompleted
    , messageInternalServerError
    , messageInvalidUrl
    , messageNetworkError
    , messageNotAuthorized
    , messageNotFound
    , messagePublished
    , messageSuccessfullySaved
    , messageTimeout
    , messageUnknown
    , messageUrlExpired
    , toolPrivate
    , toolPublic
    , toolTipExport
    , toolTipHelp
    , toolTipImport
    , toolTipNewFile
    , toolTipOpenFile
    , toolTipSave
    , toolTipSettings
    , toolTipShare
    )


type alias Message =
    Lang -> String


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


messagEerrorOccurred : Lang -> String
messagEerrorOccurred lang =
    case lang of
        Ja ->
            "エラーが発生しました"

        _ ->
            "An error occurred"


messageNetworkError : Lang -> String
messageNetworkError lang =
    case lang of
        Ja ->
            "ネットワークエラーが発生しました"

        _ ->
            "Network error"


messageSuccessfullySaved : Lang -> String
messageSuccessfullySaved lang =
    case lang of
        Ja ->
            "保存しました"

        _ ->
            "Successfully saved"


messageFailedSaved : Lang -> String
messageFailedSaved lang =
    case lang of
        Ja ->
            "保存に失敗しました"

        _ ->
            "Failed saved"


messageImportCompleted : Lang -> String
messageImportCompleted lang =
    case lang of
        Ja ->
            "インポートが完了しました"

        _ ->
            "Import completed"


messageFailedSharing : Lang -> String
messageFailedSharing lang =
    case lang of
        Ja ->
            "共有 URL の生成に失敗しました"

        _ ->
            "Failed to generate URL for sharing"


messagePublished : Lang -> String
messagePublished lang =
    case lang of
        Ja ->
            "公開しました"

        _ ->
            "Published"


messageFailedPublished : Lang -> String
messageFailedPublished lang =
    case lang of
        Ja ->
            "公開設定の変更に失敗しました"

        _ ->
            "Failed to change publishing settings"


messageNotFound : Lang -> String
messageNotFound lang =
    case lang of
        Ja ->
            "見つかりませんでした"

        _ ->
            "Not found"


messageNotAuthorized : Lang -> String
messageNotAuthorized lang =
    case lang of
        Ja ->
            "権限がありません"

        _ ->
            "Not authorized"


messageInternalServerError : Lang -> String
messageInternalServerError lang =
    case lang of
        Ja ->
            "システムエラーが発生しました"

        _ ->
            "Internal server error has occurred"


messageUrlExpired : Lang -> String
messageUrlExpired lang =
    case lang of
        Ja ->
            "URL の有効期限が切れました"

        _ ->
            "URL has expired"


messageUnknown : Lang -> String
messageUnknown lang =
    case lang of
        Ja ->
            "システムエラーが発生しました"

        _ ->
            "Unknown error has occurred"


messageInvalidUrl : Lang -> String
messageInvalidUrl lang =
    case lang of
        Ja ->
            "不正な URL にアクセスされました"

        _ ->
            "Invalid URL"


messageTimeout : Lang -> String
messageTimeout lang =
    case lang of
        Ja ->
            "リクエストがタイムアウトしました"

        _ ->
            "Request timeout"


messageBadRequest : Lang -> String
messageBadRequest lang =
    case lang of
        Ja ->
            "不正なリクエストです"

        _ ->
            "Bad request"


messageFailedRevokeToken : Lang -> String
messageFailedRevokeToken lang =
    case lang of
        Ja ->
            "トークンの失効処理に失敗しました"

        _ ->
            "Failed to revoke the token"


messageFailedSaveSettings : Lang -> String
messageFailedSaveSettings lang =
    case lang of
        Ja ->
            "設定の保存に失敗しました"

        _ ->
            "Failed to save settings"
