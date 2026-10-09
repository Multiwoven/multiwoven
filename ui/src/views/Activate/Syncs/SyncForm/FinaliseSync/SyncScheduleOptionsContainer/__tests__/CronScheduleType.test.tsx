import { render, screen, fireEvent } from '@testing-library/react';
import { expect, describe, it, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';

jest.mock('dayjs/plugin/utc', () => ({
  __esModule: true,
  default: () => {},
}));

jest.mock('dayjs/plugin/customParseFormat', () => ({
  __esModule: true,
  default: () => {},
}));

jest.mock('cron-validator', () => ({
  isValidCron: jest.fn((expr: string) => {
    const validExpressions = ['*/5 * * * *', '0 0 * * *', '0 12 * * MON-FRI'];
    return validExpressions.includes(expr);
  }),
}));

jest.mock('cron-parser', () => ({
  parseExpression: jest.fn(() => {
    let callCount = 0;
    return {
      next: () => {
        callCount++;
        const date = new Date(2024, 0, callCount, 12, 0, 0);
        return { value: date, done: false };
      },
    };
  }),
}));

import CronScheduleType from '../CronScheduleType';
import { useFormik, FormikProps } from 'formik';
import { FinalizeSyncFormFields } from '../../../../types';

type WrapperProps = {
  initialCron?: string;
};

const TestWrapper = ({ initialCron = '' }: WrapperProps) => {
  const formik: FormikProps<FinalizeSyncFormFields> = useFormik<FinalizeSyncFormFields>({
    initialValues: {
      sync_mode: 'full_refresh',
      sync_interval: 0,
      sync_interval_unit: 'minutes',
      schedule_type: 'cron_expression',
      cron_expression: '' as FinalizeSyncFormFields['cron_expression'],
    },
    onSubmit: () => {},
  });

  if (initialCron && formik.values.cron_expression === '') {
    formik.values.cron_expression = initialCron as FinalizeSyncFormFields['cron_expression'];
  }

  return (
    <ChakraProvider>
      <CronScheduleType formik={formik} />
    </ChakraProvider>
  );
};

const renderComponent = (props: WrapperProps = {}) => {
  return render(<TestWrapper {...props} />);
};

describe('CronScheduleType', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders the cron expression heading', () => {
    renderComponent();
    expect(screen.getByText('Cron Expression')).toBeInTheDocument();
  });

  it('renders cron input field', () => {
    renderComponent();
    const input = screen.getByPlaceholderText('Enter cron expression');
    expect(input).toBeInTheDocument();
  });

  it('accepts user input in the cron expression field', () => {
    renderComponent();
    const input = screen.getByPlaceholderText('Enter cron expression');
    fireEvent.change(input, { target: { value: '*/5 * * * *', name: 'cron_expression' } });
    expect(input).toHaveValue('*/5 * * * *');
  });

  it('shows invalid cron message for invalid expression', () => {
    renderComponent();
    const input = screen.getByPlaceholderText('Enter cron expression');
    fireEvent.change(input, { target: { value: 'invalid-cron', name: 'cron_expression' } });
    expect(screen.getByText('Invalid Cron Expression')).toBeInTheDocument();
  });

  it('does not show invalid message for valid cron expression', () => {
    renderComponent();
    const input = screen.getByPlaceholderText('Enter cron expression');
    fireEvent.change(input, { target: { value: '*/5 * * * *', name: 'cron_expression' } });
    expect(screen.queryByText('Invalid Cron Expression')).not.toBeInTheDocument();
  });

  it('shows next five sync runs for valid cron expression', () => {
    renderComponent({ initialCron: '*/5 * * * *' });
    expect(screen.getByText('The next five sync runs will trigger at:')).toBeInTheDocument();
  });

  it('does not show next runs when cron is empty', () => {
    renderComponent();
    expect(screen.queryByText('The next five sync runs will trigger at:')).not.toBeInTheDocument();
  });

  it('updates from invalid to valid expression', () => {
    renderComponent();
    const input = screen.getByPlaceholderText('Enter cron expression');

    fireEvent.change(input, { target: { value: 'bad', name: 'cron_expression' } });
    expect(screen.getByText('Invalid Cron Expression')).toBeInTheDocument();

    fireEvent.change(input, { target: { value: '0 0 * * *', name: 'cron_expression' } });
    expect(screen.queryByText('Invalid Cron Expression')).not.toBeInTheDocument();
  });
});
