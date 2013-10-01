from os.path import *

RAW_DATA_DIR = abspath(join(dirname(__file__), '../rawdata'))
APP_DATA_DIR = abspath(join(dirname(__file__), '../frontend/www/data'))

EQUAL_AREA_SRID = 2163
GEOGRAPHIC_SRID = 4326

SPATIALITE_DB_FILE = 'db.sqlite'
SPATIALITE_ENCODING = 'utf-8'
SPATIALITE_GEOMETRY_COLUMN_NAME = 'geom'

SPATIALITE_PK_NAME = 'PK_UID'
APP_PK_NAME = 'gid'

BROWNFIELDS_TABLE = '_G_brownfields'
COUNTIES_TABLE = '_G_counties'
DEMOGRAPHY_TABLE = '_G_demography'

USE_DEMOGRAPHY = True
FEATURE_CHUNK_SIZE = 1000  # How many features go into a single geojson file?
BACKEND_CHUNK_SIZE = 250   # break up intensive SQL insertions into batches of this size


global_datasets = {
    'brownfields': {
        'table': BROWNFIELDS_TABLE,
        'path': 'nationaldata/brownfields',
        'srid': GEOGRAPHIC_SRID,
    },
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

naics_csv = {
    'nationwide': 'nationaldata/NAICS_BLS/mfg_clean_allmfg_us.csv',
    'statewide': 'nationaldata/NAICS_BLS/mfg_clean_allmfg_st.csv',
    'countywide': 'nationaldata/NAICS_BLS/mfg_clean_allmfg_co.csv',
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
