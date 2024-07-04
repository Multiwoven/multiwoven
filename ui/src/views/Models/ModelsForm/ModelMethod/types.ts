import { ModelMethodName } from './methods';

export type ModelMethodType = {
  image: string;
  name: ModelMethodName;
  description: string;
  type: string;
  enabled: boolean;
};
