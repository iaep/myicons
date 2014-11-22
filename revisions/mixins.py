from iconpacks.models import Pack
from iconcollections.models import Collection, CollectionIcon

from .models import Revision

def get_field_names(model):
    fields = model._meta.fields
    return [field.name for field in fields]

class RevisionMixin:
    fields = []
    exclude = []
    relations = []

    def serialize(self, obj):
        serialized = {}
        for name in self.fields:
            if name in self.exclude: continue
            val = getattr(obj, name)
            if name in self.relations:
                serialized[name] = val.id
            else:
                serialized[name] = val
        return serialized

    def serialize_delete(self, obj):
        return self.serialize(obj)

    def get_user(self):
        if self.request.user:
            return {
                'name': self.request.user.username,
                'email': self.request.user.email,
            }
        return {}

    def post_save(self, obj, created=False):
        serialized_obj = self.serialize(obj)
        if created:
            Revision.objects.create(
                action='create',
                model=self.revision_model,
                target_id=obj.id,
                target_name=obj.name,
                user=self.get_user(),
                snapshot=serialized_obj)
        else:
            Revision.objects.create(
                action='update',
                model=self.revision_model,
                target_id=obj.id,
                target_name=obj.name,
                user=self.get_user(),
                snapshot=serialized_obj)

    def pre_delete(self, obj):
        self._pre_delete_id = obj.id
        self._pre_delete_name = obj.name
        self._pre_delete_snapshot = self.serialize_delete(obj)
        
    def post_delete(self, obj):
        Revision.objects.create(
            action='delete',
            model=self.revision_model,
            target_id=self._pre_delete_id,
            target_name=self._pre_delete_name,
            user=self.get_user(),
            snapshot = self._pre_delete_snapshot)


class PackRevisionMixin(RevisionMixin):
    fields = get_field_names(Pack)
    revision_model = 'pack'

    def serialize_delete(self, obj):
        serialized = self.serialize(obj)
        serialized['icons'] = list(obj.icons.values())
        return serialized


class CollectionRevisionMixin(PackRevisionMixin):
    fields = get_field_names(Collection)
    exclude = ('token', )
    revision_model = 'collection'
    

class CollectionIconRevisionMixin(RevisionMixin):
    fields = get_field_names(CollectionIcon)
    exclude = ('packicon', )
    relations = ('collection', )
    revision_model = 'collectionicon'