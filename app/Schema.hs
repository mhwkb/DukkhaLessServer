{-# LANGUAGE OverloadedStrings #-}
module Schema where

import           Protolude
import           Database.Beam                  (
                                                withDatabase
                                                )
import           Database.Beam.Migrate.Simple   ( autoMigrate )
import           Database.Beam.Migrate.Types    ( CheckedDatabaseSettings
                                                , MigrationSteps
                                                , evaluateDatabase
                                                , migrationStep
                                                )
import           Database.Beam.Postgres         ( Postgres
                                                , PgCommandSyntax
                                                , Connection
                                                )
import           Database.Beam.Postgres.Migrate ( migrationBackend )
import           Schema.V0001            hiding ( migration )
import qualified Schema.V0001                  as V0001
                                                ( migration )

dukkhalessDb :: CheckedDatabaseSettings Postgres DukkhalessDb
dukkhalessDb = evaluateDatabase migration

migration
  :: MigrationSteps
       PgCommandSyntax
       ()
       (CheckedDatabaseSettings Postgres DukkhalessDb)
migration = migrationStep "Initial commit" V0001.migration

runMigrations :: Connection -> IO ()
runMigrations conn =
  withDatabase conn $ autoMigrate migrationBackend dukkhalessDb
