from os.path import *

RAW_DATA_DIR = abspath(join(dirname(__file__), '../rawdata'))
APP_DATA_DIR = abspath(join(dirname(__file__), '../frontend/data'))

SPATIALITE_DB_FILE = 'db.sqlite'
SPATIALITE_ENCODING = 'ASCII'
SPATIALITE_SRID = 4326
SPATIALITE_GEOMETRY_COLUMN_NAME = 'Geometry'

SPATIALITE_GLOBAL_TABLE_PREFIX = '_g_'