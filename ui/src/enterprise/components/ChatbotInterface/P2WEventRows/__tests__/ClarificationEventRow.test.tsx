import { render, screen, fireEvent } from '@testing-library/react';
import { expect, describe, it } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import { ChakraProvider } from '@chakra-ui/react';
import ClarificationEventRow from '../ClarificationEventRow';
import type { FormField, P2WEventItem } from '../../p2wTypes';

const wrap = (ui: React.ReactElement) => render(<ChakraProvider>{ui}</ChakraProvider>);

const baseItem: P2WEventItem = {
  id: 'clar-1',
  kind: 'clarification',
  status: 'loading',
  startedAt: Date.now(),
  clarificationId: 'cid-1',
  clarificationQuestion: 'Which database should I use?',
  clarificationOptions: ['PostgreSQL', 'MySQL'],
  clarificationInputType: 'select',
  clarificationSensitive: false,
};

describe('ClarificationEventRow', () => {
  // ── resolved state ──────────────────────────────────────────────────────────

  describe('resolved state', () => {
    it('shows "Question answered"', () => {
      wrap(<ClarificationEventRow item={{ ...baseItem, status: 'resolved' }} />);
      expect(screen.getByText('Question answered')).toBeInTheDocument();
    });

    it('does not render the question card', () => {
      wrap(<ClarificationEventRow item={{ ...baseItem, status: 'resolved' }} />);
      expect(screen.queryByText('Which database should I use?')).not.toBeInTheDocument();
    });
  });

  // ── failed state ────────────────────────────────────────────────────────────

  describe('failed state', () => {
    it('shows "Execution stopped"', () => {
      wrap(<ClarificationEventRow item={{ ...baseItem, status: 'failed' }} />);
      expect(screen.getByText('Execution stopped')).toBeInTheDocument();
    });
  });

  // ── loading state (card open) ────────────────────────────────────────────────

  describe('loading state (interactive card)', () => {
    it('renders the clarification question', () => {
      wrap(<ClarificationEventRow item={baseItem} />);
      expect(screen.getByText('Which database should I use?')).toBeInTheDocument();
    });

    it('renders each predefined option', () => {
      wrap(<ClarificationEventRow item={baseItem} />);
      expect(screen.getByText('PostgreSQL')).toBeInTheDocument();
      expect(screen.getByText('MySQL')).toBeInTheDocument();
    });

    it('renders E2E data-testid selectors for select clarifications', () => {
      wrap(<ClarificationEventRow item={baseItem} onAnswer={jest.fn()} />);
      expect(screen.getByTestId('clarification-question')).toBeInTheDocument();
      expect(screen.getByTestId('clarification-options')).toBeInTheDocument();
      expect(screen.getAllByTestId('clarification-option')).toHaveLength(2);
      expect(screen.getByTestId('clarification-submit-btn')).toBeInTheDocument();
    });

    it('Submit button is disabled when no option is selected', () => {
      wrap(<ClarificationEventRow item={baseItem} onAnswer={jest.fn()} />);
      expect(screen.getByRole('button', { name: /submit/i })).toBeDisabled();
    });

    it('Reject button calls onReject with the clarificationId', () => {
      const onReject = jest.fn();
      wrap(<ClarificationEventRow item={baseItem} onReject={onReject} />);
      fireEvent.click(screen.getByRole('button', { name: /reject/i }));
      expect(onReject).toHaveBeenCalledWith('cid-1');
    });

    // ── keyboard submit ─────────────────────────────────────────────────────

    it('submits on Cmd+Enter in the free-text input', () => {
      const onAnswer = jest.fn();
      wrap(<ClarificationEventRow item={baseItem} onAnswer={onAnswer} />);
      const input = screen.getByPlaceholderText('Type your own answer');
      fireEvent.change(input, { target: { value: 'SQLite' } });
      fireEvent.keyDown(input, { key: 'Enter', metaKey: true });
      expect(onAnswer).toHaveBeenCalledWith('cid-1', 'SQLite');
    });

    it('submits on Ctrl+Enter in the free-text input', () => {
      const onAnswer = jest.fn();
      wrap(<ClarificationEventRow item={baseItem} onAnswer={onAnswer} />);
      const input = screen.getByPlaceholderText('Type your own answer');
      fireEvent.change(input, { target: { value: 'SQLite' } });
      fireEvent.keyDown(input, { key: 'Enter', ctrlKey: true });
      expect(onAnswer).toHaveBeenCalledWith('cid-1', 'SQLite');
    });

    // ── sensitive input ─────────────────────────────────────────────────────

    it('renders the free-text input as a password field when clarificationSensitive is true', () => {
      wrap(<ClarificationEventRow item={{ ...baseItem, clarificationSensitive: true }} />);
      expect(screen.getByPlaceholderText('Type your own answer')).toHaveAttribute(
        'type',
        'password',
      );
    });

    it('renders the free-text input as a text field when clarificationSensitive is false', () => {
      wrap(<ClarificationEventRow item={baseItem} />);
      expect(screen.getByPlaceholderText('Type your own answer')).toHaveAttribute('type', 'text');
    });

    // ── auto-select fix (regression for keyboard tab-then-type) ─────────────
    // When the user navigates to the free-text input via keyboard and starts
    // typing without triggering onFocus, onChange must still auto-select the
    // custom radio and enable the Submit button.

    it('enables Submit when user types in the free-text input without clicking the radio first', () => {
      const onAnswer = jest.fn();
      wrap(<ClarificationEventRow item={baseItem} onAnswer={onAnswer} />);
      const input = screen.getByPlaceholderText('Type your own answer');

      // Simulate typing without a preceding focus (the tab-then-type scenario).
      fireEvent.change(input, { target: { value: 'SQLite' } });

      // Submit button should now be enabled.
      expect(screen.getByRole('button', { name: /submit/i })).not.toBeDisabled();
    });

    it('calls onAnswer with the free-text value when Submit is clicked after typing', () => {
      const onAnswer = jest.fn();
      wrap(<ClarificationEventRow item={baseItem} onAnswer={onAnswer} />);
      const input = screen.getByPlaceholderText('Type your own answer');

      fireEvent.change(input, { target: { value: 'SQLite' } });
      fireEvent.click(screen.getByRole('button', { name: /submit/i }));

      expect(onAnswer).toHaveBeenCalledWith('cid-1', 'SQLite');
    });

    it('Submit remains disabled if the free-text input is only whitespace', () => {
      wrap(<ClarificationEventRow item={baseItem} onAnswer={jest.fn()} />);
      const input = screen.getByPlaceholderText('Type your own answer');
      fireEvent.change(input, { target: { value: '   ' } });
      expect(screen.getByRole('button', { name: /submit/i })).toBeDisabled();
    });

    // ── predefined radio selection ──────────────────────────────────────────

    it('enables Submit after clicking a predefined radio option', () => {
      wrap(<ClarificationEventRow item={baseItem} onAnswer={jest.fn()} />);
      // getAllByRole('radio') returns [PostgreSQL, MySQL, custom-input]
      const radios = screen.getAllByRole('radio');
      fireEvent.click(radios[0]); // select PostgreSQL
      expect(screen.getByRole('button', { name: /submit/i })).not.toBeDisabled();
    });

    it('calls onAnswer with the predefined option value on Submit', () => {
      const onAnswer = jest.fn();
      wrap(<ClarificationEventRow item={baseItem} onAnswer={onAnswer} />);
      const radios = screen.getAllByRole('radio');
      fireEvent.click(radios[0]); // select PostgreSQL
      fireEvent.click(screen.getByRole('button', { name: /submit/i }));
      expect(onAnswer).toHaveBeenCalledWith('cid-1', 'PostgreSQL');
    });

    it('clears typed input when a predefined radio is selected after typing', () => {
      const onAnswer = jest.fn();
      wrap(<ClarificationEventRow item={baseItem} onAnswer={onAnswer} />);
      const input = screen.getByPlaceholderText('Type your own answer');
      fireEvent.change(input, { target: { value: 'custom text' } });
      // Now select a predefined radio — handleRadioChange clears inputValue
      const radios = screen.getAllByRole('radio');
      fireEvent.click(radios[0]); // PostgreSQL
      fireEvent.click(screen.getByRole('button', { name: /submit/i }));
      // Should submit with PostgreSQL, not the typed custom text
      expect(onAnswer).toHaveBeenCalledWith('cid-1', 'PostgreSQL');
    });

    // ── onFocus path (explicit focus before typing) ─────────────────────────

    it('calls onAnswer via the onFocus-then-type path', () => {
      const onAnswer = jest.fn();
      wrap(<ClarificationEventRow item={baseItem} onAnswer={onAnswer} />);
      const input = screen.getByPlaceholderText('Type your own answer');
      // fireEvent.focus triggers onFocus → setSelectedOpt(CUSTOM_INPUT_VALUE)
      fireEvent.focus(input);
      // onChange fires; since selectedOpt is already CUSTOM_INPUT_VALUE, the
      // defensive fallback branch (lines 132-134) is skipped
      fireEvent.change(input, { target: { value: 'via focus' } });
      fireEvent.click(screen.getByRole('button', { name: /submit/i }));
      expect(onAnswer).toHaveBeenCalledWith('cid-1', 'via focus');
    });

    // ── loading prop ────────────────────────────────────────────────────────

    it('disables both buttons when isLoading is true', () => {
      wrap(<ClarificationEventRow item={baseItem} isLoading={true} />);
      expect(screen.getByRole('button', { name: /reject/i })).toBeDisabled();
      expect(screen.getByRole('button', { name: /submit/i })).toBeDisabled();
    });
  });

  // ── text input type (no options) ─────────────────────────────────────────────

  describe('text input type (no predefined options)', () => {
    const textItem: P2WEventItem = {
      id: 'clar-text',
      kind: 'clarification',
      status: 'loading',
      startedAt: Date.now(),
      clarificationId: 'cid-1',
      clarificationQuestion: 'Enter your API key',
      clarificationInputType: 'text',
    };

    it('renders a text input with "Type your answer" placeholder', () => {
      wrap(<ClarificationEventRow item={textItem} />);
      expect(screen.getByPlaceholderText('Type your answer')).toBeInTheDocument();
    });

    it('Submit is disabled when input is empty', () => {
      wrap(<ClarificationEventRow item={textItem} onAnswer={jest.fn()} />);
      expect(screen.getByRole('button', { name: /submit/i })).toBeDisabled();
    });

    it('calls onAnswer with the typed value on Submit', () => {
      const onAnswer = jest.fn();
      wrap(<ClarificationEventRow item={textItem} onAnswer={onAnswer} />);
      fireEvent.change(screen.getByPlaceholderText('Type your answer'), {
        target: { value: 'sk-my-key' },
      });
      fireEvent.click(screen.getByRole('button', { name: /submit/i }));
      expect(onAnswer).toHaveBeenCalledWith('cid-1', 'sk-my-key');
    });

    it('submits on Cmd+Enter', () => {
      const onAnswer = jest.fn();
      wrap(<ClarificationEventRow item={textItem} onAnswer={onAnswer} />);
      const input = screen.getByPlaceholderText('Type your answer');
      fireEvent.change(input, { target: { value: 'sk-my-key' } });
      fireEvent.keyDown(input, { key: 'Enter', metaKey: true });
      expect(onAnswer).toHaveBeenCalledWith('cid-1', 'sk-my-key');
    });
  });

  // ── single_option input type ─────────────────────────────────────────────────

  describe('single_option input type', () => {
    const singleItem: P2WEventItem = {
      id: 'clar-single',
      kind: 'clarification',
      status: 'loading',
      startedAt: Date.now(),
      clarificationId: 'cid-1',
      clarificationQuestion: 'Which model?',
      clarificationInputType: 'single_option',
      clarificationOptions: ['gpt-4o', 'claude-3'],
    };

    it('renders each option as a radio button', () => {
      wrap(<ClarificationEventRow item={singleItem} />);
      expect(screen.getByText('gpt-4o')).toBeInTheDocument();
      expect(screen.getByText('claude-3')).toBeInTheDocument();
    });

    it('does not render a free-text custom input', () => {
      wrap(<ClarificationEventRow item={singleItem} />);
      expect(screen.queryByPlaceholderText('Type your own answer')).not.toBeInTheDocument();
    });

    it('Submit is disabled when no option is selected', () => {
      wrap(<ClarificationEventRow item={singleItem} onAnswer={jest.fn()} />);
      expect(screen.getByRole('button', { name: /submit/i })).toBeDisabled();
    });

    it('enables Submit after selecting a radio option', () => {
      wrap(<ClarificationEventRow item={singleItem} onAnswer={jest.fn()} />);
      fireEvent.click(screen.getAllByRole('radio')[0]);
      expect(screen.getByRole('button', { name: /submit/i })).not.toBeDisabled();
    });

    it('calls onAnswer with the selected option string on Submit', () => {
      const onAnswer = jest.fn();
      wrap(<ClarificationEventRow item={singleItem} onAnswer={onAnswer} />);
      fireEvent.click(screen.getAllByRole('radio')[0]); // gpt-4o
      fireEvent.click(screen.getByRole('button', { name: /submit/i }));
      expect(onAnswer).toHaveBeenCalledWith('cid-1', 'gpt-4o');
    });
  });

  // ── multiple_option input type ───────────────────────────────────────────────

  describe('multiple_option input type', () => {
    const multiItem: P2WEventItem = {
      id: 'clar-multi',
      kind: 'clarification',
      status: 'loading',
      startedAt: Date.now(),
      clarificationId: 'cid-1',
      clarificationQuestion: 'Which permissions are needed?',
      clarificationInputType: 'multiple_option',
      clarificationOptions: ['Read', 'Write', 'Admin'],
    };

    it('renders each option as a checkbox', () => {
      wrap(<ClarificationEventRow item={multiItem} />);
      expect(screen.getByText('Read')).toBeInTheDocument();
      expect(screen.getByText('Write')).toBeInTheDocument();
      expect(screen.getByText('Admin')).toBeInTheDocument();
    });

    it('renders E2E data-testid selectors for multiple_option clarifications', () => {
      wrap(<ClarificationEventRow item={multiItem} />);
      expect(screen.getByTestId('clarification-options')).toBeInTheDocument();
      expect(screen.getAllByTestId('clarification-option')).toHaveLength(3);
    });

    it('Submit is disabled when nothing is checked', () => {
      wrap(<ClarificationEventRow item={multiItem} onAnswer={jest.fn()} />);
      expect(screen.getByRole('button', { name: /submit/i })).toBeDisabled();
    });

    it('enables Submit after checking at least one option', () => {
      wrap(<ClarificationEventRow item={multiItem} onAnswer={jest.fn()} />);
      fireEvent.click(screen.getAllByRole('checkbox')[0]); // Read
      expect(screen.getByRole('button', { name: /submit/i })).not.toBeDisabled();
    });

    it('calls onAnswer with an array of checked option labels on Submit', () => {
      const onAnswer = jest.fn();
      wrap(<ClarificationEventRow item={multiItem} onAnswer={onAnswer} />);
      fireEvent.click(screen.getAllByRole('checkbox')[0]); // Read
      fireEvent.click(screen.getAllByRole('checkbox')[2]); // Admin
      fireEvent.click(screen.getByRole('button', { name: /submit/i }));
      expect(onAnswer).toHaveBeenCalledWith('cid-1', ['Read', 'Admin']);
    });
  });

  // ── form_input input type ────────────────────────────────────────────────────

  describe('form_input input type', () => {
    const fields: FormField[] = [
      { name: 'host', label: 'Host', type: 'text', required: true },
      { name: 'port', label: 'Port', type: 'number', required: false, default: 5432 },
      { name: 'api_key', label: 'API Key', type: 'password', required: true },
    ];
    const formItem: P2WEventItem = {
      id: 'clar-form',
      kind: 'clarification',
      status: 'loading',
      startedAt: Date.now(),
      clarificationId: 'cid-1',
      clarificationQuestion: 'Configure the connector',
      clarificationInputType: 'form_input',
      clarificationFields: fields,
    };

    it('renders a label for each field', () => {
      wrap(<ClarificationEventRow item={formItem} />);
      expect(screen.getByText('Host')).toBeInTheDocument();
      expect(screen.getByText('Port')).toBeInTheDocument();
      expect(screen.getByText('API Key')).toBeInTheDocument();
    });

    it('renders the password field as type="password"', () => {
      const { container } = wrap(<ClarificationEventRow item={formItem} />);
      expect(container.querySelector('input[type="password"]')).toBeInTheDocument();
    });

    it('Submit is disabled when required fields are empty', () => {
      wrap(<ClarificationEventRow item={formItem} onAnswer={jest.fn()} />);
      expect(screen.getByRole('button', { name: /submit/i })).toBeDisabled();
    });

    it('calls onAnswer with a coerced hash on Submit when required fields are filled', () => {
      const onAnswer = jest.fn();
      const { container } = wrap(<ClarificationEventRow item={formItem} onAnswer={onAnswer} />);

      // Fill host (only text-role input in this form; port is spinbutton, api_key is password)
      const textInputs = screen.getAllByRole('textbox');
      fireEvent.change(textInputs[0], { target: { value: 'db.example.com' } });

      // Fill api_key (password input)
      const passwordInput = container.querySelector('input[type="password"]')!;
      fireEvent.change(passwordInput, { target: { value: 'secret-key' } });

      fireEvent.click(screen.getByRole('button', { name: /submit/i }));
      expect(onAnswer).toHaveBeenCalledWith('cid-1', {
        host: 'db.example.com',
        port: 5432, // number field with default 5432, coerced from string to number
        api_key: 'secret-key',
      });
    });
  });

  // ── wizard mode (questions[]) ────────────────────────────────────────────────

  describe('wizard mode', () => {
    const wizardItem: P2WEventItem = {
      id: 'clar-wizard',
      kind: 'clarification',
      status: 'loading',
      startedAt: Date.now(),
      clarificationId: 'cid-1',
      clarificationQuestion: 'Please configure the following:',
      clarificationQuestions: [
        { question: 'Which model?', inputType: 'text' },
        {
          question: 'Which region?',
          inputType: 'single_option',
          options: ['us-east-1', 'eu-west-1'],
        },
      ],
    };

    it('shows the step counter and first step question', () => {
      wrap(<ClarificationEventRow item={wizardItem} />);
      expect(screen.getByText('Which model?')).toBeInTheDocument();
      expect(screen.getByText('1 / 2')).toBeInTheDocument();
    });

    it('shows a Next button (not Submit) on the first step', () => {
      wrap(<ClarificationEventRow item={wizardItem} />);
      expect(screen.getByRole('button', { name: /next/i })).toBeInTheDocument();
      expect(screen.queryByRole('button', { name: /^submit$/i })).not.toBeInTheDocument();
    });

    it('does not show a Back button on the first step', () => {
      wrap(<ClarificationEventRow item={wizardItem} />);
      expect(screen.queryByRole('button', { name: /back/i })).not.toBeInTheDocument();
    });

    it('shows a Cancel button (not Reject)', () => {
      wrap(<ClarificationEventRow item={wizardItem} />);
      expect(screen.getByRole('button', { name: /cancel/i })).toBeInTheDocument();
      expect(screen.queryByRole('button', { name: /reject/i })).not.toBeInTheDocument();
    });

    it('advances to step 2 after answering step 1 and clicking Next', () => {
      wrap(<ClarificationEventRow item={wizardItem} />);
      fireEvent.change(screen.getByPlaceholderText('Type your answer'), {
        target: { value: 'gpt-4o' },
      });
      fireEvent.click(screen.getByRole('button', { name: /next/i }));
      expect(screen.getByText('Which region?')).toBeInTheDocument();
      expect(screen.getByText('2 / 2')).toBeInTheDocument();
    });

    it('shows Back and Submit on the last step', () => {
      wrap(<ClarificationEventRow item={wizardItem} />);
      fireEvent.change(screen.getByPlaceholderText('Type your answer'), {
        target: { value: 'gpt-4o' },
      });
      fireEvent.click(screen.getByRole('button', { name: /next/i }));
      expect(screen.getByRole('button', { name: /back/i })).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /submit/i })).toBeInTheDocument();
    });

    it('calls onAnswer with an array of all step answers on final Submit', () => {
      const onAnswer = jest.fn();
      wrap(<ClarificationEventRow item={wizardItem} onAnswer={onAnswer} />);

      // Step 1: fill text
      fireEvent.change(screen.getByPlaceholderText('Type your answer'), {
        target: { value: 'gpt-4o' },
      });
      fireEvent.click(screen.getByRole('button', { name: /next/i }));

      // Step 2: select radio
      fireEvent.click(screen.getAllByRole('radio')[0]); // us-east-1
      fireEvent.click(screen.getByRole('button', { name: /submit/i }));

      expect(onAnswer).toHaveBeenCalledWith('cid-1', ['gpt-4o', 'us-east-1']);
    });

    it('Cancel button calls onReject', () => {
      const onReject = jest.fn();
      wrap(<ClarificationEventRow item={wizardItem} onReject={onReject} />);
      fireEvent.click(screen.getByRole('button', { name: /cancel/i }));
      expect(onReject).toHaveBeenCalledWith('cid-1');
    });

    // ── Back navigation ─────────────────────────────────────────────────────

    it('navigates back to step 1 when Back is clicked on step 2', () => {
      wrap(<ClarificationEventRow item={wizardItem} />);
      fireEvent.change(screen.getByPlaceholderText('Type your answer'), {
        target: { value: 'gpt-4o' },
      });
      fireEvent.click(screen.getByRole('button', { name: /next/i }));
      fireEvent.click(screen.getByRole('button', { name: /back/i }));
      expect(screen.getByText('Which model?')).toBeInTheDocument();
      expect(screen.getByText('1 / 2')).toBeInTheDocument();
    });

    it('restores the typed text answer when navigating back to a text step', () => {
      wrap(<ClarificationEventRow item={wizardItem} />);
      fireEvent.change(screen.getByPlaceholderText('Type your answer'), {
        target: { value: 'gpt-4o' },
      });
      fireEvent.click(screen.getByRole('button', { name: /next/i }));
      fireEvent.click(screen.getByRole('button', { name: /back/i }));
      expect(screen.getByPlaceholderText('Type your answer')).toHaveValue('gpt-4o');
    });

    it('restores multiple_option selections when navigating back', () => {
      const multiFirstItem: P2WEventItem = {
        id: 'clar-wiz-m',
        kind: 'clarification',
        status: 'loading',
        startedAt: Date.now(),
        clarificationId: 'cid-1',
        clarificationQuestion: 'Configure:',
        clarificationQuestions: [
          {
            question: 'Permissions?',
            inputType: 'multiple_option',
            options: ['Read', 'Write', 'Admin'],
          },
          { question: 'Confirm?', inputType: 'text' },
        ],
      };
      wrap(<ClarificationEventRow item={multiFirstItem} />);
      fireEvent.click(screen.getAllByRole('checkbox')[0]); // Read
      fireEvent.click(screen.getAllByRole('checkbox')[2]); // Admin
      fireEvent.click(screen.getByRole('button', { name: /next/i }));
      fireEvent.click(screen.getByRole('button', { name: /back/i }));
      const boxes = screen.getAllByRole('checkbox');
      expect(boxes[0]).toBeChecked();
      expect(boxes[1]).not.toBeChecked();
      expect(boxes[2]).toBeChecked();
    });

    it('restores form_input values when navigating back to a form_input step', () => {
      const formFirstItem: P2WEventItem = {
        id: 'clar-wiz-f',
        kind: 'clarification',
        status: 'loading',
        startedAt: Date.now(),
        clarificationId: 'cid-1',
        clarificationQuestion: 'Configure:',
        clarificationQuestions: [
          {
            question: 'DB config',
            inputType: 'form_input',
            fields: [{ name: 'host', label: 'Host', type: 'text', required: true }],
          },
          { question: 'Confirm?', inputType: 'text' },
        ],
      };
      wrap(<ClarificationEventRow item={formFirstItem} />);
      fireEvent.change(screen.getByRole('textbox'), { target: { value: 'db.example.com' } });
      fireEvent.click(screen.getByRole('button', { name: /next/i }));
      fireEvent.click(screen.getByRole('button', { name: /back/i }));
      expect(screen.getByRole('textbox')).toHaveValue('db.example.com');
    });

    // ── captureStepAnswer branches ──────────────────────────────────────────

    it('captures multiple_option step answers and submits them in the wizard', () => {
      const onAnswer = jest.fn();
      const item: P2WEventItem = {
        id: 'clar-w',
        kind: 'clarification',
        status: 'loading',
        startedAt: Date.now(),
        clarificationId: 'cid-1',
        clarificationQuestion: 'Config:',
        clarificationQuestions: [
          { question: 'Permissions?', inputType: 'multiple_option', options: ['Read', 'Write'] },
          { question: 'Done?', inputType: 'text' },
        ],
      };
      wrap(<ClarificationEventRow item={item} onAnswer={onAnswer} />);
      fireEvent.click(screen.getAllByRole('checkbox')[0]); // Read
      fireEvent.click(screen.getByRole('button', { name: /next/i }));
      fireEvent.change(screen.getByPlaceholderText('Type your answer'), {
        target: { value: 'confirmed' },
      });
      fireEvent.click(screen.getByRole('button', { name: /submit/i }));
      expect(onAnswer).toHaveBeenCalledWith('cid-1', [['Read'], 'confirmed']);
    });

    it('captures form_input step answers and submits them in the wizard', () => {
      const onAnswer = jest.fn();
      const item: P2WEventItem = {
        id: 'clar-w',
        kind: 'clarification',
        status: 'loading',
        startedAt: Date.now(),
        clarificationId: 'cid-1',
        clarificationQuestion: 'Config:',
        clarificationQuestions: [
          {
            question: 'DB config',
            inputType: 'form_input',
            fields: [{ name: 'host', label: 'Host', type: 'text', required: true }],
          },
          { question: 'Done?', inputType: 'text' },
        ],
      };
      wrap(<ClarificationEventRow item={item} onAnswer={onAnswer} />);
      fireEvent.change(screen.getByRole('textbox'), { target: { value: 'db.example.com' } });
      fireEvent.click(screen.getByRole('button', { name: /next/i }));
      fireEvent.change(screen.getByPlaceholderText('Type your answer'), {
        target: { value: 'confirmed' },
      });
      fireEvent.click(screen.getByRole('button', { name: /submit/i }));
      expect(onAnswer).toHaveBeenCalledWith('cid-1', [{ host: 'db.example.com' }, 'confirmed']);
    });

    it('captures a select step predefined answer in the wizard', () => {
      const onAnswer = jest.fn();
      const item: P2WEventItem = {
        id: 'clar-w',
        kind: 'clarification',
        status: 'loading',
        startedAt: Date.now(),
        clarificationId: 'cid-1',
        clarificationQuestion: 'Config:',
        clarificationQuestions: [
          { question: 'Which DB?', inputType: 'select', options: ['PostgreSQL', 'MySQL'] },
          { question: 'Done?', inputType: 'text' },
        ],
      };
      wrap(<ClarificationEventRow item={item} onAnswer={onAnswer} />);
      fireEvent.click(screen.getAllByRole('radio')[0]); // PostgreSQL
      fireEvent.click(screen.getByRole('button', { name: /next/i }));
      fireEvent.change(screen.getByPlaceholderText('Type your answer'), {
        target: { value: 'confirmed' },
      });
      fireEvent.click(screen.getByRole('button', { name: /submit/i }));
      expect(onAnswer).toHaveBeenCalledWith('cid-1', ['PostgreSQL', 'confirmed']);
    });

    it('captures a select step custom answer in the wizard', () => {
      const onAnswer = jest.fn();
      const item: P2WEventItem = {
        id: 'clar-w',
        kind: 'clarification',
        status: 'loading',
        startedAt: Date.now(),
        clarificationId: 'cid-1',
        clarificationQuestion: 'Config:',
        clarificationQuestions: [
          { question: 'Which DB?', inputType: 'select', options: ['PostgreSQL', 'MySQL'] },
          { question: 'Done?', inputType: 'text' },
        ],
      };
      wrap(<ClarificationEventRow item={item} onAnswer={onAnswer} />);
      fireEvent.change(screen.getByPlaceholderText('Type your own answer'), {
        target: { value: 'SQLite' },
      });
      fireEvent.click(screen.getByRole('button', { name: /next/i }));
      fireEvent.change(screen.getByPlaceholderText('Type your answer'), {
        target: { value: 'confirmed' },
      });
      fireEvent.click(screen.getByRole('button', { name: /submit/i }));
      expect(onAnswer).toHaveBeenCalledWith('cid-1', ['SQLite', 'confirmed']);
    });
  });

  // ── form_input boolean and select field types ────────────────────────────────

  describe('form_input - boolean field type', () => {
    const makeBoolItem = (hint?: string): P2WEventItem => ({
      id: 'clar-bool',
      kind: 'clarification',
      status: 'loading',
      startedAt: Date.now(),
      clarificationId: 'cid-1',
      clarificationQuestion: 'Config',
      clarificationInputType: 'form_input',
      clarificationFields: [
        { name: 'ssl', label: 'Enable SSL', type: 'boolean', required: false, hint },
      ],
    });

    it('renders a Switch for a boolean field', () => {
      wrap(<ClarificationEventRow item={makeBoolItem()} />);
      expect(screen.getByText('Enable SSL')).toBeInTheDocument();
      expect(screen.getByRole('checkbox')).toBeInTheDocument();
    });

    it('toggles the Switch and submits the boolean value', () => {
      const onAnswer = jest.fn();
      wrap(<ClarificationEventRow item={makeBoolItem()} onAnswer={onAnswer} />);
      fireEvent.click(screen.getByRole('checkbox'));
      fireEvent.click(screen.getByRole('button', { name: /submit/i }));
      expect(onAnswer).toHaveBeenCalledWith('cid-1', { ssl: true });
    });

    it('renders hint text for a boolean field', () => {
      wrap(<ClarificationEventRow item={makeBoolItem('Enables TLS encryption')} />);
      expect(screen.getByText('Enables TLS encryption')).toBeInTheDocument();
    });
  });

  describe('form_input - select field type', () => {
    const makeSelectItem = (hint?: string): P2WEventItem => ({
      id: 'clar-sel',
      kind: 'clarification',
      status: 'loading',
      startedAt: Date.now(),
      clarificationId: 'cid-1',
      clarificationQuestion: 'Config',
      clarificationInputType: 'form_input',
      clarificationFields: [
        {
          name: 'region',
          label: 'Region',
          type: 'select',
          required: true,
          options: ['us-east-1', 'eu-west-1'],
          hint,
        },
      ],
    });

    it('renders a Select dropdown with its options', () => {
      wrap(<ClarificationEventRow item={makeSelectItem()} />);
      expect(screen.getByRole('combobox')).toBeInTheDocument();
      expect(screen.getByText('us-east-1')).toBeInTheDocument();
      expect(screen.getByText('eu-west-1')).toBeInTheDocument();
    });

    it('submits the chosen dropdown value', () => {
      const onAnswer = jest.fn();
      wrap(<ClarificationEventRow item={makeSelectItem()} onAnswer={onAnswer} />);
      fireEvent.change(screen.getByRole('combobox'), { target: { value: 'us-east-1' } });
      fireEvent.click(screen.getByRole('button', { name: /submit/i }));
      expect(onAnswer).toHaveBeenCalledWith('cid-1', { region: 'us-east-1' });
    });

    it('renders hint text for a select field', () => {
      wrap(<ClarificationEventRow item={makeSelectItem('Choose your cloud region')} />);
      expect(screen.getByText('Choose your cloud region')).toBeInTheDocument();
    });
  });
});
