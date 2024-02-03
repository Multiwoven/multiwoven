import { Box } from "@chakra-ui/react";
import { Navigate, Route, Routes } from "react-router-dom";
import SyncsList from "./SyncsList";
import SyncForm from "./SyncForm";

const Syncs = (): JSX.Element => {
  return (
    <Box padding="20px">
      <Routes>
        <Route path="sources">
          <Route index element={<SyncsList />} />
          <Route path="new" element={<SyncForm />} />
        </Route>
        <Route path="*" element={<Navigate to="sources" />} />
      </Routes>
    </Box>
  );
};

export default Syncs;
