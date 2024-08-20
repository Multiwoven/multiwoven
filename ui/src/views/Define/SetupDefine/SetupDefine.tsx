import { Navigate, Route, Routes } from 'react-router-dom';
<<<<<<< HEAD:ui/src/views/Models/SetupModels.tsx
import ModelsList from './ModelsList';
import ModelsForm from './ModelsForm';
import ViewModel from './ViewModel';
import EditModel from './EditModel';
=======
import ModelsList from '@/views/Models/ModelsList';
import ModelsForm from '@/views/Models/ModelsForm';
import ViewModel from '@/views/Models/ViewModel';
import EditModel from '@/views/Models/EditModel';
import RoleAccess from '@/enterprise/components/RoleAccess';
import { UserActions } from '@/enterprise/types';
>>>>>>> 5038b91c (refactor(CE): changed setup models to setup define):ui/src/views/Define/SetupDefine/SetupDefine.tsx

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
