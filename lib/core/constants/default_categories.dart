class DefaultCategoryIds {
  static const fixedExpense = 'fixed_expense';
  static const variableExpense = 'variable_expense';
  static const extraExpense = 'extra_expense';
  static const financingExpense = 'financing_expense';
}

class DefaultCategoryNames {
  static const fixedExpense = 'Despesa fixa';
  static const variableExpense = 'Despesa variável';
  static const extraExpense = 'Despesa extra';
  static const financingExpense = 'Financiamento';
}

class DefaultCategoryDefinition {
  final String id;
  final String name;
  final String type;

  const DefaultCategoryDefinition({
    required this.id,
    required this.name,
    required this.type,
  });
}

const defaultExpenseCategories = <DefaultCategoryDefinition>[
  DefaultCategoryDefinition(
    id: DefaultCategoryIds.fixedExpense,
    name: DefaultCategoryNames.fixedExpense,
    type: 'expense',
  ),
  DefaultCategoryDefinition(
    id: DefaultCategoryIds.variableExpense,
    name: DefaultCategoryNames.variableExpense,
    type: 'expense',
  ),
  DefaultCategoryDefinition(
    id: DefaultCategoryIds.extraExpense,
    name: DefaultCategoryNames.extraExpense,
    type: 'expense',
  ),
  DefaultCategoryDefinition(
    id: DefaultCategoryIds.financingExpense,
    name: DefaultCategoryNames.financingExpense,
    type: 'expense',
  ),
];