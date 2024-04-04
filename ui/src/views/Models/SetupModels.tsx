import { Navigate, Route, Routes } from 'react-router-dom';
import ModelsList from './ModelsList';
import ModelsForm from './ModelsForm';
import ViewModel from './ViewModel';
import EditModel from './EditModel';

const SetupModels = (): JSX.Element => {
  return (
    <Routes>
      <Route path='models'>
        <Route index element={<ModelsList />} />
        <Route path='new' element={<ModelsForm />} />
        <Route path=':id' element={<ViewModel />} />
        <Route path=':id/edit' element={<EditModel />} />
      </Route>
      <Route path='*' element={<Navigate to='models' />} />
    </Routes>
  );
};

export default SetupModels;
