{-# LANGUAGE OverloadedStrings #-}
module App where

import           Protolude                      ( IO
                                                , ($)
                                                , (.)
                                                , (>>=)
                                                , Maybe(..)
                                                , putStrLn
                                                , show
                                                , (++)
                                                , Bool(..)
                                                , (==)
                                                )
import           Control.Lens
import qualified Data.ByteString               as BS
import           Data.Default                   ( def )
import           Data.Text.Lazy                 ( unpack )
import           Network.Wai                    ( Middleware )
import           Network.Wai.Middleware.RequestLogger
                                                ( logStdoutDev
                                                , logStdout
                                                )
import           Network.Wai.Middleware.Rewrite ( PathsAndQueries
                                                , rewritePureWithQueries
                                                )
import           Network.Wai.Middleware.Gzip    ( gzip )
import           Network.HTTP.Types.Header      ( RequestHeaders )
import           Web.Scotty
import           Types
import qualified Conf                          as Conf
import           Conf                           ( Environment(..) )
import qualified Data.Configurator             as C

app :: Conf.Environment -> IO ()
app env = do
  config <-
    C.load [C.Required $ unpack $ Conf.confFileName env] >>= Conf.makeConfig
  case config of
    Just conf -> app'
      conf
      (case env of
        Production  -> logStdout
        Development -> logStdoutDev
      )
    Nothing -> putStrLn $ "Config file not found for environment: " ++ show env


app' :: Conf.Config -> Middleware -> IO ()
app' conf logger = scotty 4000 $ do
  middleware $ rewritePureWithQueries removeApiPrefix
  middleware logger
  middleware $ gzip def
  get "/:word" $ html "Hi"
  post "/login" $ do
    loginUser <- jsonData :: ActionM LoginUser
    text $ loginUser ^. (username . _text)
  post "/register" $ do
    registerUser <- jsonData :: ActionM RegisterUser
    text $ registerUser ^. (username . _text)

removeApiPrefix :: PathsAndQueries -> RequestHeaders -> PathsAndQueries
removeApiPrefix ("api" : tail, queries) _ = (tail, queries)
removeApiPrefix paq                     _ = paq

