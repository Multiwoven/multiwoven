import SelectDestinations from './SelectDestinations';
import ConnectorConfigForm from '@/views/Connectors/ConnectorConfigForm';
import ConnectorConnectionTest from '@/views/Connectors/ConnectorConnectionTest';
import ConnectorFinaliseForm from '@/views/Connectors/ConnectorFinaliseForm';
import SteppedFormDrawer from '@/components/SteppedFormDrawer';

const DestinationsForm = (): JSX.Element => {
  const steps = [
    {
      formKey: 'destination',
      name: 'Select a Destination',
      component: <SelectDestinations />,
      isRequireContinueCta: false,
    },
    {
      formKey: 'destinationConfig',
      name: 'Connect your Destination',
      component: <ConnectorConfigForm connectorType='destination' />,
      isRequireContinueCta: false,
    },
    {
      formKey: 'testDestination',
      name: 'Test your Destination',
      component: <ConnectorConnectionTest connectorType='destination' />,
      isRequireContinueCta: false,
    },
    {
      formKey: 'finalizeDestination',
      name: 'Finalize your Destination',
      component: <ConnectorFinaliseForm connectorType='destination' />,
      isRequireContinueCta: false,
    },
  ];

  return <SteppedFormDrawer steps={steps} />;
};

export default DestinationsForm;
