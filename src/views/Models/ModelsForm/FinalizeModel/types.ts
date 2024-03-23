import { ColumnMapType } from '@/utils/types';

export type SQLModel = {
  columns: Array<ColumnMapType>;
  id: string | number;
  query: string;
  query_type: string;
};

export type FinalizeForm = {
  modelName: string;
  description: string;
  primaryKey: string;
};

export type FinalizeModelProps = {
  hasPrefilledValues?: boolean;
  prefillValues?: FinalizeForm;
};
