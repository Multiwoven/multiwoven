import { useState } from 'react';
import { Stream } from '@/views/Activate/Syncs/types';

import SelectModel from './SelectModel';
import SelectDestination from './SelectDestination';
import ConfigureSyncs from './ConfigureSyncs';
import FinaliseSync from './FinaliseSync';
import { FieldMap as FieldMapType } from '@/views/Activate/Syncs/types';
import { SchemaMode } from '@/views/Activate/Syncs/types';
import SteppedFormDrawer from '@/components/SteppedFormDrawer';

const SyncForm = (): JSX.Element => {
  const [selectedStream, setSelectedStream] = useState<Stream | null>(null);
  const [configuration, setConfiguration] = useState<FieldMapType[] | null>(null);
  const [schemaMode, setSchemaMode] = useState<SchemaMode | null>(null);
  const [selectedSyncMode, setSelectedSyncMode] = useState('');
  const [cursorField, setCursorField] = useState('');

  const steps = [
    {
      formKey: 'selectModel',
      name: 'Select a Model',
      component: <SelectModel />,
      isRequireContinueCta: false,
    },
    {
      formKey: 'selectDestination',
      name: 'Select a Destination',
      component: (
        <SelectDestination
          setSelectedStream={setSelectedStream}
          setConfiguration={setConfiguration}
        />
      ),
      isRequireContinueCta: false,
    },
    {
      formKey: 'configureSyncs',
      name: 'Configure Sync',
      component: (
        <ConfigureSyncs
          selectedStream={selectedStream}
          configuration={configuration}
          schemaMode={schemaMode}
          cursorField={cursorField}
          selectedSyncMode={selectedSyncMode}
          setSelectedStream={setSelectedStream}
          setConfiguration={setConfiguration}
          setSchemaMode={setSchemaMode}
          setSelectedSyncMode={setSelectedSyncMode}
          setCursorField={setCursorField}
        />
      ),
      isRequireContinueCta: false,
    },
    {
      formKey: 'finaliseSync',
      name: 'Finalize Sync',
      component: <FinaliseSync />,
      isRequireContinueCta: false,
    },
  ];

  return <SteppedFormDrawer steps={steps} />;
};

export default SyncForm;
