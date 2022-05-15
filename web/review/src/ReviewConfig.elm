module ReviewConfig exposing (config)

import Review.Rule exposing (Rule)
import NoDebug.Log
import NoDebug.TodoOrToString
import NoUnused.CustomTypeConstructorArgs
import NoUnused.CustomTypeConstructors
import NoUnused.Dependencies
import NoUnused.Exports
import NoUnused.Modules
import NoUnused.Parameters
import NoUnused.Patterns
import NoUnused.Variables
import NoUnoptimizedRecursion
import NoSimpleLetBody
import CognitiveComplexity
import NoExposingEverything
import NoImportingEverything
import NoMissingTypeAnnotation
import NoMissingTypeAnnotationInLetIn
import NoMissingTypeExpose
import NoPrematureLetComputation
import NoForbiddenWords
import NoInconsistentAliases
import NoModuleOnExposedNames
import NoSinglePatternCase
import Review.Rule exposing (Rule)
import Simplify
import UseCamelCase
import Review.Rule exposing (Rule)


config : List Rule
config =
    [ NoDebug.Log.rule
    , NoDebug.TodoOrToString.rule
    , NoUnused.CustomTypeConstructors.rule []
    , NoUnused.CustomTypeConstructorArgs.rule
    , NoUnused.Dependencies.rule
    , NoUnused.Exports.rule
    , NoForbiddenWords.rule [ "REPLACEME" ]
    , NoUnused.Modules.rule
    , NoUnused.Parameters.rule
    , NoUnused.Patterns.rule
    , NoUnused.Variables.rule
    , NoUnoptimizedRecursion.rule (NoUnoptimizedRecursion.optOutWithComment "IGNORE")
    , NoSimpleLetBody.rule
    , CognitiveComplexity.rule 15
    , NoExposingEverything.rule
    , NoImportingEverything.rule []
    , NoMissingTypeAnnotation.rule
    , NoMissingTypeAnnotationInLetIn.rule
    , NoMissingTypeExpose.rule
    , NoPrematureLetComputation.rule
    , NoInconsistentAliases.config
        [ ( "Html.Attributes", "Attr" )
        , ( "Json.Decode", "D" )
        , ( "Json.Encode", "E" )
        ]
        |> NoInconsistentAliases.noMissingAliases
        |> NoInconsistentAliases.rule
    , NoModuleOnExposedNames.rule
    , NoSinglePatternCase.rule NoSinglePatternCase.fixInArgument
    , UseCamelCase.rule UseCamelCase.default
    , Simplify.rule Simplify.defaults
    ]
