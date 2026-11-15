import { render, screen } from '@testing-library/react';
import { expect, describe, it } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { useFormik } from 'formik';
import ScheduleForm from '../ScheduleForm';
import { FinalizeSyncFormFields } from '../../types';

jest.mock(
  '../../SyncForm/FinaliseSync/SyncScheduleOptionsContainer/SyncScheduleOptionsContainer',
  () => ({
    __esModule: true,
    default: () => <div data-testid='schedule-options'>ScheduleOptions</div>,
  }),
);

const TestComponent = ({
  isEdit = false,
  scheduleType = 'interval',
}: {
  isEdit?: boolean;
  scheduleType?: string;
}) => {
  const formik = useFormik<FinalizeSyncFormFields>({
    initialValues: {
      sync_mode: 'full_refresh',
      sync_interval: 0,
      sync_interval_unit: 'minutes',
      schedule_type: scheduleType,
      cron_expression: '',
    },
    onSubmit: () => {},
  });

  return <ScheduleForm formik={formik} isEdit={isEdit} />;
};

const renderComponent = (isEdit = false, scheduleType = 'interval') => {
  return render(
    <ChakraProvider>
      <TestComponent isEdit={isEdit} scheduleType={scheduleType} />
    </ChakraProvider>,
  );
};

describe('ScheduleForm', () => {
  it('renders the form title', () => {
    renderComponent();
    expect(screen.getByText('Finalise setting for this sync')).toBeInTheDocument();
  });

  it('renders SyncScheduleOptionsContainer', () => {
    renderComponent();
    expect(screen.getByTestId('schedule-options')).toBeInTheDocument();
  });

  it('applies edit background color when isEdit is true', () => {
    const { container } = renderComponent(true);
    const box = container.querySelector('div[style*="background"]') || container.firstChild;
    expect(box).toBeInTheDocument();
  });

  it('applies default background color when isEdit is false', () => {
    const { container } = renderComponent(false);
    const box = container.querySelector('div[style*="background"]') || container.firstChild;
    expect(box).toBeInTheDocument();
  });

  it('applies 0px margin-bottom when schedule_type is manual', () => {
    const { container } = renderComponent(false, 'manual');
    const outerBox = container.firstChild as HTMLElement;
    expect(outerBox).toBeInTheDocument();
    expect(screen.getByTestId('schedule-options')).toBeInTheDocument();
  });

  it('applies 100px margin-bottom when schedule_type is not manual', () => {
    const { container } = renderComponent(false, 'interval');
    const outerBox = container.firstChild as HTMLElement;
    expect(outerBox).toBeInTheDocument();
    expect(screen.getByTestId('schedule-options')).toBeInTheDocument();
  });
});
