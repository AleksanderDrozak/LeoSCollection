// catching errors Promise like way

class CustomTransformatorThatMayThrowError {
    class CustomException extends Excetpion { }
}

class CollectionExceptionHandler {
    onlyOfType
    public CollectionExceptionHandler(Type onlyOfType) {

    }
    public void handleException(Exception error) {

        if(onlyOfType != null){
            // handle error
            return; 
        }

        if(error instanceof onlyOfType){
            // handle error
            return; 
        }

        throw error;
    }
}

Collection.of(accounts)
.pipe(new List<Object> {
    new CustomTransformatorThatMayThrowError(),
})
.catch(CustomTransformatorThatMayThrowError.CustomException.class)