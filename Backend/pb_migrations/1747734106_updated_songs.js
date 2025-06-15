/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_1906970480")

  // update field
  collection.fields.addAt(5, new Field({
    "hidden": false,
    "id": "file3274582604",
    "maxSelect": 1,
    "maxSize": 10048576,
    "mimeTypes": [],
    "name": "audio_file",
    "presentable": false,
    "protected": false,
    "required": false,
    "system": false,
    "thumbs": [],
    "type": "file"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_1906970480")

  // update field
  collection.fields.addAt(5, new Field({
    "hidden": false,
    "id": "file3274582604",
    "maxSelect": 1,
    "maxSize": 1048576,
    "mimeTypes": [],
    "name": "audio_file",
    "presentable": false,
    "protected": false,
    "required": false,
    "system": false,
    "thumbs": [],
    "type": "file"
  }))

  return app.save(collection)
})
