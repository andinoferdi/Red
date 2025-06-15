/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_976091127")

  // add field
  collection.fields.addAt(5, new Field({
    "hidden": false,
    "id": "json3136074139",
    "maxSize": 0,
    "name": "songs",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "json"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_976091127")

  // remove field
  collection.fields.removeById("json3136074139")

  return app.save(collection)
})
