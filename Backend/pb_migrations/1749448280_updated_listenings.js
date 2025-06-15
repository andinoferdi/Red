/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_2234858796")

  // update collection data
  unmarshal({
    "name": "recent_plays"
  }, collection)

  // remove field
  collection.fields.removeById("relation2229126836")

  // remove field
  collection.fields.removeById("relation1782261251")

  // remove field
  collection.fields.removeById("relation2674970454")

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_2234858796")

  // update collection data
  unmarshal({
    "name": "listenings"
  }, collection)

  // add field
  collection.fields.addAt(1, new Field({
    "cascadeDelete": false,
    "collectionId": "pbc_2151843437",
    "hidden": false,
    "id": "relation2229126836",
    "maxSelect": 1,
    "minSelect": 0,
    "name": "favorites_id",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "relation"
  }))

  // add field
  collection.fields.addAt(2, new Field({
    "cascadeDelete": false,
    "collectionId": "pbc_2683869272",
    "hidden": false,
    "id": "relation1782261251",
    "maxSelect": 1,
    "minSelect": 0,
    "name": "genres_id",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "relation"
  }))

  // add field
  collection.fields.addAt(3, new Field({
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
