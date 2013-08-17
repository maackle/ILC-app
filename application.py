import csv
import sys

from flask import *
from sqlalchemy import create_engine
from werkzeug.contrib.cache import SimpleCache

import conf
from util import *

app = Flask(__name__)
# app.config.from_object('conf.settings')
# app.config.from_object('conf.environment')
# app.jinja_env.add_extension('pyjade.ext.jinja.PyJadeExtension')



def load_global_shapefiles():
	pass

def load_local_shapefiles():
	pass







def connect_engine():

	# print "connecting to postgres server... ",
	engine = create_engine('postgresql://%s:%s@%s/%s' % (
		app.config['PG_NAME'],
		app.config['PG_PASS'],
		app.config['PG_HOST'],
		app.config['PG_DATABASE'],
	))
	engine.connect()
	return engine;

###### RUNNER

if __name__ == '__main__':
	port = int(sys.argv[1]) or None if len(sys.argv) > 1 else None
	app.run(
		debug=True,
		port=port
	)
