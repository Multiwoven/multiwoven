import { Navigate, Route, Routes } from "react-router-dom";
import ModelsList from "./ModelsList";
import ModelsForm from "./ModelsForm";

const SetupModels = (): JSX.Element => {
  return (
    <Routes>
      <Route path="" element={<ModelsList />}>
        <Route path="new" element={<ModelsForm />} />
      </Route>
      <Route path="*" element={<Navigate to="" />} />
    </Routes>
  );
};

export default SetupModels;
