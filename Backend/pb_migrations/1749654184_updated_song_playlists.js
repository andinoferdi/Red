/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_21065996")

  // update field
  collection.fields.addAt(1, new Field({
    "cascadeDelete": false,
    "collectionId": "pbc_1906970480",
    "hidden": false,
    "id": "relation3278218033",
    "maxSelect": 1,
    "minSelect": 0,
    "name": "song_id",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "relation"
  }))

  // update field
  collection.fields.addAt(2, new Field({
    "cascadeDelete": false,
    "collectionId": "pbc_976091127",
    "hidden": false,
    "id": "relation2674970454",
    "maxSelect": 1,
    "minSelect": 0,
    "name": "playlist_id",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "relation"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_21065996")

  // update field
  collection.fields.addAt(1, new Field({
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

  // update field
  collection.fields.addAt(2, new Field({
    "cascadeDelete": false,
    "collectionId": "pbc_976091127",
    "hidden": false,
    "id": "relation2674970454",
    "maxSelect": 1,
    "minSelect": 0,
    "name": "playlists_id",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "relation"
  }))

  return app.save(collection)
})
