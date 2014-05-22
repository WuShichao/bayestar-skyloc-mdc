#!/usr/bin/env python

from __future__ import division

import sys
import math

n = int(sys.argv[1])
step = int(sys.argv[2])
coincfilename = sys.argv[3]
coincfilestem, _, _ = coincfilename.partition('.')

for i in range(int(math.ceil(n / step))):
	print """
JOB paginate_coincs_{i} paginate_coincs.sub
VARS paginate_coincs_{i} sql_file="paginate_coincs_{i}.sql" database="{coincfilestem}_{i}.sqlite"
SCRIPT PRE paginate_coincs_{i} paginate_coincs.pre {i} {step} {coincfilestem}.sqlite {coincfilestem}_{i}.sqlite
SCRIPT POST paginate_coincs_{i} paginate_coincs.post {i} $RETURN

JOB paginate_to_xml_{i} sqlite_to_xml.sub
VARS paginate_to_xml_{i} database="{coincfilestem}_{i}.sqlite" xml="{coincfilestem}_{i}.xml.gz"
SCRIPT POST paginate_to_xml_{i} sqlite_to_xml.post {coincfilestem}_{i}.sqlite $RETURN
PARENT paginate_coincs_{i} CHILD paginate_to_xml_{i}

JOB localize_coincs_{i} localize_coincs.sub
VARS localize_coincs_{i} xml="{coincfilestem}_{i}.xml.gz"
PARENT paginate_to_xml_{i} CHILD localize_coincs_{i}
""".format(i=i, step=step, coincfilestem=coincfilestem)
