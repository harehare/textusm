module ReviewConfig exposing (config)

import Review.Rule exposing (Rule)
import NoDebug.Log
import NoDebug.TodoOrToString
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
import Review.Rule exposing (Rule)


config : List Rule
config =
    [ NoDebug.Log.rule
    , NoDebug.TodoOrToString.rule
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
    
    ]
