/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_2234858796")

  // update field
  collection.fields.addAt(5, new Field({
    "hidden": false,
    "id": "number1946592222",
    "max": null,
    "min": 1,
    "name": "play_count",
    "onlyInt": false,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_2234858796")

  // update field
  collection.fields.addAt(5, new Field({
    "hidden": false,
    "id": "number1946592222",
    "max": null,
    "min": 0,
    "name": "play_count",
    "onlyInt": false,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }))

  return app.save(collection)
})
