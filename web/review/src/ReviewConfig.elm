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
import Simplify
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
    , Simplify.rule Simplify.defaults
    ]
