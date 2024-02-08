import { Navigate, Route, Routes } from "react-router-dom";
import SyncsList from "../Syncs/SyncsList";
import SyncForm from "../Syncs/SyncForm";

const SetupConnectors = (): JSX.Element => {
  return (
    <Routes>
      <Route path="syncs">
        <Route index element={<SyncsList />} />
        <Route path="new" element={<SyncForm />} />
      </Route>
      <Route path="*" element={<Navigate to="syncs" />} />
    </Routes>
  );
};

export default SetupConnectors;
