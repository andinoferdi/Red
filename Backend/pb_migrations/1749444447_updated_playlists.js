/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_976091127")

  // remove field
  collection.fields.removeById("relation3278218033")

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_976091127")

  // add field
  collection.fields.addAt(5, new Field({
    "cascadeDelete": false,
    "collectionId": "pbc_1906970480",
    "hidden": false,
    "id": "relation3278218033",
    "maxSelect": 1,
    "minSelect": 0,
    "name": "songs_id",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "relation"
  }))

  return app.save(collection)
})
