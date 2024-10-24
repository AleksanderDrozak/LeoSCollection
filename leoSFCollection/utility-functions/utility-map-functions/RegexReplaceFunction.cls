@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class RegexReplaceFunction implements MapFunction {

    String regExp;
    String replacement;

    public RegexReplaceFunction(String regExp, String replacement) {
        this.regExp = regExp;
        this.replacement = replacement;
    }

    public Object mapValue(Object obj) {
        return this.mapValue((String) obj);
    }

    public String mapValue(String text) {
        return text.replaceAll(this.regExp, this.replacement);
    }
}