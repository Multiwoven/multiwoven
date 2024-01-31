import { Navigate, Route, Routes } from "react-router-dom";
import ModelsList from "./ModelsList";
import ModelsForm from "./ModelsForm";
import ViewModel from "./ViewModel";
import EditModel from "./EditModel";

const SetupModels = (): JSX.Element => {
  return (
    <Routes>
      <Route path="/models" element={<ModelsList />}>
        <Route path="new" element={<ModelsForm />} />
        <Route path="*" element={<Navigate to="" />} />
      </Route>
      <Route path="/models/:id" element={<ViewModel />} />
      <Route path="/models/:id/edit" element={<EditModel />} />
    </Routes>
  );
};

export default SetupModels;
