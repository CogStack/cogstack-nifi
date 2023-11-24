import traceback
from io import BytesIO
import sys
import os
import uuid
import json
import avro
from avro.datafile import DataFileReader, DataFileWriter
from avro.io import DatumReader, DatumWriter

from avro.schema import Schema

from pydoc import locate

records_stream = json.loads(sys.stdin.read())

schema = {
  "type": "record",
  "name": "inferAvro",
  "namespace":"org.apache.nifi",
  "fields": []
}

fields = list(records_stream[0].keys())

for field_name in fields:
     schema["fields"].append({"name": field_name, "type": ["null", { "type" : "long", "logicalType" : "timestamp-millis"}, "string"]})

avro_schema =  avro.schema.parse(json.dumps(schema))

file_id = str(uuid.uuid4().hex) 

tmp_file_path = os.path.join("/opt/nifi/user-scripts/tmp/" + file_id + ".avro")

with open(tmp_file_path, mode="wb+") as tmp_file:
    writer =  DataFileWriter(tmp_file, DatumWriter(), avro_schema)

    for _record in records_stream:
        writer.append(_record)

    writer.close()

tmp_file = open(tmp_file_path, "rb")

tmp_file_data = tmp_file.read()

tmp_file.close()

# delete file temporarly created above
if os.path.isfile(tmp_file_path):
    os.remove(tmp_file_path)

sys.stdout.buffer.write(tmp_file_data)