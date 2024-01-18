import { Navigate, Route, Routes } from "react-router-dom";
import SourcesList from "../Sources/SourcesList";
import SourcesForm from "../Sources/SourcesForm";

const SetupConnectors = (): JSX.Element => {
  return (
    <Routes>
      <Route path="sources" element={<SourcesList />}>
        <Route path="new" element={<SourcesForm />} />
      </Route>
      <Route path="*" element={<Navigate to="sources" />} />
    </Routes>
  );
};

export default SetupConnectors;
