module Main where


import Control.Applicative
import Data.Attoparsec.Text ( parseOnly )
import Data.Monoid
import Data.Text ( Text )
import PGSimple.TH
import Test.QuickCheck.Assertions
import Test.QuickCheck.Instances ()
import Test.QuickCheck.Modifiers
import Test.Tasty
import Test.Tasty.QuickCheck

import qualified Data.Text as T

instance Arbitrary Rope where
    arbitrary = oneof [ fmap RLit noSpecialString
                      , fmap RInt nobraceString
                      , fmap RPaste nobraceString
                      ]
      where
        noSpecialString = suchThat arbitrary (\x -> and [ not $ T.isInfixOf "#{" x
                                                       , not $ T.isInfixOf "^{" x
                                                       , T.length x > 0])
        nobraceString = suchThat arbitrary (\x -> and [ not $ T.isInfixOf "}" x
                                                      ])


flattenRope :: [Rope] -> Text
flattenRope = mconcat . map f
  where
    f (RLit t) = t
    f (RInt t) = "#{" <> t <> "}"
    f (RPaste t) = "^{" <> t <> "}"

propRopeParser ::  NonEmptyList Rope -> Result
propRopeParser (NonEmpty rope) =
    (Right $ squashRope rope) ==? (parseOnly ropeParser $ flattenRope rope)


main :: IO ()
main = do
    defaultMain
        $ testGroup "TH Rope parser"
        [ testProperty "parses correct" propRopeParser ]
