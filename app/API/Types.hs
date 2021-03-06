{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE FunctionalDependencies #-}
module API.Types where

import           Protolude                      ( Eq
                                                , Show
                                                , ($)
                                                , (<*>)
                                                , (<$>)
                                                , Generic
                                                , (<>)
                                                )
import           Control.Lens.Combinators
import           Data.Aeson
import           Data.UUID                      ( UUID )
import           Data.Aeson.Types               ( typeMismatch )
import           Data.Time.Clock                ( UTCTime )
import           Types

data RegisterUser = RegisterUser
  { registerUserUsername :: Username
  , registerUserRawPassword :: RawPassword
  , registerUserPublicKey :: PublicKey
  }
  deriving (Generic, Eq, Show)
makeFields ''RegisterUser

data LoginUser = LoginUser { loginUserUsername :: Username, loginUserRawPassword :: RawPassword }
  deriving (Eq, Show, Generic)
makeFields ''LoginUser

data JournalEntry = JournalEntry
  { journalEntryJournalId :: JournalId
  , journalEntryCreatedAt :: CreatedAt
  , journalEntryUserId :: UserId
  , journalEntryLastUpdated :: LastUpdated
  , journalEntryTitleCiphertext :: TitleCiphertext
  , journalEntryBodyCiphertext :: BodyCiphertext
  }
  deriving (Eq, Show, Generic)
makeFields ''JournalEntry

data UpdateJournalEntry = UpdateJournalEntry
  { updateJournalEntryBodyCiphertext :: BodyCiphertext
  , updateJournalEntryTitleCiphertext :: TitleCiphertext
  , updateJournalEntryJournalId :: JournalId
  }
  deriving (Eq, Show, Generic)
makeFields ''UpdateJournalEntry

data CreateJournalEntry = CreateJournalEntry
  { createJournalEntryBodyCiphertext :: BodyCiphertext
  , createJournalEntryTitleCiphertext :: TitleCiphertext
  }
  deriving (Eq, Show, Generic)
makeFields ''CreateJournalEntry

newtype Expiry = Expiry { expiryUTCTime :: UTCTime }
    deriving (Eq, Show, Generic, ToJSON, FromJSON)
makeFields ''Expiry

newtype TokenId = TokenId { tokenIdUUID :: UUID }
  deriving (Eq, Show, Generic, ToJSON, FromJSON)
makeFields ''TokenId

data AccessToken = AccessToken
  { accessTokenTokenId :: TokenId
  , accessTokenUserId :: UserId
  , accessTokenExpiry :: Expiry
  }
  deriving (Eq, Show, Generic)
makeFields ''AccessToken

newtype SessionToken = SessionToken { sessionTokenBase64Content :: Base64Content }
  deriving (Eq, Show, Generic)
makeFields ''SessionToken


instance FromJSON RegisterUser where
  parseJSON = withObject "loginUser" $ \o ->
    RegisterUser <$> o .: "username" <*> o .: "password" <*> o .: "publicKey"

instance FromJSON LoginUser where
  parseJSON = withObject "loginUser"
    $ \o -> LoginUser <$> o .: "username" <*> o .: "password"

instance ToJSON AccessToken where
  toJSON (AccessToken ti ui e) = object ["jti" .= ti, "sub" .= ui, "exp" .= e]
  toEncoding (AccessToken ti ui e) =
    pairs ("jti" .= ti <> "sub" .= ui <> "exp" .= e)
instance FromJSON AccessToken where
  parseJSON (Object v) =
    AccessToken <$> v .: "jti" <*> v .: "sub" <*> v .: "exp"
  parseJSON invalid = typeMismatch "AccessToken" invalid

instance ToJSON SessionToken where
  toJSON (SessionToken content) = object ["sessionToken" .= content]
  toEncoding (SessionToken content) = pairs ("sessionToken" .= content)

instance FromJSON SessionToken where
  parseJSON (Object v) = SessionToken <$> v .: "sessionToken"
  parseJSON invalid    = typeMismatch "SessionToken" invalid
