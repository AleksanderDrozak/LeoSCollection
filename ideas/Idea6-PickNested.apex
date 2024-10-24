// Pick nested field function eg Account.CreatedBy.Name

Collection
    .transform(
        accounts,
        new PickByNestedFunction(Account.CreatedBy.Name) // or reuse if possible "PickByFieldFunction"
        )
.toList(String.class);