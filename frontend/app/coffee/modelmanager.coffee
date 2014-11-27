models = require './models'

class ModelManger

  ready: (callback) ->
    @$q.all @currentUser.$promise, @packs.$promise, @collections.$promise, @labels.$promise
      .then => callback()

  getPack: (id, callback) ->
    @ready =>
      for pack in @packs
        if pack.id == id
          icons = @$models.PackIcon.query pack: pack.id
          callback pack, icons
          return

  getCollection: (id, callback) ->
    @ready =>
      for collection in @collections
        if collection.id == id
          icons = @$models.CollectionIcon.query collection: collection.id
          callback collection, icons
          return

  getLabel: (id, callback) ->
    @ready =>
      label_info = @$models.Label.get id: id
      callback(label_info)

  getCollectionIcons: (collection) ->
    @$models.CollectionIcon.query collection: collection.id

  getRevisions: (callback) ->
    @$models.Revision.query (data) => callback(data)

  addPack: (pack, callback) ->
    newPack = new @$models.Pack pack
    newPack.$save =>
      @packs.push newPack
      callback newPack if callback

  deletePack: (pack) ->
    idx = @packs.indexOf pack
    @packs.splice(idx, 1)
    pack.$delete()

  addCollection: (collection, callback) ->
    newCollection = new @$models.Collection collection
    newCollection.$save =>
      @collections.push newCollection
      callback newCollection if callback

  addCollectionIcon: (icon, callback) ->
    newIcon = new @$models.CollectionIcon icon
    newIcon.$save =>
      callback newIcon if callback

  deleteCollection: (col) ->
    idx = @collections.indexOf col
    @collections.splice(idx, 1)
    col.$delete()

  getPackRevisions: (pack) ->
    return @$models.Revision.query ref_model:'pack', ref_id:pack.id

  getCollectionRevisions: (collection) ->
    return @$models.Revision.query ref_model:'collection', ref_id:collection.id

  refreshPacks: ->
    @$models.Pack.query (packs) =>
      angular.forEach packs, (newpack) =>
        for oldpack in @packs
          if oldpack.id == newpack.id
            angular.extend oldpack, newpack
            return
        @packs.push newpack

  refreshCollections: ->
    @$models.Collection.query (collections) =>
      angular.forEach collections, (newcol) =>
        for oldcol in @collections
          if oldcol.id == newcol.id
            angular.extend oldcol, newcol
            return
        @collections.push newcol

  constructor: (@$resource, @$q) ->
    @$models = models(@$resource)
    @currentUser = @$models.User.current()
    @packs = @$models.Pack.query()
    @collections = @$models.Collection.query()
    @labels = @$models.Label.query()


module.exports = ($resource, $q) =>
  new ModelManger($resource, $q)
