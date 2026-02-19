import { Dispatch, SetStateAction } from 'react';
import { SyncsConfigurationForTemplateMapping } from '@/views/Activate/Syncs/types';

export type TemplateMappingOptionsProps = {
  columnOptions: Column[];
  filterOptions: Column[];
  variableOptions: Column[];
  selectedTemplate: string;
  setSelectedTemplate: Dispatch<SetStateAction<string>>;
};

export enum OPTION_TYPE {
  COLUMNS = 'columns',
  VARIABLE = 'variable',
  FILTER = 'filter',
}

type Column = {
  name: string;
  description: string;
  value: string;
};

export type ColumnsProps = {
  columnOptions: Column[];
  fieldType: 'model' | 'destination';
  catalogMapping?: SyncsConfigurationForTemplateMapping;
  showFilter?: boolean;
  showDescription?: boolean;
  description?: string;
  onSelect?: (args: string) => void;
  height?: string;
  templateColumnType?: OPTION_TYPE;
};
