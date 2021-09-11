module Models.JwtTests exposing (suite)

import Expect
import Maybe.Extra as MaybeEx
import Models.Jwt as Jwt
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Jwt test"
        [ test "Jwt shoud be three commas in the string" <|
            \() ->
                Expect.true "" <| MaybeEx.isJust (Jwt.fromString "eyJhbGciOiJSUzUxMiIsInR5cCI6IkpXVCJ9.eyJjaGVja19lbWFpbCI6ZmFsc2UsImNoZWNrX3Bhc3N3b3JkIjpmYWxzZSwiZXhwIjoxNjE4NzQ5NDk0LCJpYXQiOjE2MTg3NDkxOTQsImp0aSI6ImFjY2NhMzc3LTM2ODYtNDg3NS04N2Y3LTY3NDE0NTU2YTQ5NiIsInN1YiI6IjFhZTQ3ZDJlZjUxYTFiZmQ3NDllZGFmY2MwNzkwMWIzMGU0OTBmYTI4OWQ4NWFkNGQ1ZjkxNDdjMzBlMTAyZGIifQ.QHc-VQdEMsQoX_IkpqKsJCdKtXtwdgRXWPvHESfbNtQ5bPUtV_NQTk17_QgtzpjDaFCaheJUZziePrSbakEAAw-f7raSqzR4KAlbmYIy5e0lAdZWfe7w1CWVp4T0LBNDKAKC9g3-0kyE2jO4lxh9xJ-1X7zOuudwSR_gRQeic4JALA8uOY4pSFOWK0Jz9mSbwi355S8XIJjKGS_Zyhg_j20RQ3w1nkHt6yAFt_xAjmh1610eMD1cSIOfe2P3ZhfIpdl1oyWqapOf2Ep_DJ9_9rPensbOYDst9KC53BgZ3Oy_7y30BqgMTeMTTTVKB-gs_PKLhpAxeA7sNv54qmixTCGXWQrTOJ9T8Xaxc4LlidZUDh3Y7qQpCzeMHoRDti8DskIqOWVUV7XJ-1-xSGCHy-roaGEUPci2Tx5kQ40-ZsQJAVX38cwPHFRnPurrmr8NoGAJrhFV7R5N337Vwcr1hjH5l7oTSHobLlCYpUDgjfH5mLL5e2YYvEMLyu51gqWhyIh2dcDzCYjkFjdxenYQWqmQjXgoa55RcWuakJlclgtwVmIY9Fh_oUg1Uzb6RpHDuBMKWVcaxxuBbNh1wJ7zJzhwjWvu3-FoP0ZFBcN0lNUkAhEZoPuj7br8G8gvoxFaVqDg048mnhe1ASCOaXZAK6TxTKMOOi1IRiQx11mGW")
        , test "Error if not three commas in jwt" <|
            \() ->
                Expect.true "" <| MaybeEx.isNothing (Jwt.fromString "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjE1MTYyMzkwMjIsInBhcyI6ZmFsc2UsImp0aSI6InRlc3QifQ.IcBz1eTRDCXzq_ZAxLZBu5ECieUTUKPyGWQu6SjGZIc")
        ]
