## Example

```bash
curl 'https://firestore.googleapis.com/v1beta1/projects/tekartik-free-dev/databases/(default)/documents/tests/data-types'
```

```json
{
  "name": "projects/tekartik-free-dev/databases/(default)/documents/tests/data-types",
  "fields": {
    "refVal": {
      "referenceValue": "projects/tekartik-free-dev/databases/(default)/documents/users/23"
    },
    "geoVal": {
      "geoPointValue": {
        "latitude": 23.03,
        "longitude": 19.84
      }
    },
    "intVal": {
      "integerValue": "23"
    },
    "nestedVal": {
      "mapValue": {
        "fields": {
          "nestedKey": {
            "stringValue": "much nested"
          }
        }
      }
    },
    "boolVal": {
      "booleanValue": true
    },
    "tsVal": {
      "timestampValue": "2019-02-16T17:28:01.792Z"
    },
    "stringVal": {
      "stringValue": "text"
    },
    "listVal": {
      "arrayValue": {
        "values": [
          {
            "integerValue": "23"
          },
          {
            "integerValue": "84"
          }
        ]
      }
    },
    "complexVal": {
      "mapValue": {
        "fields": {
          "sub": {
            "arrayValue": {
              "values": [
                {
                  "mapValue": {
                    "fields": {
                      "subList": {
                        "arrayValue": {
                          "values": [
                            {
                              "integerValue": "1"
                            }
                          ]
                        }
                      }
                    }
                  }
                }
              ]
            }
          }
        }
      }
    },
    "serverTimestamp": {
      "timestampValue": "2019-02-16T17:28:01.905Z"
    },
    "blobVal": {
      "bytesValue": "AQID"
    },
    "doubleVal": {
      "doubleValue": 19.84
    }
  },
  "createTime": "2018-02-23T14:40:59.444924Z",
  "updateTime": "2019-02-16T17:28:01.986551Z"
}

```