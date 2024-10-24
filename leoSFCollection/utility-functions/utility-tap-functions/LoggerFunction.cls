@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class LoggerFunction implements Function {

    @SuppressWarnings('PMD.EmptyStatementBlock')
    global LoggerFunction() {
    }

    public void call(Object data) {
        System.debug('Logging data');
        System.debug(data);
    }

}