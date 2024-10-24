@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class ConvertFunction implements MapFunction {

    private abstract class Transformer {
        protected Type targetType;
        protected Map<SObjectField, MapFunction> targetKeyToSourceMapFunction;

        protected Set<SObjectField> targetFields {
            get {

                if(this.targetFields == null) {
                    this.targetFields = this.targetKeyToSourceMapFunction.keySet();
                }

                return this.targetFields;
            }

            private set;
        }

        protected Transformer(Type targetType, Map<SObjectField, MapFunction> targetKeyToSourceMapFunction) {
            this.targetType = targetType;
            this.targetKeyToSourceMapFunction = targetKeyToSourceMapFunction;
        }

        protected MapFunction getMapFunction(SObjectField field) {
            return this.targetKeyToSourceMapFunction.get(field);
        }

        public abstract SObject transform(SObject sourceObject);
    }

    private class TransformByJson extends Transformer {

        public TransformByJson(Type targetType, Map<SObjectField, MapFunction> targetKeyToSourceMapFunction) {
            super(targetType, targetKeyToSourceMapFunction);
        }

        private Map<String, Object> getMappedValues(SObject sourceObject) {

            Map<String, Object> mappedValues = new Map<String, Object>();

            for(SObjectField field: this.targetFields) {
                mappedValues.put(
                    String.valueOf(field),
                    this.getMapFunction(field).mapValue(sourceObject)
                );
            }

            return mappedValues;
        }

        public override SObject transform(SObject sourceObject) {
            return (SObject) JSON.deserialize(
                JSON.serialize(this.getMappedValues(sourceObject)),
                this.targetType
            );
        }
    }

    private class TransformBySobject extends Transformer {

        public TransformBySobject(Type targetType, Map<SObjectField, MapFunction> targetKeyToSourceMapFunction) {
            super(targetType, targetKeyToSourceMapFunction);
        }

        private SObject getNewMappedInstance(SObject sourceObject) {

            SObject targetObject = (SObject) this.targetType.newInstance();

            for(SObjectField field : this.targetFields) {
                targetObject.put(
                    field,
                    this.getMapFunction(field).mapValue(sourceObject)
                );
            }

            return targetObject;
        }

        public override SObject transform(SObject sourceObject) {
            return this.getNewMappedInstance(sourceObject);
        }
    }

    private Transformer transformer;

    global ConvertFunction(Type targetType, Map<SObjectField, SObjectField> targetKeyToSourceField) {
        this(targetType, targetKeyToSourceField, true);
    }

    global ConvertFunction(Type targetType, Map<SObjectField, SObjectField> targetKeyToSourceField, Boolean isTypeSafeTransform) {
        this(targetType, getMappingsToFunction(targetKeyToSourceField), isTypeSafeTransform);
    }

    global ConvertFunction(Type targetType, Map<SObjectField, MapFunction> targetKeyToSourceMapFunction) {
        this(targetType, targetKeyToSourceMapFunction, true);
    }

    global ConvertFunction(Type targetType, Map<SObjectField, MapFunction> targetKeyToSourceMapFunction, Boolean isTypeSafeTransform) {
        this.transformer = isTypeSafeTransform ?
                           (Transformer) new TransformByJson(targetType, targetKeyToSourceMapFunction) :
                           (Transformer) new TransformBySobject(targetType, targetKeyToSourceMapFunction);
    }

    private static Map<SObjectField, MapFunction> getMappingsToFunction(Map<SObjectField, SObjectField> targetKeyToSourceField) {

        Map<SObjectField, MapFunction> functionsMap = new Map<SObjectField, MapFunction>();

        for(SObjectField field : targetKeyToSourceField.keySet()) {
            functionsMap.put(field, new PickByFieldFunction(targetKeyToSourceField.get(field)));
        }

        return functionsMap;
    }

    global Object mapValue(Object sourceObject) {
        return this.transformer.transform((SObject) sourceObject);
    }
}