/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_21065996")

  // add field
  collection.fields.addAt(3, new Field({
    "hidden": false,
    "id": "number4113142680",
    "max": null,
    "min": 1,
    "name": "order",
    "onlyInt": false,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_21065996")

  // remove field
  collection.fields.removeById("number4113142680")

  return app.save(collection)
})
