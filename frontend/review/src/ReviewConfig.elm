module ReviewConfig exposing (config)

import CognitiveComplexity
import LimitAliasedRecordSize
import NoDebug.Log
import NoDebug.TodoOrToString
import NoExposingEverything
import NoForbiddenWords
import NoImportingEverything
import NoInconsistentAliases
import NoMissingSubscriptionsCall
import NoMissingTypeAnnotation
import NoMissingTypeAnnotationInLetIn
import NoMissingTypeExpose
import NoModuleOnExposedNames
import NoPrematureLetComputation
import NoRecursiveUpdate
import NoSimpleLetBody
import NoSinglePatternCase
import NoUnoptimizedRecursion
import NoUnused.CustomTypeConstructorArgs
import NoUnused.CustomTypeConstructors
import NoUnused.Dependencies
import NoUnused.Exports
import NoUnused.Modules
import NoUnused.Parameters
import NoUnused.Patterns
import NoUnused.Variables
import NoUnusedPorts
import NoUselessSubscriptions
import Review.Rule exposing (Rule)
import Simplify
import UseCamelCase


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
    , NoUselessSubscriptions.rule
    , NoMissingSubscriptionsCall.rule
    , NoRecursiveUpdate.rule
    , NoUnusedPorts.rule
    , LimitAliasedRecordSize.rule
        (20 |> LimitAliasedRecordSize.maxRecordSize)
    ]
