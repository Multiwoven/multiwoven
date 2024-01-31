import { Navigate, Route, Routes } from "react-router-dom";
import ModelsList from "./ModelsList";
import ModelsForm from "./ModelsForm";
import ViewModel from "./ViewModel";

const SetupModels = (): JSX.Element => {
  return (
    <Routes>
      <Route path="" element={<ModelsList />}>
        <Route path="new" element={<ModelsForm />} />
      </Route>
      <Route path=":id" element={<ViewModel />} />
      <Route path="*" element={<Navigate to="" />} />
    </Routes>
  );
};

export default SetupModels;
