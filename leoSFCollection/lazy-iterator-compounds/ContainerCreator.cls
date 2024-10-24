public without sharing class ContainerCreator {

    public List<Object> getList(Type dataType) {
        return (List<Object>) Type.forName('List<' + dataType.toString() + '>').newInstance();
    }

    public Set<Object> getSet(Type dataType) {
        return (Set<Object>) Type.forName('Set<' + dataType.toString() + '>').newInstance();
    }

    public Map<String, Object> getMap(Type keyType, Type dataType) {
        return (Map<String, Object>) Type.forName('Map<' + keyType.toString() + ',' + dataType.toString() + '>').newInstance();
    }

    public Map<String, List<Object>> getMapOfLists(Type keyType, Type dataType) {
        return (Map<String, List<Object>>) Type.forName('Map<' + keyType.toString() + ',List<' + dataType.toString() + '>>').newInstance();
    }
}