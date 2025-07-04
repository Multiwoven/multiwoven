export { ConvertToTableData } from './ConvertToTableData';
export { extractData, extractDataByKey } from './ExtractDataFromJSON';
export { addIconDataToArray } from './addIconDataToArray';

import { format } from 'sql-formatter';

/**
 * Safely formats SQL queries, handling potential parsing errors
 * @param query The SQL query to format
 * @param options Formatting options for sql-formatter
 * @returns Formatted query or original query if formatting fails
 */
export const safeFormatSQL = (query: string, options?: any) => {
  try {
    // Check if the query contains any suspicious patterns that might cause formatting errors
    const hasUUID = /[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/i.test(query);
    
    // If the query contains patterns that might cause issues, return it unformatted
    if (hasUUID) {
      console.warn('Query contains UUID-like pattern, skipping formatting');
      return query;
    }
    
    // Attempt to format the query
    return format(query, options);
  } catch (error) {
    console.error('Error formatting SQL:', error);
    return query; // Return the original query if formatting fails
  }
};
