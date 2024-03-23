import { GetAllModelsResponse } from '@/services/models';

export function addIconDataToArray(array: GetAllModelsResponse[]): GetAllModelsResponse[] {
  array.map((item: any) => {
    item.attributes['icon'] = item.attributes.connector.icon;
  });
  return array;
}
