/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_2234858796")

  // add field
  collection.fields.addAt(1, new Field({
    "cascadeDelete": false,
    "collectionId": "_pb_users_auth_",
    "hidden": false,
    "id": "relation2809058197",
    "maxSelect": 1,
    "minSelect": 0,
    "name": "user_id",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "relation"
  }))

  // add field
  collection.fields.addAt(2, new Field({
    "hidden": false,
    "id": "select1156453330",
    "maxSelect": 1,
    "name": "item_type",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "select",
    "values": [
      "album",
      "artist",
      "playlist",
      "song"
    ]
  }))

  // add field
  collection.fields.addAt(3, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text309285470",
    "max": 0,
    "min": 0,
    "name": "item_id",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": true,
    "system": false,
    "type": "text"
  }))

  // add field
  collection.fields.addAt(4, new Field({
    "hidden": false,
    "id": "date775272694",
    "max": "",
    "min": "",
    "name": "last_played_at",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "date"
  }))

  // add field
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

  // remove field
  collection.fields.removeById("relation2809058197")

  // remove field
  collection.fields.removeById("select1156453330")

  // remove field
  collection.fields.removeById("text309285470")

  // remove field
  collection.fields.removeById("date775272694")

  // remove field
  collection.fields.removeById("number1946592222")

  return app.save(collection)
})
