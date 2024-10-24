public abstract class ComparatorsConstants {

    public static final Map<Type, SortByFunction> COMPARABLE_TYPE_MAPPING = new Map<Type, SortByFunction> {
        String.class => new StringComparator(),
        Id.class => new StringComparator(),
        Decimal.class => new NumberComparator(),
        Double.class => new NumberComparator(),
        Integer.class => new NumberComparator(),
        Long.class => new NumberComparator(),
        Date.class => new DateComparator(),
        Datetime.class => new DateComparator()
    };
}
