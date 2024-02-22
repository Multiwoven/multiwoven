export type StepData = {
  step: number;
  data: any;
  stepKey: string;
};

export type ExtractedData = {
  id?: string;
  icon?: JSX.Element;
  name?: string;
};

export type PrefillValue = {
  connector_id: string;
  connector_name: string;
  connector_icon: JSX.Element;
  model_name: string;
  model_description: string;
  model_id: string;
  query: string;
  query_type: string;
  primary_key: string;
};

export type DefineSQLProps = {
  hasPrefilledValues?: boolean;
  prefillValues?: PrefillValue;
  isFooterVisible?: boolean;
  newQuery?: string;
  isUpdateButtonVisible: boolean;
  isAlignToContentContainer?: boolean;
};
