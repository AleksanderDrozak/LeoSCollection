@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class AccountWrapper implements WrapperFunction {

    private Account wrappedAccount;

    @SuppressWarnings('PMD.EmptyStatementBlock')
    global AccountWrapper() {
    }

    global AccountWrapper(Account wrappedAccount) {
        this.wrappedAccount = wrappedAccount;
    }

    global Object wrap(Object acc) {
        return new AccountWrapper((Account) acc);
    }
}