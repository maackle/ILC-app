from os.path import *

RAW_DATA_DIR = abspath(join(dirname(__file__), '../rawdata'))
APP_DATA_DIR = abspath(join(dirname(__file__), '../frontend/data'))

SPATIALITE_ENCODING = 'UTF-8'
SPATIALITE_SRID = 4326
SPATIALITE_GEOMETRY_COLUMN_NAME = 'Geometry'