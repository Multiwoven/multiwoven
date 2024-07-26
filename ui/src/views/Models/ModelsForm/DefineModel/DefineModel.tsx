import { useContext } from 'react';
import { SteppedFormContext } from '@/components/SteppedForm/SteppedForm';
import DefineSQL from './DefineSQL';
import { DefineSQLProps } from './DefineSQL/types';
import { ModelMethodName } from '../ModelMethod/methods';
import TableSelector from './TableSelector';

const DefineModel = (props: DefineSQLProps): JSX.Element | null => {
  let selectedModelType;
  if (props.hasPrefilledValues) {
    selectedModelType = 'SQL Query';
  } else {
    const { state } = useContext(SteppedFormContext);
    const dataMethod = state.forms.find((data) => data.data?.selectModelType);
    selectedModelType = dataMethod?.data?.selectModelType;
  }

  switch (selectedModelType) {
    case ModelMethodName.SQLQuery:
      return <DefineSQL {...props} />;
    case ModelMethodName.TableSelector:
      return <TableSelector {...props} />;
    default:
      return <></>;
  }
};

export default DefineModel;
