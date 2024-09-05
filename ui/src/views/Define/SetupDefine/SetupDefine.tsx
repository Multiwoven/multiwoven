import { Navigate, Route, Routes } from 'react-router-dom';
import ModelsList from '@/views/Models/ModelsList';
import ModelsForm from '@/views/Models/ModelsForm';
import ViewModel from '@/views/Models/ViewModel';
import EditModel from '@/views/Models/EditModel';

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
