import { Navigate, Route, Routes } from "react-router-dom";
import ModelsList from "./ModelsList";
import SourcesForm from "../Connectors/Sources/SourcesForm";

const SetupModels = (): JSX.Element => {
  return (
    <Routes>
      <Route path="" element={<ModelsList />}>
        <Route path="new" element={<SourcesForm />} />
      </Route>
      <Route path="*" element={<Navigate to="" />} />
    </Routes>
  );
};

export default SetupModels;
