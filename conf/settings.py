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
COUNTIES_TABLE = '_G_counties'
DEMOGRAPHY_TABLE = '_G_demography'

USE_DEMOGRAPHY = True
FEATURE_CHUNK_SIZE = 1000  # How many features go into a single geojson file?
BACKEND_CHUNK_SIZE = 50


global_datasets = {
    # settings.BROWNFIELDS_TABLE: 'brownfields/GEODATA_Featureclass_MAR2013',
    # 'census_tracts': {
    #     'table': settings.CENSUS_TABLE,
    #     'path': 'census_tracts/Mecklenburg_CensusTracts',
    #     'srid': settings.GEOGRAPHIC_SRID,
    # },
    'counties': {
        'table': COUNTIES_TABLE,
        'path': 'nationaldata/Counties',
        'srid': GEOGRAPHIC_SRID,
    },
    'demography': {
        'table': DEMOGRAPHY_TABLE,
        'path': 'nationaldata/TRACT_ACS_07_11-2163',
        'srid': EQUAL_AREA_SRID,
    },
}


demography_categories = {
    'race_categories': (
        {
            'rawname': 'WHITE',
            'name': 'white',
            'title': 'White',
        },
        {
            'rawname': 'BLACK',
            'name': 'black',
            'title': 'Black',
        },
        {
            'rawname': 'ASIAN',
            'name': 'asian',
            'title': 'Asian',
        },
        {
            'rawname': 'MULTI',
            'name': 'multi',
            'title': 'Multiple',
        },
    ),
    'occupation_categories': (
        {
            'rawname': 'PROD',
            'name': 'manufacturing',
            'title': 'Manufacturing',
        },
        {
            'rawname': 'CONST',
            'name': 'construction',
            'title': 'Construction',
        },
        {
            'rawname': 'MGMT',
            'name': 'management',
            'title': 'Management',
        },
        {
            'rawname': 'SERVICE',
            'name': 'service',
            'title': 'Service',
        },
        {
            'rawname': 'OFFICE',
            'name': 'office',
            'title': 'Office',
        },
    ),
}
