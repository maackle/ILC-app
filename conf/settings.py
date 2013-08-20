from os.path import *

RAW_DATA_DIR = abspath(join(dirname(__file__), '../rawdata'))
APP_DATA_DIR = abspath(join(dirname(__file__), '../frontend/data'))

EQUAL_AREA_SRID = 2163
GEOGRAPHIC_SRID = 4326

SPATIALITE_DB_FILE = 'db.sqlite'
SPATIALITE_ENCODING = 'ASCII'
SPATIALITE_GEOMETRY_COLUMN_NAME = 'geom'

SPATIALITE_PK_NAME = 'GID'
APP_PK_NAME = 'gid'

BROWNFIELDS_TABLE = '_G_brownfields'
CENSUS_TABLE = '_G_census_tracts'
DEMOGRAPHY_TABLE = '_G_demography'