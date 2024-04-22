export enum EntryKind {
  Keyword = 'Keyword',
  Function = 'Function',
  Snippet = 'Snippet',
  Class = 'Class',
}

type AutocompleteObject = {
  label: string;
  insertText: string;
  documentation: string;
  kind: EntryKind;
};

export const autocompleteEntries: Array<AutocompleteObject> = [
  {
    label: 'SELECT',
    insertText: 'SELECT',
    documentation: 'The SELECT statement is used to select data from a database.',
    kind: EntryKind.Keyword,
  },
  {
    label: 'FROM',
    insertText: 'FROM',
    documentation: 'Specifies the table from which to retrieve data.',
    kind: EntryKind.Keyword,
  },
  {
    label: 'WHERE',
    insertText: 'WHERE',
    documentation: 'Specifies the condition for filtering records.',
    kind: EntryKind.Keyword,
  },
  {
    label: 'LIKE',
    insertText: "LIKE '%${1}%'",
    documentation: 'Searches for a specified pattern in a column.',
    kind: EntryKind.Keyword,
  },
  {
    label: 'LIMIT',
    insertText: 'LIMIT',
    documentation: 'Constrains the number of rows returned.',
    kind: EntryKind.Keyword,
  },
  {
    label: 'ORDER BY',
    insertText: 'ORDER BY',
    documentation: 'Specifies the order in which to return rows.',
    kind: EntryKind.Keyword,
  },
  {
    label: 'GROUP BY',
    insertText: 'GROUP BY',
    documentation: 'Groups rows that have the same values in specified columns into summary rows.',
    kind: EntryKind.Keyword,
  },
  {
    label: 'UPDATE',
    insertText: 'UPDATE',
    documentation: 'Updates existing records in a table.',
    kind: EntryKind.Keyword,
  },
  {
    label: 'JOIN',
    insertText: 'JOIN',
    documentation: 'Used to join tables based on a related column between them.',
    kind: EntryKind.Keyword,
  },
  {
    label: 'LEFT JOIN',
    insertText: 'LEFT JOIN',
    documentation:
      'Returns all records from the left table and matched records from the right table.',
    kind: EntryKind.Keyword,
  },
  {
    label: 'RIGHT JOIN',
    insertText: 'RIGHT JOIN',
    documentation:
      'Returns all records from the right table and matched records from the left table.',
    kind: EntryKind.Keyword,
  },
  {
    label: 'INNER JOIN',
    insertText: 'INNER JOIN',
    documentation: 'Returns records that have matching values in both tables.',
    kind: EntryKind.Keyword,
  },
  {
    label: 'OUTER JOIN',
    insertText: 'OUTER JOIN',
    documentation: 'Returns all records when there is a match in either left or right table.',
    kind: EntryKind.Keyword,
  },
  {
    label: 'DISTINCT',
    insertText: 'DISTINCT',
    documentation: 'Selects only distinct (different) values.',
    kind: EntryKind.Keyword,
  },
  {
    label: 'COUNT',
    insertText: 'COUNT()',
    documentation: 'Returns the number of rows that matches a specified criterion.',
    kind: EntryKind.Function,
  },
  {
    label: 'SUM',
    insertText: 'SUM()',
    documentation: 'Returns the total sum of a numeric column.',
    kind: EntryKind.Function,
  },
  {
    label: 'MAX',
    insertText: 'MAX()',
    documentation: 'Returns the largest value of the selected column.',
    kind: EntryKind.Function,
  },
  {
    label: 'MIN',
    insertText: 'MIN()',
    documentation: 'Returns the smallest value of the selected column.',
    kind: EntryKind.Function,
  },
  {
    label: 'SERIAL',
    insertText: 'SERIAL',
    documentation: 'Auto-incrementing integer column.',
    kind: EntryKind.Keyword,
  },
  {
    label: 'ILIKE',
    insertText: 'ILIKE',
    documentation: 'Case-insensitive LIKE operation.',
    kind: EntryKind.Keyword,
  },
  {
    label: 'AUTO_INCREMENT',
    insertText: 'AUTO_INCREMENT',
    documentation: 'Auto-incrementing field for primary keys.',
    kind: EntryKind.Keyword,
  },
  {
    label: 'FIND',
    insertText: 'FIND',
    documentation: 'Used in SOSL queries to find matches in records.',
    kind: EntryKind.Keyword,
  },
];
