import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { expect, describe, it, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import A2ASkillsSection from '../A2ASkillsSection';
// ---- mock functions ----
const mockSetSelectedComponent = jest.fn();
const mockSetWorkflow = jest.fn();
const mockUpdateNodeById = jest.fn();

// ---- mock state ----
let mockSelectedComponent: Record<string, unknown> | null = null;
let mockCurrentWorkflow: Record<string, unknown> | null = null;

jest.mock('@/enterprise/store/useAgentStore', () => ({
  __esModule: true,
  default: (selector: (state: Record<string, unknown>) => unknown) =>
    selector({
      currentWorkflow: mockCurrentWorkflow,
      selectedComponent: mockSelectedComponent,
      setSelectedComponent: mockSetSelectedComponent,
      setWorkflow: mockSetWorkflow,
      updateNodeById: mockUpdateNodeById,
    }),
}));

// ---- mock toast ----
const mockToast = jest.fn();
jest.mock('@/hooks/useCustomToast', () => ({
  __esModule: true,
  default: () => mockToast,
}));

// ---- mock mutations ----
const mockMutateAsync = jest.fn();
let mockIsPending = false;
jest.mock('@/enterprise/hooks/mutations/useAgentMutations', () => ({
  __esModule: true,
  default: () => ({
    fetchAgentCard: {
      mutateAsync: mockMutateAsync,
      // Use a getter so we can change isPending between render and click
      get isPending() {
        return mockIsPending;
      },
    },
  }),
}));

// ---- mock icons ----
jest.mock('react-icons/fi');

// ---- mock ToolTip ----
jest.mock('@/components/ToolTip', () => ({
  __esModule: true,
  default: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}));

// ---- Emotion CSS helper ----
/** Collect all Emotion-injected CSS text from the document */
const getEmotionCSS = (): string => {
  const tags = document.querySelectorAll('style[data-emotion]');
  return Array.from(tags)
    .map((t) => t.textContent ?? '')
    .join('\n');
};

/** Return all Emotion CSS rule blocks that reference the given class name */
const getCSSRulesForClass = (className: string): string[] => {
  const css = getEmotionCSS();
  const escaped = className.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const regex = new RegExp(`\\.${escaped}[^{]*\\{[^}]*\\}`, 'g');
  return css.match(regex) ?? [];
};

/** Return only base (non-pseudo-selector) CSS rules for the given class name */
const getBaseCSSRulesForClass = (className: string): string[] => {
  const rules = getCSSRulesForClass(className);
  return rules.filter(
    (r) =>
      !r.includes(':hover') &&
      !r.includes(':focus') &&
      !r.includes(':active') &&
      !r.includes(':disabled'),
  );
};

// ---- helpers ----
const queryClient = new QueryClient({
  defaultOptions: { queries: { retry: false } },
});

const renderComponent = () =>
  render(
    <ChakraProvider>
      <QueryClientProvider client={queryClient}>
        <A2ASkillsSection />
      </QueryClientProvider>
    </ChakraProvider>,
  );

const makeComponent = (overrides: Record<string, unknown> = {}) => ({
  id: 'a2a-1',
  data: { component: 'a2a_agent', label: 'A2A' },
  configuration: {},
  ...overrides,
});

const SKILLS = [
  { id: 's1', name: 'Skill One', description: 'First skill' },
  { id: 's2', name: 'Skill Two', description: 'Second skill' },
];

beforeEach(() => {
  jest.clearAllMocks();
  queryClient.clear();
  mockIsPending = false;
  mockSelectedComponent = makeComponent();
});

describe('A2ASkillsSection', () => {
  describe('Rendering', () => {
    it('renders the Agent Endpoint URL label', () => {
      renderComponent();
      expect(screen.getByText('Agent Endpoint URL')).toBeInTheDocument();
    });

    it('renders the URL input with placeholder', () => {
      renderComponent();
      expect(screen.getByPlaceholderText('https://my-agent.example.com')).toBeInTheDocument();
    });

    it('renders the API Key / Auth token label', () => {
      renderComponent();
      expect(screen.getByText('API Key / Auth token')).toBeInTheDocument();
    });

    it('renders the API key input with placeholder', () => {
      renderComponent();
      expect(screen.getByPlaceholderText('••••••••••••••••••••')).toBeInTheDocument();
    });

    it('renders the connect button with correct text when no skills loaded', () => {
      renderComponent();
      expect(screen.getByText('Connect & Load Skills')).toBeInTheDocument();
    });

    it('exposes stable data-testid attributes on URL input, API key input, and connect button', () => {
      renderComponent();
      expect(screen.getByTestId('workflow-config-a2a-endpoint-url-input')).toBeInTheDocument();
      expect(screen.getByTestId('workflow-config-a2a-api-key-input')).toBeInTheDocument();
      expect(screen.getByTestId('workflow-config-a2a-connect-skills-button')).toBeInTheDocument();
    });

    it('does not show skills section when no skills are loaded', () => {
      renderComponent();
      expect(screen.queryByText('Skills')).not.toBeInTheDocument();
      expect(screen.queryByText('(read only)')).not.toBeInTheDocument();
    });

    it('renders URL input value from configuration', () => {
      mockSelectedComponent = makeComponent({
        configuration: { url: 'https://example.com/agent' },
      });
      renderComponent();
      const input = screen.getByPlaceholderText('https://my-agent.example.com') as HTMLInputElement;
      expect(input.value).toBe('https://example.com/agent');
    });

    it('renders empty string for URL when config.url is undefined', () => {
      mockSelectedComponent = makeComponent({ configuration: {} });
      renderComponent();
      const input = screen.getByPlaceholderText('https://my-agent.example.com') as HTMLInputElement;
      expect(input.value).toBe('');
    });

    it('renders API key value from configuration', () => {
      mockSelectedComponent = makeComponent({
        configuration: { api_key: 'secret-key-123' },
      });
      renderComponent();
      const input = screen.getByPlaceholderText('••••••••••••••••••••') as HTMLInputElement;
      expect(input.value).toBe('secret-key-123');
    });

    it('renders empty string for api_key when config.api_key is undefined', () => {
      mockSelectedComponent = makeComponent({ configuration: {} });
      renderComponent();
      const input = screen.getByPlaceholderText('••••••••••••••••••••') as HTMLInputElement;
      expect(input.value).toBe('');
    });
  });

  // ---- URL Input Behavior ----
  describe('URL Input', () => {
    it('calls updateConfig when URL input changes', () => {
      renderComponent();
      const input = screen.getByPlaceholderText('https://my-agent.example.com');
      fireEvent.change(input, { target: { value: 'https://new-agent.com' } });
      expect(mockSetSelectedComponent).toHaveBeenCalled();
      expect(mockUpdateNodeById).toHaveBeenCalled();
    });

    it('passes updated URL in the configuration patch', () => {
      renderComponent();
      const input = screen.getByPlaceholderText('https://my-agent.example.com');
      fireEvent.change(input, { target: { value: 'https://new-agent.com' } });

      const calledWith = mockSetSelectedComponent.mock.calls[0][0];
      expect(calledWith.configuration.url).toBe('https://new-agent.com');
    });
  });

  // ---- API Key Input Behavior ----
  describe('API Key Input', () => {
    it('defaults to password type (hidden)', () => {
      renderComponent();
      const input = screen.getByPlaceholderText('••••••••••••••••••••') as HTMLInputElement;
      expect(input.type).toBe('password');
    });

    it('toggles to visible text type when visibility button is clicked', () => {
      renderComponent();
      const input = screen.getByPlaceholderText('••••••••••••••••••••') as HTMLInputElement;
      const toggleBtn = screen.getByLabelText('Show token');
      fireEvent.click(toggleBtn);
      expect(input.type).toBe('text');
      // Verify it is specifically 'text', not just truthy
      expect(input.type).not.toBe('');
      expect(input.type).toHaveLength(4);
    });

    it('toggles back to password type when clicked again', () => {
      renderComponent();
      const input = screen.getByPlaceholderText('••••••••••••••••••••') as HTMLInputElement;
      const toggleBtn = screen.getByLabelText('Show token');
      fireEvent.click(toggleBtn);
      expect(input.type).toBe('text');

      const hideBtn = screen.getByLabelText('Hide token');
      fireEvent.click(hideBtn);
      expect(input.type).toBe('password');
    });

    it('calls updateConfig when API key input changes', () => {
      renderComponent();
      const input = screen.getByPlaceholderText('••••••••••••••••••••');
      fireEvent.change(input, { target: { value: 'my-api-key' } });
      expect(mockSetSelectedComponent).toHaveBeenCalled();

      const calledWith = mockSetSelectedComponent.mock.calls[0][0];
      expect(calledWith.configuration.api_key).toBe('my-api-key');
    });
  });

  // ---- Connect Button ----
  describe('Connect button', () => {
    it('is disabled when URL is empty', () => {
      mockSelectedComponent = makeComponent({ configuration: { url: '' } });
      renderComponent();
      const btn = screen.getByText('Connect & Load Skills').closest('button')!;
      expect(btn).toBeDisabled();
    });

    it('is disabled when URL is only whitespace', () => {
      mockSelectedComponent = makeComponent({ configuration: { url: '   ' } });
      renderComponent();
      const btn = screen.getByText('Connect & Load Skills').closest('button')!;
      expect(btn).toBeDisabled();
    });

    it('is enabled when URL has a value', () => {
      mockSelectedComponent = makeComponent({
        configuration: { url: 'https://agent.example.com' },
      });
      renderComponent();
      const btn = screen.getByText('Connect & Load Skills').closest('button')!;
      expect(btn).not.toBeDisabled();
    });

    it('shows "Refresh Skills" when skills are already loaded', () => {
      mockSelectedComponent = makeComponent({
        configuration: {
          url: 'https://agent.example.com',
          skills: SKILLS,
        },
      });
      renderComponent();
      expect(screen.getByText('Refresh Skills')).toBeInTheDocument();
    });

    it('shows loading text when fetchAgentCard is pending', () => {
      mockIsPending = true;
      mockSelectedComponent = makeComponent({
        configuration: { url: 'https://agent.example.com' },
      });
      renderComponent();
      expect(screen.getByText('Connecting...')).toBeInTheDocument();
    });
  });

  // ---- handleConnect logic ----
  describe('handleConnect', () => {
    it('trims URL before sending in the payload', async () => {
      mockSelectedComponent = makeComponent({
        configuration: { url: '  https://agent.example.com  ' },
      });
      mockMutateAsync.mockResolvedValueOnce({
        connection_status: { status: 'succeeded', message: 'OK' },
        skills: SKILLS,
      });

      renderComponent();
      fireEvent.click(screen.getByText('Connect & Load Skills').closest('button')!);

      await waitFor(() => {
        expect(mockMutateAsync).toHaveBeenCalledWith({
          connection_spec: { url: 'https://agent.example.com' },
        });
      });
    });

    it('trims api_key before sending in the payload', async () => {
      mockSelectedComponent = makeComponent({
        configuration: { url: 'https://agent.example.com', api_key: '  my-key  ' },
      });
      mockMutateAsync.mockResolvedValueOnce({
        connection_status: { status: 'succeeded', message: 'OK' },
        skills: SKILLS,
      });

      renderComponent();
      fireEvent.click(screen.getByText('Connect & Load Skills').closest('button')!);

      await waitFor(() => {
        expect(mockMutateAsync).toHaveBeenCalledWith({
          connection_spec: { url: 'https://agent.example.com', api_key: 'my-key' },
        });
      });
    });

    it('calls mutateAsync with correct payload (URL only, no API key)', async () => {
      mockSelectedComponent = makeComponent({
        configuration: { url: 'https://agent.example.com' },
      });
      mockMutateAsync.mockResolvedValueOnce({
        connection_status: { status: 'succeeded', message: 'OK' },
        agent_card: { name: 'Agent' },
        skills: SKILLS,
      });

      renderComponent();
      const btn = screen.getByText('Connect & Load Skills').closest('button')!;
      fireEvent.click(btn);

      await waitFor(() => {
        expect(mockMutateAsync).toHaveBeenCalledWith({
          connection_spec: { url: 'https://agent.example.com' },
        });
      });
    });

    it('calls mutateAsync with API key when provided', async () => {
      mockSelectedComponent = makeComponent({
        configuration: { url: 'https://agent.example.com', api_key: 'my-key' },
      });
      mockMutateAsync.mockResolvedValueOnce({
        connection_status: { status: 'succeeded', message: 'OK' },
        skills: SKILLS,
      });

      renderComponent();
      const btn = screen.getByText('Connect & Load Skills').closest('button')!;
      fireEvent.click(btn);

      await waitFor(() => {
        expect(mockMutateAsync).toHaveBeenCalledWith({
          connection_spec: { url: 'https://agent.example.com', api_key: 'my-key' },
        });
      });
    });

    it('does not include api_key in payload when api_key is only whitespace', async () => {
      mockSelectedComponent = makeComponent({
        configuration: { url: 'https://agent.example.com', api_key: '   ' },
      });
      mockMutateAsync.mockResolvedValueOnce({
        connection_status: { status: 'succeeded', message: 'OK' },
        skills: SKILLS,
      });

      renderComponent();
      const btn = screen.getByText('Connect & Load Skills').closest('button')!;
      fireEvent.click(btn);

      await waitFor(() => {
        expect(mockMutateAsync).toHaveBeenCalledWith({
          connection_spec: { url: 'https://agent.example.com' },
        });
      });
    });

    it('shows success toast on successful connection', async () => {
      mockSelectedComponent = makeComponent({
        configuration: { url: 'https://agent.example.com' },
      });
      mockMutateAsync.mockResolvedValueOnce({
        connection_status: { status: 'succeeded', message: 'All good' },
        agent_card: { name: 'Agent' },
        skills: SKILLS,
      });

      renderComponent();
      fireEvent.click(screen.getByText('Connect & Load Skills').closest('button')!);

      await waitFor(() => {
        expect(mockToast).toHaveBeenCalledWith(
          expect.objectContaining({
            title: 'Connected successfully',
            description: 'All good',
            status: 'success',
          }),
        );
      });
    });

    it('uses default success message when connection_status message is missing', async () => {
      mockSelectedComponent = makeComponent({
        configuration: { url: 'https://agent.example.com' },
      });
      mockMutateAsync.mockResolvedValueOnce({
        connection_status: { status: 'succeeded' },
        skills: SKILLS,
      });

      renderComponent();
      fireEvent.click(screen.getByText('Connect & Load Skills').closest('button')!);

      await waitFor(() => {
        expect(mockToast).toHaveBeenCalledWith(
          expect.objectContaining({
            title: 'Connected successfully',
            description: 'Agent skills loaded successfully.',
          }),
        );
      });
    });

    it('updates config with agent_card and skills on success', async () => {
      const agentCard = { name: 'Test Agent', description: 'An agent' };
      mockSelectedComponent = makeComponent({
        configuration: { url: 'https://agent.example.com' },
      });
      mockMutateAsync.mockResolvedValueOnce({
        connection_status: { status: 'succeeded', message: 'OK' },
        agent_card: agentCard,
        skills: SKILLS,
      });

      renderComponent();
      fireEvent.click(screen.getByText('Connect & Load Skills').closest('button')!);

      await waitFor(() => {
        expect(mockSetSelectedComponent).toHaveBeenCalled();
        const updatedComp = mockSetSelectedComponent.mock.calls[0][0];
        expect(updatedComp.configuration.agent_card).toEqual(agentCard);
        expect(updatedComp.configuration.skills).toEqual(SKILLS);
        expect(updatedComp.configuration.url).toBe('https://agent.example.com');
      });
    });

    it('falls back to agent_card.skills when top-level skills is absent', async () => {
      const agentCard = { name: 'Agent', skills: SKILLS };
      mockSelectedComponent = makeComponent({
        configuration: { url: 'https://agent.example.com' },
      });
      mockMutateAsync.mockResolvedValueOnce({
        connection_status: { status: 'succeeded', message: 'OK' },
        agent_card: agentCard,
      });

      renderComponent();
      fireEvent.click(screen.getByText('Connect & Load Skills').closest('button')!);

      await waitFor(() => {
        expect(mockSetSelectedComponent).toHaveBeenCalled();
        const updatedComp = mockSetSelectedComponent.mock.calls[0][0];
        expect(updatedComp.configuration.skills).toEqual(SKILLS);
      });
    });

    it('shows error toast when connection_status is failed', async () => {
      mockSelectedComponent = makeComponent({
        configuration: { url: 'https://agent.example.com' },
      });
      mockMutateAsync.mockResolvedValueOnce({
        connection_status: { status: 'failed', message: 'Auth failed' },
      });

      renderComponent();
      fireEvent.click(screen.getByText('Connect & Load Skills').closest('button')!);

      await waitFor(() => {
        expect(mockToast).toHaveBeenCalledWith(
          expect.objectContaining({
            title: 'Connection failed',
            description: 'Auth failed',
            status: 'error',
          }),
        );
      });
    });

    it('handles response with no connection_status gracefully and shows success toast', async () => {
      mockSelectedComponent = makeComponent({
        configuration: { url: 'https://agent.example.com' },
      });
      mockMutateAsync.mockResolvedValueOnce({
        agent_card: { name: 'Agent' },
        skills: SKILLS,
      });

      renderComponent();
      fireEvent.click(screen.getByText('Connect & Load Skills').closest('button')!);

      await waitFor(() => {
        // Should not crash even when connection_status is undefined
        expect(mockSetSelectedComponent).toHaveBeenCalled();
        // Must show success toast with the default message (not an error toast)
        expect(mockToast).toHaveBeenCalledWith(
          expect.objectContaining({
            title: 'Connected successfully',
            description: 'Agent skills loaded successfully.',
            status: 'success',
          }),
        );
      });
    });

    it('handles response with no agent_card and no top-level skills', async () => {
      mockSelectedComponent = makeComponent({
        configuration: { url: 'https://agent.example.com' },
      });
      mockMutateAsync.mockResolvedValueOnce({
        connection_status: { status: 'succeeded', message: 'OK' },
        // No skills and no agent_card
      });

      renderComponent();
      fireEvent.click(screen.getByText('Connect & Load Skills').closest('button')!);

      await waitFor(() => {
        expect(mockSetSelectedComponent).toHaveBeenCalled();
        const updatedComp = mockSetSelectedComponent.mock.calls[0][0];
        // Skills should be empty since both sources are undefined
        expect(updatedComp.configuration.skills).toEqual([]);
        // Should show success toast
        expect(mockToast).toHaveBeenCalledWith(
          expect.objectContaining({
            title: 'Connected successfully',
            status: 'success',
          }),
        );
      });
    });

    it('does not update config when connection fails', async () => {
      mockSelectedComponent = makeComponent({
        configuration: { url: 'https://agent.example.com' },
      });
      mockMutateAsync.mockResolvedValueOnce({
        connection_status: { status: 'failed', message: 'No' },
      });

      renderComponent();
      fireEvent.click(screen.getByText('Connect & Load Skills').closest('button')!);

      await waitFor(() => {
        expect(mockToast).toHaveBeenCalled();
      });
      // setSelectedComponent should NOT have been called for config update
      expect(mockSetSelectedComponent).not.toHaveBeenCalled();
    });

    it('shows error toast when mutateAsync throws an Error', async () => {
      mockSelectedComponent = makeComponent({
        configuration: { url: 'https://agent.example.com' },
      });
      mockMutateAsync.mockRejectedValueOnce(new Error('Network timeout'));

      renderComponent();
      fireEvent.click(screen.getByText('Connect & Load Skills').closest('button')!);

      await waitFor(() => {
        expect(mockToast).toHaveBeenCalledWith(
          expect.objectContaining({
            title: 'Connection failed',
            description: 'Network timeout',
            status: 'error',
          }),
        );
      });
    });

    it('shows generic error message when thrown value is not an Error', async () => {
      mockSelectedComponent = makeComponent({
        configuration: { url: 'https://agent.example.com' },
      });
      mockMutateAsync.mockRejectedValueOnce('something weird');

      renderComponent();
      fireEvent.click(screen.getByText('Connect & Load Skills').closest('button')!);

      await waitFor(() => {
        expect(mockToast).toHaveBeenCalledWith(
          expect.objectContaining({
            title: 'Connection failed',
            description: 'Could not reach the remote agent.',
            status: 'error',
          }),
        );
      });
    });

    it('does not call mutateAsync when isPending is true', async () => {
      // Render with isPending=false so button is enabled (not in loading state)
      mockIsPending = false;
      mockSelectedComponent = makeComponent({
        configuration: { url: 'https://agent.example.com' },
      });
      renderComponent();

      // Now flip isPending to true BEFORE clicking — the getter will return true
      // when handleConnect reads fetchAgentCard.isPending inside the handler
      mockIsPending = true;

      const btn = screen.getByText('Connect & Load Skills').closest('button')!;
      fireEvent.click(btn);

      // The handler should return early due to isPending check
      expect(mockMutateAsync).not.toHaveBeenCalled();
    });
  });

  // ---- Skills Display ----
  describe('Skills display', () => {
    beforeEach(() => {
      mockSelectedComponent = makeComponent({
        configuration: {
          url: 'https://agent.example.com',
          skills: SKILLS,
        },
      });
    });

    it('renders skill tags when skills are loaded', () => {
      renderComponent();
      expect(screen.getByText('Skill One')).toBeInTheDocument();
      expect(screen.getByText('Skill Two')).toBeInTheDocument();
    });

    it('shows the "Skills" header', () => {
      renderComponent();
      expect(screen.getByText('Skills')).toBeInTheDocument();
    });

    it('shows the "(read only)" label', () => {
      renderComponent();
      expect(screen.getByText('(read only)')).toBeInTheDocument();
    });

    it('shows green check icon on URL input when skills are loaded', () => {
      renderComponent();
      // The FiCheck icon should be rendered (via the mock it gets a test ID)
      expect(screen.getByTestId('fi-check')).toBeInTheDocument();
    });

    it('filters out skills with empty names', () => {
      mockSelectedComponent = makeComponent({
        configuration: {
          url: 'https://agent.example.com',
          skills: [
            { id: 's1', name: 'Valid Skill' },
            { id: 's2', name: '' },
            { id: 's3', name: '   ' },
          ],
        },
      });
      renderComponent();
      expect(screen.getByText('Valid Skill')).toBeInTheDocument();

      // The invalid skills should not appear as tags
      expect(screen.queryByText('   ')).not.toBeInTheDocument();
    });

    it('does not show skills section when all skills have empty names', () => {
      mockSelectedComponent = makeComponent({
        configuration: {
          url: 'https://agent.example.com',
          skills: [
            { id: 's1', name: '' },
            { id: 's2', name: '   ' },
          ],
        },
      });
      renderComponent();
      expect(screen.queryByText('Skills')).not.toBeInTheDocument();
      expect(screen.getByText('Connect & Load Skills')).toBeInTheDocument();
    });
  });

  // ---- updateConfig edge cases ----
  describe('updateConfig', () => {
    it('does nothing when selectedComponent is null', () => {
      mockSelectedComponent = null;
      renderComponent();
      // Try to trigger an input change - the handler should return early
      const urlInput = screen.getByPlaceholderText('https://my-agent.example.com');
      fireEvent.change(urlInput, { target: { value: 'https://test.com' } });
      expect(mockSetSelectedComponent).not.toHaveBeenCalled();
      expect(mockUpdateNodeById).not.toHaveBeenCalled();
    });

    it('calls both setSelectedComponent and updateNodeById with correct ID', () => {
      mockSelectedComponent = makeComponent({ id: 'node-42', configuration: {} });
      renderComponent();
      const input = screen.getByPlaceholderText('https://my-agent.example.com');
      fireEvent.change(input, { target: { value: 'https://test.com' } });

      expect(mockSetSelectedComponent).toHaveBeenCalledTimes(1);
      expect(mockUpdateNodeById).toHaveBeenCalledTimes(1);
      expect(mockUpdateNodeById).toHaveBeenCalledWith(
        'node-42',
        expect.objectContaining({
          id: 'node-42',
          configuration: expect.objectContaining({ url: 'https://test.com' }),
        }),
      );
    });

    it('calls setWorkflow with updated workflow when currentWorkflow is set (triggers auto-save)', () => {
      mockSelectedComponent = makeComponent({
        id: 'node-42',
        configuration: { url: 'https://old.com' },
      });
      mockCurrentWorkflow = {
        workflow: {
          components: [
            { id: 'node-other', configuration: {} },
            { id: 'node-42', configuration: { url: 'https://old.com' } },
          ],
          status: 'draft',
        },
      };
      renderComponent();
      const input = screen.getByPlaceholderText('https://my-agent.example.com');
      fireEvent.change(input, { target: { value: 'https://new.com' } });

      expect(mockSetWorkflow).toHaveBeenCalledTimes(1);
      const [updatedWorkflow] = mockSetWorkflow.mock.calls[0];
      const updatedComponent = updatedWorkflow.workflow.components.find(
        (c: { id: string }) => c.id === 'node-42',
      );
      expect(updatedComponent).toBeDefined();
      expect(updatedComponent.configuration.url).toBe('https://new.com');
    });

    it('preserves existing configuration fields when updating', () => {
      mockSelectedComponent = makeComponent({
        configuration: { url: 'https://old.com', api_key: 'existing-key' },
      });
      renderComponent();
      const input = screen.getByPlaceholderText('https://my-agent.example.com');
      fireEvent.change(input, { target: { value: 'https://new.com' } });

      const updatedComp = mockSetSelectedComponent.mock.calls[0][0];
      expect(updatedComp.configuration.url).toBe('https://new.com');
      expect(updatedComp.configuration.api_key).toBe('existing-key');
    });
  });

  // ---- getValidSkills utility ----
  describe('getValidSkills filtering', () => {
    it('handles undefined skills gracefully', () => {
      mockSelectedComponent = makeComponent({ configuration: { url: 'https://x.com' } });
      renderComponent();
      // No skills section should appear
      expect(screen.queryByText('Skills')).not.toBeInTheDocument();
      expect(screen.getByText('Connect & Load Skills')).toBeInTheDocument();
    });

    it('handles null skill names', () => {
      mockSelectedComponent = makeComponent({
        configuration: {
          url: 'https://x.com',
          skills: [{ id: 's1', name: null }],
        },
      });
      renderComponent();
      expect(screen.queryByText('Skills')).not.toBeInTheDocument();
    });

    it('handles skills with only valid entries', () => {
      mockSelectedComponent = makeComponent({
        configuration: {
          url: 'https://x.com',
          skills: [
            { id: '1', name: 'Alpha' },
            { id: '2', name: 'Beta' },
          ],
        },
      });
      renderComponent();
      expect(screen.getByText('Alpha')).toBeInTheDocument();
      expect(screen.getByText('Beta')).toBeInTheDocument();
    });
  });

  // ---- Chakra style assertions (via Emotion CSS inspection) ----
  describe('Emotion CSS styles', () => {
    it('applies success.400 border-color to URL input when skills are loaded', () => {
      mockSelectedComponent = makeComponent({
        configuration: { url: 'https://x.com', skills: SKILLS },
      });
      const { unmount } = renderComponent();

      const inputWithSkills = screen.getByPlaceholderText('https://my-agent.example.com');
      const clsWith = inputWithSkills.className.split(/\s+/).find((c) => c.startsWith('css-'))!;
      unmount();

      // Render without skills for comparison
      mockSelectedComponent = makeComponent({ configuration: { url: 'https://x.com' } });
      renderComponent();
      const inputNoSkills = screen.getByPlaceholderText('https://my-agent.example.com');
      const clsWithout = inputNoSkills.className.split(/\s+/).find((c) => c.startsWith('css-'))!;

      // The Emotion CSS class must be different when borderColor is applied
      expect(clsWith).not.toBe(clsWithout);

      // Additionally verify the success.400 value appears in the CSS rules
      const rules = getCSSRulesForClass(clsWith);
      const allRulesText = rules.join('\n');
      expect(allRulesText).toContain('border-color:success.400');
    });

    it('applies success.400 border-color in the base (non-pseudo) CSS rule when skills are loaded', () => {
      mockSelectedComponent = makeComponent({
        configuration: { url: 'https://x.com', skills: SKILLS },
      });
      renderComponent();

      const input = screen.getByPlaceholderText('https://my-agent.example.com');
      const cls = input.className.split(/\s+/).find((c) => c.startsWith('css-'))!;

      // Check ONLY base rules (no :hover, :focus, :active, :disabled)
      const baseRules = getBaseCSSRulesForClass(cls);
      const baseText = baseRules.join('\n');
      expect(baseText).toContain('border-color:success.400');
    });

    it('applies success.400 border-color on hover when skills are loaded', () => {
      mockSelectedComponent = makeComponent({
        configuration: { url: 'https://x.com', skills: SKILLS },
      });
      renderComponent();

      const input = screen.getByPlaceholderText('https://my-agent.example.com');
      const cls = input.className.split(/\s+/).find((c) => c.startsWith('css-'))!;
      const rules = getCSSRulesForClass(cls);

      const hoverRule = rules.find((r) => r.includes(':hover'));
      expect(hoverRule).toBeDefined();
      expect(hoverRule).toContain('border-color:success.400');
    });

    it('applies success.400 border-color and removes box-shadow on focus-visible when skills are loaded', () => {
      mockSelectedComponent = makeComponent({
        configuration: { url: 'https://x.com', skills: SKILLS },
      });
      renderComponent();

      const input = screen.getByPlaceholderText('https://my-agent.example.com');
      const cls = input.className.split(/\s+/).find((c) => c.startsWith('css-'))!;
      const rules = getCSSRulesForClass(cls);

      const focusRule = rules.find((r) => r.includes(':focus-visible'));
      expect(focusRule).toBeDefined();
      expect(focusRule).toContain('border-color:success.400');
      expect(focusRule).toContain('box-shadow');
    });

    it('does not apply success.400 border styles when no skills are loaded', () => {
      mockSelectedComponent = makeComponent({ configuration: { url: 'https://x.com' } });
      renderComponent();

      const input = screen.getByPlaceholderText('https://my-agent.example.com');
      const cls = input.className.split(/\s+/).find((c) => c.startsWith('css-'))!;
      const rules = getCSSRulesForClass(cls);

      // Base rule should NOT have success.400 border
      const baseRule = rules.find((r) => !r.includes(':hover') && !r.includes(':focus'));
      expect(baseRule).not.toContain('border-color:success.400');

      // Hover rule should NOT have success.400
      const hoverWithSuccess = rules.filter(
        (r) => r.includes(':hover') && r.includes('success.400'),
      );
      expect(hoverWithSuccess).toHaveLength(0);
    });

    it('applies gray.600 color to URL link icon', () => {
      renderComponent();

      const linkIcon = screen.getByTestId('fi-link');
      // Walk up to find the Chakra Icon wrapper with the Emotion CSS class
      // The SVG itself or its parent Box/Icon element should carry the color style
      let el: Element | null = linkIcon;
      let iconCls: string | undefined;
      while (el && !iconCls) {
        const classAttr = el.getAttribute('class') ?? '';
        iconCls = classAttr.split(/\s+/).find((c) => c.startsWith('css-'));
        if (!iconCls) el = el.parentElement;
      }
      expect(iconCls).toBeDefined();

      const rules = getCSSRulesForClass(iconCls!);
      const allRulesText = rules.join('\n');
      expect(allRulesText).toContain('color:var(--chakra-colors-gray-600)');
    });
  });

  // ---- toast configuration ----
  describe('toast configuration', () => {
    it('success toast has isClosable and correct position', async () => {
      mockSelectedComponent = makeComponent({
        configuration: { url: 'https://agent.example.com' },
      });
      mockMutateAsync.mockResolvedValueOnce({
        connection_status: { status: 'succeeded', message: 'OK' },
        skills: SKILLS,
      });

      renderComponent();
      fireEvent.click(screen.getByText('Connect & Load Skills').closest('button')!);

      await waitFor(() => {
        expect(mockToast).toHaveBeenCalledWith(
          expect.objectContaining({
            isClosable: true,
            position: 'bottom-right',
          }),
        );
      });
    });

    it('error toast has isClosable and correct position', async () => {
      mockSelectedComponent = makeComponent({
        configuration: { url: 'https://agent.example.com' },
      });
      mockMutateAsync.mockRejectedValueOnce(new Error('fail'));

      renderComponent();
      fireEvent.click(screen.getByText('Connect & Load Skills').closest('button')!);

      await waitFor(() => {
        expect(mockToast).toHaveBeenCalledWith(
          expect.objectContaining({
            isClosable: true,
            position: 'bottom-right',
          }),
        );
      });
    });
  });
});
