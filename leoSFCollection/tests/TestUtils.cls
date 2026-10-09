@isTest
private class TestUtils {

    /**
     * A pipeline over no rows - what Collection.empty() used to give. The library ships no such seed any more, so
     * the tests that need one take it from here.
     */
    public static LazyIterator empty() {
        return Collection.of(new List<Object>());
    }
}
