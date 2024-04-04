import { Navigate, Route, Routes } from 'react-router-dom';
import SourcesList from '../Sources/SourcesList';
import SourcesForm from '../Sources/SourcesForm';
import EditSource from '../Sources/EditSource';
import DestinationsList from '../Destinations/DestinationsList';
import DestinationsForm from '../Destinations/DestinationsForm';
import EditDestinations from '../Destinations/EditDestinations';

const SetupConnectors = (): JSX.Element => {
  return (
    <Routes>
      <Route path='sources'>
        <Route index element={<SourcesList />} />
        <Route path='new' element={<SourcesForm />} />
        <Route path=':sourceId' element={<EditSource />} />
        <Route path='*' element={<Navigate to='' />} />
      </Route>
      <Route path='destinations'>
        <Route index element={<DestinationsList />} />
        <Route path='new' element={<DestinationsForm />} />
        <Route path=':destinationId' element={<EditDestinations />} />
        <Route path='*' element={<Navigate to='' />} />
      </Route>
      <Route path='*' element={<Navigate to='sources' />} />
    </Routes>
  );
};

export default SetupConnectors;
