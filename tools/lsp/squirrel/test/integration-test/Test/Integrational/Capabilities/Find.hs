module Test.Integrational.Capabilities.Find
  ( test_findDefinitionAndGoToReferencesCorrespondence
  , test_findDefinitionAndGoToReferencesCorrespondenceIncludesFallback
  , unit_definitionOfId
  , unit_definitionOfLeft
  , unit_referenceOfId
  , unit_referenceOfLeft
  , unit_definitionOfXInWildcard
  , unit_referenceOfXInWildcard

  , unit_type_of_heap_arg
  , unit_type_of_heap_const
  , unit_type_of_let
  , unit_type_of_pascaligo_lambda_arg
  , unit_pascaligo_local_type
  ) where

import System.FilePath ((</>))

import AST.Scope (Fallback, Standard)

import Test.Common.Capabilities.Find
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (Assertion)

import Range (_rFile, interval)

includeInvariants :: [DefinitionReferenceInvariant]
includeInvariants =
  [ DefinitionReferenceInvariant
    { driFile = contractsDir </> "includes" </> "A1.mligo"
    , driDesc = "a1, find references in other files"
    , driDef = Just (interval 1 5 7)
    , driRefs =
      [ (interval 3 10 12){_rFile = contractsDir </> "includes" </> "A2.mligo"}
      , (interval 3 10 12){_rFile = contractsDir </> "includes" </> "A3.mligo"}
      ]
    }
  , DefinitionReferenceInvariant
    { driFile = contractsDir </> "includes" </> "B3.ligo"
    , driDesc = "b3, relative directories"
    , driDef = Just (interval 1 7 9)
    , driRefs =
      [ (interval 3 21 23){_rFile = contractsDir </> "includes" </> "B1.ligo"}
      , (interval 3 12 14){_rFile = contractsDir </> "includes" </> "B2" </> "B2.ligo"}
      ]
    }
  , DefinitionReferenceInvariant
    { driFile = contractsDir </> "includes" </> "C2.religo"
    , driDesc = "c2, find references in other files"
    , driDef = Just (interval 1 5 7)
    , driRefs =
      [ (interval 4 15 17){_rFile = contractsDir </> "includes" </> "C1.mligo"}
      ]
    }
  , DefinitionReferenceInvariant
    { driFile = contractsDir </> "includes" </> "C3.mligo"
    , driDesc = "c3, find references in other files"
    , driDef = Just (interval 1 5 7)
    , driRefs =
      [ (interval 4 10 12){_rFile = contractsDir </> "includes" </> "C1.mligo"}
      ]
    }
  , DefinitionReferenceInvariant
    { driFile = contractsDir </> "includes" </> "D1.ligo"
    , driDesc = "d, no references"
    , driDef = Just (interval 1 7 8)
    , driRefs = []
    }
  , DefinitionReferenceInvariant
    { driFile = contractsDir </> "includes" </> "D2.ligo"
    , driDesc = "d, no references"
    , driDef = Just (interval 1 7 8)
    , driRefs = []
    }
  {- FIXME: We currently can't, given a file A, find for references in a file B.
  , DefinitionReferenceInvariant
    { driFile = contractsDir </> "LIGO-260" </> "A.mligo"
    , driDesc = "b, find in other file (LIGO-260 regression test)"
    , driDef = Just (interval 1 5 6){_rFile = contractsDir </> "LIGO-260" </> "B.mligo"}
    , driRefs =
      [ (interval 4 9 10){_rFile = contractsDir </> "LIGO-260" </> "A.mligo"}
      ]
    }
  -}
  , DefinitionReferenceInvariant
    { driFile = contractsDir </> "LIGO-260" </> "C.mligo"
    , driDesc = "c, find in other file (LIGO-260 regression test)"
    , driDef = Just (interval 1 5 6){_rFile = contractsDir </> "LIGO-260" </> "C.mligo"}
    , driRefs =
      [ (interval 4 13 14){_rFile = contractsDir </> "LIGO-260" </> "A.mligo"}
      ]
    }
  ]

test_findDefinitionAndGoToReferencesCorrespondence :: TestTree
test_findDefinitionAndGoToReferencesCorrespondence =
  testGroup "Find definition and go to references correspondence"
    [ findDefinitionAndGoToReferencesCorrespondence @Standard allVariants
    --, findDefinitionAndGoToReferencesCorrespondence @FromCompiler allVariants  -- FIXME (LIGO-93)
    --  (also LIGO-446 and LIGO-208 on some).
    ]
  where
    allVariants = invariants <> includeInvariants

-- Since we require `ligo preprocess` for includes, we run `Fallback` tests for
-- includes in integration tests.
test_findDefinitionAndGoToReferencesCorrespondenceIncludesFallback :: TestTree
test_findDefinitionAndGoToReferencesCorrespondenceIncludesFallback =
  findDefinitionAndGoToReferencesCorrespondence @Fallback includeInvariants

unit_definitionOfId :: Assertion
unit_definitionOfId = do
  definitionOfId @Standard
  -- definitionOfId @FromCompiler

unit_referenceOfId :: Assertion
unit_referenceOfId = do
  referenceOfId @Standard
  --referenceOfId @FromCompiler  -- FIXME (LIGO-93)

unit_definitionOfLeft :: Assertion
unit_definitionOfLeft = do
  definitionOfLeft @Standard
  --definitionOfLeft @FromCompiler  -- FIXME (LIGO-93) (LIGO-446)

unit_referenceOfLeft :: Assertion
unit_referenceOfLeft = do
  referenceOfLeft @Standard
  --referenceOfLeft @FromCompiler  -- FIXME (LIGO-93) (LIGO-446)

unit_definitionOfXInWildcard :: Assertion
unit_definitionOfXInWildcard = do
  definitionOfXInWildcard @Standard
  --definitionOfXInWildcard @FromCompiler  -- FIXME (LIGO-93)

unit_referenceOfXInWildcard :: Assertion
unit_referenceOfXInWildcard = do
  referenceOfXInWildcard @Standard
  -- referenceOfXInWildcard @FromCompiler  -- FIXME (LIGO-93)

unit_type_of_heap_const :: Assertion
unit_type_of_heap_const = do
  typeOfHeapConst @Standard
  --typeOfHeapConst @FromCompiler  -- FIXME (LIGO-203) (LIGO-446)

unit_type_of_heap_arg :: Assertion
unit_type_of_heap_arg = do
  typeOfHeapArg @Standard
  --typeOfHeapArg @FromCompiler  -- FIXME (LIGO-93)

unit_type_of_let :: Assertion
unit_type_of_let = do
  typeOfLet @Standard
  --typeOfLet @FromCompiler  -- FIXME (LIGO-93)

unit_type_of_pascaligo_lambda_arg :: Assertion
unit_type_of_pascaligo_lambda_arg = do
  typeOfPascaligoLambdaArg @Standard
  --typeOfPascaligoLambdaArg @FromCompiler  -- FIXME (LIGO-93)

unit_pascaligo_local_type :: Assertion
unit_pascaligo_local_type = do
  pascaligoLocalType @Standard
  --pascaligoLocalType @FromCompiler  -- FIXME (LIGO-93)

-- See LIGO-110
-- unit_type_of_camligo_lambda_arg :: Assertion
-- unit_type_of_camligo_lambda_arg = typeOfCamligoLambdaArg @Standard
